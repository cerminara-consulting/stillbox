import SwiftUI

/// "The Room" — the only screen of StillBox.
///
/// Layers, top to bottom:
///   1. Header bar — logo (clipped to rounded squircle) + "StillBox"
///      wordmark (always visible, low-contrast)
///   2. A rotating quote (idle + breathing, sits below header above the box)
///   3. The breathing box (animated; phase-dependent) + phase label inside
///   4. Bottom affordance — "Tap anywhere to begin" (idle) or "Tap to stop"
///      (breathing), positioned halfway between the box's bottom edge and
///      the footnote-links row
///   5. Footnote links (Patterns & settings / About) — pinned to the bottom
///      safe area
///   6. Background fill (the "room")
///
/// The entire screen is the tap target. The affordance labels at the top
/// and bottom are visual cues, not buttons.
public struct ContentView: View {

    @EnvironmentObject private var engine: BreathEngine
    @State private var haptics = HapticEngine()
    @State private var showSettings: Bool = false
    @State private var showAbout: Bool = false

    // Quote of the moment — picked once when the view appears (== app open).
    // Drawn from the curated CalmQuote.library; see App/Models/CalmQuote.swift.
    @State private var currentQuote: CalmQuote?
    @State private var showQuoteDetail: Bool = false

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

                // Quote (idle and breathing) — sits in the upper third, above the box.
                // Per John (2026-08-20): keep the quote visible during
                // breathing too. The box is the focal point, but the quote
                // belongs to the room, not to the idle state.
                if engine.session != .completing {
                    quoteOverlay
                }

                // Phase label inside the box (idle = nothing, breathing = phase name)
                promptOverlay

                // Bottom affordance + footnote links. The affordance text is
                // positioned at the geometric midpoint between the box's
                // bottom edge and the footnote-links row — per John
                // (2026-08-20). Footnote links stay pinned to the bottom
                // safe area. Whole-screen tap target still works; these
                // are visual cues, not buttons.
                bottomLinks
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .padding(.bottom, 24)

