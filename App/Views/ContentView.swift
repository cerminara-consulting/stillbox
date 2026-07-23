import SwiftUI

/// "The Room" — the only screen of StillBox.
///
/// Layers, top to bottom:
///   1. Settings sheet trigger (small text, low-contrast, bottom-leading)
///   2. About trigger (small text, low-contrast, bottom-trailing)
///   3. "breathe" prompt label (idle only)
///   4. The breathing box (animated; phase-dependent)
///   5. Background fill (the "room")
///
/// The entire screen — except the two small text buttons — is the tap target.
/// Tapping starts/stops a session.
public struct ContentView: View {

    @EnvironmentObject private var engine: BreathEngine
    @StateObject private var store = StoreManager()
    @State private var haptics = HapticEngine()
    @State private var showSettings: Bool = false
    @State private var showAbout: Bool = false

    // Tweak these per SPEC §6.
    private let boxMinScale: CGFloat = 1.0
    private let boxMaxScale: CGFloat = 1.18

    public var body: some View {
        GeometryReader { geo in
            ZStack {
                Color("BrandBackground")
                    .ignoresSafeArea()

                // The box (always present so the layout doesn't shift)
                boxView(size: boxSize(in: geo.size))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Phase label / idle prompt
                promptOverlay

                // Settings + About links (visible only while idle)
                if engine.session == .idle {
                    bottomLinks
                }
            }
            .contentShape(Rectangle()) // entire screen is tappable
            .onTapGesture {
                engine.toggleSession()
                if engine.hapticsEnabled {
                    haptics.phaseChanged()
                }
                // Schedule completion haptics when transitioning out of breathing.
                if case .completing = engine.session {
                    if engine.hapticsEnabled {
                        haptics.completionPulse()
                    }
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
                    .environmentObject(store)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showAbout) {
                AboutView()
                    .environmentObject(store)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - Sub-views

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
