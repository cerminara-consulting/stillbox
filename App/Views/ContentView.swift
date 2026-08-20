import SwiftUI

/// "The Room" — the only screen of StillBox.
///
/// Layers, top to bottom:
///   1. Header bar — logo + "StillBox" wordmark (always visible, low-contrast)
///   2. A rotating quote (idle only, sits below header above the box)
///   3. Settings sheet trigger (small text, low-contrast, bottom-leading)
///   4. About trigger (small text, low-contrast, bottom-trailing)
///   5. "breathe" prompt label (idle only)
///   6. The breathing box (animated; phase-dependent)
///   7. Background fill (the "room")
///
/// The entire screen — except the two small text buttons and the header logo —
/// is the tap target. Tapping starts/stops a session.
public struct ContentView: View {

    @EnvironmentObject private var engine: BreathEngine
    @State private var haptics = HapticEngine()
    @State private var showSettings: Bool = false
    @State private var showAbout: Bool = false

    // Quote of the moment — picked once when the view appears (== app open).
    // PLACEHOLDER list; real quotes supplied by John, swapped in via
    // `placeholderQuotes` below.
    @State private var currentQuote: String = ""

    private static let placeholderQuotes: [String] = [
        "Quote 1",
        "Quote 2",
        "Quote 3",
        "Quote 4",
        "Quote 5",
        "Quote 6",
        "Quote 7",
        "Quote 8",
        "Quote 9",
        "Quote 10"
    ]

    // Tweak these per SPEC §6.
    private let boxMinScale: CGFloat = 1.0
    private let boxMaxScale: CGFloat = 1.18