                bottomAffordanceText
                    .position(
                        x: geo.size.width / 2,
                        y: midpointBetweenBoxBottomAndLinks(
                            boxBottom: geo.size.height / 2 + boxSize(in: geo.size) / 2,
                            linksTop: geo.size.height - 24 - footnoteLinksHeight
                        )
                    )
            }
            .onAppear {
                // Pick a fresh quote each time the view appears (= app open).
                if currentQuote == nil {
                    currentQuote = CalmQuote.random()
                }
            }
            .contentShape(Rectangle()) // entire screen is tappable
            .onTapGesture {
                // Capture state before toggling so we can fire the right
                // haptic (start vs stop) based on the transition direction.
                let wasIdle = (engine.session == .idle)
                engine.toggleSession()
                guard engine.hapticsEnabled else { return }
                switch engine.session {
                case .breathing where wasIdle:
                    // Idle -> breathing = user started a session.
                    haptics.sessionStarted()
                case .completing:
                    // Breathing -> completing = user stopped mid-session.
                    haptics.sessionStopped()
                    haptics.completionPulse()
                default:
                    break
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
            .sheet(isPresented: $showQuoteDetail) {
                if let quote = currentQuote {
                    QuoteDetailSheet(quote: quote)
                        .presentationDetents([.medium])
                        .presentationDragIndicator(.visible)
                }
            }
        }
    }

    // MARK: - Sub-views

    /// Header bar: real app icon (from `BrandLogo` asset) on the leading edge
    /// + "StillBox" wordmark next to it. Always visible (idle and breathing),
    /// low-contrast, top-aligned with a generous top safe-area padding so it
    /// reads as a "title bar" without competing with the box.
    ///
    /// The image is the same artwork as the App Store AppIcon master, scaled
    /// down for the 28pt header slot. We clip to a rounded squircle
    /// (corner radius ≈22% of side, continuous style) so the header logo
    /// reads as a proper iOS-style icon, matching the App Store AppIcon
    /// shape. Per John (2026-08-20) — the AppIcon itself is left untouched.
    private var headerBar: some View {
        HStack(spacing: 10) {
            Image("BrandLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 28, height: 28)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .accessibilityHidden(true)

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

    /// A single rotating quote, picked at app open from `CalmQuote.library`.
    /// Sits in the upper third of the screen, just above the box. Visible
    /// during idle AND breathing (per John 2026-08-20) — the quote belongs
    /// to the room, not to any one state. Hidden only during `.completing`
    /// so the box glow owns focus at session end.
    /// Tap the attribution to open a small "About this quote" sheet with
    /// the source link.
    @ViewBuilder
    private var quoteOverlay: some View {
        if let quote = currentQuote {
            VStack(spacing: 8) {
                Text(quote.text)
                    .font(.system(.body, design: .rounded).weight(.regular))
                    .italic()
                    .foregroundStyle(Color("BrandTextSecondary"))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 32)

                Button {
                    showQuoteDetail = true
                } label: {
                    Text("— \(quote.attribution)")
                        .font(.system(.footnote, design: .rounded))
                        .foregroundStyle(Color("BrandTextSecondary"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("About this quote: \(quote.attribution)")
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 96) // push below the header
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        } else {
            EmptyView()
        }
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
    /// timing *is* the breath timing. Matches the engine's per-phase clocks
    /// exactly — the engine is now wall-clock anchored (CACurrentMediaTime)
    /// so no cushion is needed to hide drift. See `runBreathLoop`.
    private func phaseSeconds(engine: BreathEngine) -> Double {
        let s: Int
        switch engine.currentPhase {
        case .inhale:  s = engine.pattern.inhaleSeconds
        case .holdIn:  s = engine.pattern.holdInSeconds
        case .exhale:  s = engine.pattern.exhaleSeconds
        case .holdOut: s = engine.pattern.holdOutSeconds
        }
        return Double(s)
    }

    /// The breathing-box size, based on screen geometry. The smaller of
    /// width/height is the basis, capped so the box never overflows the
    /// safe area on large phones in landscape.
    private func boxSize(in geo: CGSize) -> CGFloat {
        let basis = min(geo.width, geo.height) - 96 // 48pt inset each side
        return min(basis, 320)
    }

    /// Approximate height of the footnote-links row at the bottom of the
    /// screen. Used to anchor the affordance text halfway between the
    /// box's bottom edge and the links.
    ///
    /// Why approximate: SwiftUI doesn't expose rendered heights at
    /// `body`-evaluation time without a `GeometryReader` inside the view
    /// itself, which would force a second layout pass. The row is a
    /// single line of `.footnote` rounded text (~16pt) plus ~10pt of
    /// intrinsic padding, so 26pt is accurate enough for midpoint
    /// positioning.
    private var footnoteLinksHeight: CGFloat { 26 }

    /// Computes the y-coordinate (in screen-space, top-left origin) for
    /// the affordance text so it lands halfway between the box's bottom
    /// edge and the top of the footnote-links row.
    private func midpointBetweenBoxBottomAndLinks(
        boxBottom: CGFloat,
        linksTop: CGFloat
    ) -> CGFloat {
        (boxBottom + linksTop) / 2
    }

    /// The phase label inside the box. Idle state does NOT render a phase
    /// label — the "Tap to begin" prompt at the bottom of the screen does
    /// the talking while idle, so the box area stays clean.
    @ViewBuilder
    private var promptOverlay: some View {
        VStack(spacing: 24) {
            if engine.session != .idle {
                Text(engine.currentPhase.label)
                    .font(.system(.title, design: .rounded).weight(.heavy))
                    .foregroundStyle(Color("BrandTextSecondary"))
                    .accessibilityHidden(true)
            }
        }
        .padding(.horizontal, 24)
        .multilineTextAlignment(.center)
    }

    /// Bottom affordance text (without footnote links — those are positioned
    /// separately at the very bottom of the screen). State-driven:
    /// idle = "Tap anywhere to begin", breathing = "Tap to stop",
    /// completing = nothing.
    @ViewBuilder
    private var bottomAffordanceText: some View {
        switch engine.session {
        case .idle:
            Text("Tap anywhere to begin")
                .font(.system(.title3, design: .rounded).weight(.medium))
                .foregroundStyle(Color("BrandTextPrimary"))
                .accessibilityHidden(true)
        case .breathing:
            Text("Tap to stop")
                .font(.system(.title3, design: .rounded).weight(.medium))
                .foregroundStyle(Color("BrandTextPrimary"))
                .accessibilityHidden(true)
        case .completing:
            EmptyView()
        }
    }

    /// Two small footnote links — visible at the bottom of the screen in
    /// both idle and breathing states. Low-contrast so they never compete
    /// with the session affordance above them.
    private var bottomLinks: some View {
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
    }
}

#Preview {
    ContentView()
        .environmentObject(BreathEngine())
}
