import Foundation
import SwiftUI
import Combine

/// The runtime engine for a breath session.
///
/// State machine:
///   - `.idle`     : not running; the room shows the word "breathe".
///   - `.breathing`: actively running; one phase at a time, looping.
///   - `.completing`: post-session fade; the room shows the warm glow pulse.
///
/// The engine does NOT own the audio/haptic playback — that lives in the
/// view layer, where it can be silenced when Reduce Motion is on. Instead the
/// engine publishes a `phaseTick` whenever the phase changes, and the view
/// reacts by playing a cue and updating the visible label.
@MainActor
public final class BreathEngine: ObservableObject {

    // MARK: - Public published state

    @Published public private(set) var session: SessionState = .idle
    @Published public private(set) var currentPhase: BreathPhase = .inhale
    @Published public private(set) var elapsedRounds: Int = 0

    /// Total rounds requested for this session, nil = continuous.
    @Published public var targetRounds: Int? = nil

    /// The current breathing pattern. Defaults to 4-4-4-4 (box).
    @Published public var pattern: BreathingPattern = .box

    /// Per-phase cue modalities. Read by the view layer.
    @Published public var soundEnabled: Bool = false
    @Published public var hapticsEnabled: Bool = true

    /// True when the user has overridden the system Reduce Motion setting
    /// via the Settings sheet. `nil` means "use the system value".
    @Published public var reduceMotionOverride: Bool? = nil

    /// True while a session is in the completion animation.
    public var isCompleting: Bool { if case .completing = session { return true } else { return false } }

    /// True while a session is actively running phases.
    public var isBreathing: Bool { if case .breathing = session { return true } else { return false } }

    // MARK: - Internals

    private var phaseTask: Task<Void, Never>?
    private var systemReduceMotion: Bool = UIAccessibility.isReduceMotionEnabled

    // MARK: - Types

    public enum SessionState: Equatable {
        case idle
        case breathing
        case completing
    }

    public init() {}

    // MARK: - Public API

    /// Toggle the session between idle and breathing. If a completion is in
    /// progress, treats it as a stop and returns to idle.
    public func toggleSession() {
        switch session {
        case .idle, .completing:
            startSession()
        case .breathing:
            stopSession()
        }
    }

    /// Begin a session from the idle state. Resets counters, starts the
    /// phase loop. Public so the view layer can bind to a specific event
    /// (e.g. a "Begin" button on a future onboarding state).
    public func startSession() {
        // Defensive: stop any prior task (we may have been called twice
        // in quick succession).
        phaseTask?.cancel()

        elapsedRounds = 0
        currentPhase = .inhale
        session = .breathing

        phaseTask = Task { [weak self] in
            await self?.runBreathLoop()
        }
    }

    /// Stop the session. If the session was breathing, transition to
    /// `.completing` for the end-of-session glow. If idle, no-op.
    public func stopSession() {
        phaseTask?.cancel()
        phaseTask = nil

        switch session {
        case .breathing:
            session = .completing
            // After the completion pulse animation runs (~800ms in the view
            // layer), the view calls `completeSession()` to return to idle.
            Task { [weak self] in
                try? await Task.sleep(nanoseconds: 1_200_000_000)
                await MainActor.run {
                    guard let self else { return }
                    if case .completing = self.session {
                        self.session = .idle
                        self.elapsedRounds = 0
                    }
                }
            }
        case .idle, .completing:
            session = .idle
            elapsedRounds = 0
        }
    }

    /// Called by the view after the completion pulse animation finishes, to
    /// reset to idle. Safe to call multiple times.
    public func completeSession() {
        if case .completing = session {
            session = .idle
            elapsedRounds = 0
        }
    }

    // MARK: - System hooks

    /// Adopt the system Reduce Motion setting if no user override exists.
    /// Called from `StillBoxApp.onAppear`.
    public func honorSystemReduceMotion() {
        systemReduceMotion = UIAccessibility.isReduceMotionEnabled
        if reduceMotionOverride == nil {
            reduceMotionOverride = systemReduceMotion
        }
    }

    /// True if the engine should advise the view layer to skip motion. Either
    /// the system is set OR the user explicitly opted in via Settings.
    public var effectiveReduceMotion: Bool {
        reduceMotionOverride ?? systemReduceMotion
    }

    // MARK: - Phase loop

    /// The main phase loop. Awaits one phase at a time, publishes
    /// `currentPhase` updates for the view to react to, and increments
    /// `elapsedRounds` after each complete cycle.
    private func runBreathLoop() async {
        // Initial phase tick so the view renders the first phase immediately.
        // (The view already knows we started, but if the loop were to skip
        // the first await the UI would briefly show the wrong phase.)

        while !Task.isCancelled {
            // Per-phase duration in seconds.
            let phaseSeconds: Int
            switch currentPhase {
            case .inhale:  phaseSeconds = pattern.inhaleSeconds
            case .holdIn:  phaseSeconds = pattern.holdInSeconds
            case .exhale:  phaseSeconds = pattern.exhaleSeconds
            case .holdOut: phaseSeconds = pattern.holdOutSeconds
            }

            // Sleep in 100ms slices so cancellation can interrupt
            // mid-phase. Direct `Task.sleep(seconds:)` couldn't be cancelled
            // until the full phase elapsed, which feels unresponsive.
            let sleepSliceNs: UInt64 = 100_000_000
            let elapsedNs: UInt64 = UInt64(phaseSeconds) * 1_000_000_000
            var accum: UInt64 = 0
            while accum < elapsedNs && !Task.isCancelled {
                try? await Task.sleep(nanoseconds: sleepSliceNs)
                accum += sleepSliceNs
            }
            if Task.isCancelled { return }

            // Did we just complete a full cycle?
            let justCompletedCycle = (currentPhase == .holdOut)
            if justCompletedCycle {
                elapsedRounds += 1
                if let target = targetRounds, elapsedRounds >= target {
                    // Session is done; transition to completion.
                    stopSession()
                    return
                }
            }

            // Advance to next phase.
            currentPhase = currentPhase.next
        }
    }
}