    public var body: some View {
        GeometryReader { geo in
            ZStack {
                Color("BrandBackground")
                    .ignoresSafeArea()

                // Header bar at top (logo + wordmark)
                VStack {
                    headerBar
                    Spacer()
                }

                // The box (always present so the layout doesn't shift)
                boxView(size: boxSize(in: geo.size))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Quote (idle only) — sits in the upper third, above the box
                if engine.session == .idle {
                    quoteOverlay
                }

                // Phase label / idle prompt
                promptOverlay

                // Settings + About links (visible only while idle)
                if engine.session == .idle {
                    bottomLinks
                }
            }
            .onAppear {
                // Pick a fresh quote each time the view appears (= app open).
                if currentQuote.isEmpty {
                    currentQuote = Self.placeholderQuotes
                        .randomElement() ?? Self.placeholderQuotes[0]
                }
            }
            .contentShape(Rectangle()) // entire screen is tappable
            .onTapGesture {
                engine.toggleSession()
                // Schedule completion haptics when transitioning out of breathing.
                if case .completing = engine.session {
                    if engine.hapticsEnabled {
                        haptics.completionPulse()
                    }
                }
            }
            // Per-second haptic tick. Fires once per real second (engine
            // uses CACurrentMediaTime as the monotonic reference). Each tick
            // is a single light `impactOccurred` call.
            .onReceive(engine.tickPublisher) { _ in
                if engine.hapticsEnabled {
                    haptics.phaseChanged()
                }
            }
            .gesture(
                // Long-press to open Settings. Two paths in because we want
                // both tap-to-start (instant) and a way to reach settings
                // without burying it. Long-press is documented in onboarding.
                LongPressGesture(minimumDuration: 0.6)
                    .onEnded { _ in
                        if engine.session == .idle {
                            showSettings = true
                        }
                    }
            )
            .accessibilityElement(children: .contain)
            .accessibilityLabel("StillBox — calm breathing")
            .sheet(isPresented: $showSettings) {
                SettingsSheet()
                    .environmentObject(engine)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showAbout) {
                AboutView()
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - Sub-views

    /// Header bar: small rounded square placeholder logo on the leading edge +
    /// "StillBox" wordmark next to it. Always visible (idle and breathing),
    /// low-contrast, top-aligned with a generous top safe-area padding so it
    /// reads as a "title bar" without competing with the box.
    ///
    /// John will swap "StillBox" for the real app name + replace the
    /// placeholder square with a real logo — both via `StillBoxConfig`.
    private var headerBar: some View {
        HStack(spacing: 10) {
            // PLACEHOLDER logo — small rounded square. Replace with real
            // AppIcon-fragment / custom asset when the brand mark is ready.
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .strokeBorder(Color("BrandBoxStroke"), lineWidth: 1.5)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color("BrandAccent").opacity(0.10))
                )
                .frame(width: 28, height: 28)

            Text("StillBox")
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(Color("BrandTextSecondary"))
        }
        .padding(.leading, 20)
        .padding(.top, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("StillBox")
    }

    /// A single rotating quote, picked at app open from `placeholderQuotes`.
    /// Sits in the upper third of the screen, just above the box. Idle only
    /// — disappears when a session starts so the box owns the visual focus.
    private var quoteOverlay: some View {
        VStack {
            Spacer()
                .frame(height: 96) // push below the header
            Text(currentQuote)
                .font(.system(.body, design: .rounded).weight(.regular))
                .italic()
                .foregroundStyle(Color("BrandTextSecondary"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .accessibilityLabel("Quote")
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    /// The breathing box. Uses scale + glow to indicate phase; honors Reduce
    /// Motion by staying static.
    @ViewBuilder
    private func boxView(size: CGFloat) -> some View {
        let reduceMotion = engine.effectiveReduceMotion

        ZStack {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .strokeBorder(Color("BrandBoxStroke"), lineWidth: 2)
                .frame(width: size, height: size)
                .background(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Color("BrandAccent").opacity(reduceMotion ? 0.04 : 0.08))
                        .frame(width: size, height: size)
                )
                .scaleEffect(boxScale(engine: engine, reduceMotion: reduceMotion))
                .shadow(
                    color: Color("BrandAccent").opacity(reduceMotion ? 0.0 : 0.25),
                    radius: reduceMotion ? 0 : 24,
                    x: 0,
                    y: 0
                )
                .animation(
                    reduceMotion ? .none : .easeInOut(duration: phaseSeconds(engine: engine)),
                    value: engine.currentPhase
                )
                .accessibilityElement()
                .accessibilityLabel("Breathing box")
                .accessibilityValue(engine.currentPhase.accessibilityLabel)
        }
    }

    /// Per-phase scale, computed from the engine state. If Reduce Motion is
    /// active, returns the mid scale (no animation visible).
    private func boxScale(engine: BreathEngine, reduceMotion: Bool) -> CGFloat {
        if reduceMotion { return 1.0 }
        switch engine.currentPhase {
        case .inhale:  return boxMaxScale
        case .exhale:  return boxMinScale
        case .holdIn:  return boxMaxScale
        case .holdOut: return boxMinScale
        }
    }

    /// Phase duration in seconds, used as the animation duration so the box
    /// timing *is* the breath timing. Matches the engine's per-phase clocks.
    private func phaseSeconds(engine: BreathEngine) -> Double {
        let s: Int
        switch engine.currentPhase {
        case .inhale:  s = engine.pattern.inhaleSeconds
        case .holdIn:  s = engine.pattern.holdInSeconds
        case .exhale:  s = engine.pattern.exhaleSeconds
        case .holdOut: s = engine.pattern.holdOutSeconds
        }
        // A 100ms cushion inside the engine leaves a 100ms headroom here.
        return max(0.2, Double(s) - 0.1)
    }

    /// The breathing-box size, based on screen geometry. The smaller of
    /// width/height is the basis, capped so the box never overflows the
    /// safe area on large phones in landscape.
    private func boxSize(in geo: CGSize) -> CGFloat {
        let basis = min(geo.width, geo.height) - 96 // 48pt inset each side
        return min(basis, 320)
    }

    /// The phase label (inside the box, in low-contrast text) or the idle
    /// "breathe" prompt (above the box, slightly larger).
    @ViewBuilder
    private var promptOverlay: some View {
        VStack(spacing: 24) {
            if engine.session == .idle {
                Text("breathe")
                    .font(.system(.largeTitle, design: .rounded).weight(.heavy))
                    .foregroundStyle(Color("BrandTextPrimary"))
                    .accessibilityHidden(true)
            } else {
                // Phase text inside the box, low-contrast — never competing.
                Text(engine.currentPhase.label)
                    .font(.system(.title, design: .rounded).weight(.heavy))
                    .foregroundStyle(Color("BrandTextSecondary"))
                    .accessibilityHidden(true)
            }
        }
        .padding(.horizontal, 24)
        .multilineTextAlignment(.center)
    }

    /// Two small links at the bottom of the screen, visible only when idle.
    private var bottomLinks: some View {
        VStack {
            Spacer()
            HStack {
                Button("Patterns & settings") {
                    showSettings = true
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color("BrandTextSecondary"))
                .font(.system(.footnote, design: .rounded))

                Spacer()

                Button("About") {
                    showAbout = true
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color("BrandTextSecondary"))
                .font(.system(.footnote, design: .rounded))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(BreathEngine())
}
