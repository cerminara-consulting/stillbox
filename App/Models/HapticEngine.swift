import Foundation
import UIKit

/// A thin wrapper around `UIImpactFeedbackGenerator`s with the haptic
/// vocabulary StillBox needs:
///
/// - `phaseChanged()` — soft, per-second tap during a session. Repeats ~1x/s.
/// - `completionPulse()` — gentle tap when a session ends naturally.
/// - `sessionStarted()` — heavier "thock" when the user taps to begin.
/// - `sessionStopped()` — heavier "thock" when the user taps to stop.
///
/// Why multiple methods: per-second taps and one-shot transitions should
/// feel different. The session-transition thock uses `.medium` style at
/// full intensity so it punches through the per-second taps without
/// becoming an alert/notification sound.
///
/// Keeping all `import UIKit` references in this one file keeps the view
/// layer testable as a pure-Swift dependency.
@MainActor
public final class HapticEngine {

    private let tickGenerator: UIImpactFeedbackGenerator
    private let completionGenerator: UIImpactFeedbackGenerator
    private let transitionGenerator: UIImpactFeedbackGenerator

    public init() {
        // `.soft` is the lightest, most breath-appropriate haptic style.
        // Pre-prepare so the first tap has no latency.
        self.tickGenerator = UIImpactFeedbackGenerator(style: .soft)
        self.tickGenerator.prepare()

        // `.soft` for completion — matches the per-second tick style but at
        // lower intensity, so it reads as "settling" rather than "alert".
        self.completionGenerator = UIImpactFeedbackGenerator(style: .soft)
        self.completionGenerator.prepare()

        // `.medium` is the heaviest style that still reads as a "tactile
        // confirmation" rather than a notification. Used for the
        // session-transition thock (start/stop) so the user feels a
        // distinct event rather than another per-second tap.
        self.transitionGenerator = UIImpactFeedbackGenerator(style: .medium)
        self.transitionGenerator.prepare()
    }

    /// Single tap intended to be called on each breath phase change.
    public func phaseChanged() {
        // 0.85 is the strongest perceptible soft-tap that still reads as
        // "calm" rather than "alert". 0.6 was tested as too quiet on real
        // iPhone hardware (S1 review feedback).
        tickGenerator.impactOccurred(intensity: 0.85)
        tickGenerator.prepare()
    }

    /// Single subtle tap used for the completion pulse. Even gentler than
    /// phase transitions.
    public func completionPulse() {
        completionGenerator.impactOccurred(intensity: 0.4)
        completionGenerator.prepare()
    }

    /// Heavier "thock" played when the user taps to begin a session.
    /// Distinct from the per-second `phaseChanged()` so the user knows
    /// their tap registered and a session has actually started — not
    /// just another second ticked by.
    public func sessionStarted() {
        // Full-intensity `.medium` style. Slightly more forceful than the
        // soft per-second taps (which use `.soft @ 0.85`) but not so heavy
        // that it reads as an alert.
        transitionGenerator.impactOccurred(intensity: 1.0)
        transitionGenerator.prepare()
    }

    /// Heavier "thock" played when the user taps to stop a session.
    /// Mirrors `sessionStarted()` so start/stop feel symmetric.
    public func sessionStopped() {
        transitionGenerator.impactOccurred(intensity: 1.0)
        transitionGenerator.prepare()
    }
}
