import SwiftUI
import StoreKit

/// Settings sheet — modal, drag-to-dismiss. Hosts the pattern picker, round
/// count, sound/haptics/reduce-motion toggles, tip jar, and a sub-screen
/// navigation to the pattern creator and About.
public struct SettingsSheet: View {

    @EnvironmentObject private var engine: BreathEngine
    @EnvironmentObject private var store: StoreManager

    @Environment(\.dismiss) private var dismiss
    @State private var showPatternCreator: Bool = false
    @State private var showTipJar: Bool = false

    /// All built-in patterns, in display order.
    private let builtInPatterns: [BreathingPattern] = [
        .box,
        .fourSevenEight,
        .threeFourFiveThree
    ]

    public var body: some View {
        NavigationStack {
            Form {
                patternSection
                sessionSection
                feedbackSection
                unlockSection
            }
            .scrollContentBackground(.hidden)
            .background(Color("BrandBackground"))
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                engine.loadCustomPatterns()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color("BrandAccent"))
                }
            }
            .navigationDestination(isPresented: $showPatternCreator) {
                PatternCreatorView { newPattern in
                    engine.saveCustomPattern(newPattern)
                    engine.pattern = newPattern
                    showPatternCreator = false
                }
                .environmentObject(store)
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Sections

    @ViewBuilder
    private var patternSection: some View {
        Section {
            ForEach(builtInPatterns) { pattern in
                patternRow(pattern)
            }

            // Custom patterns (user-created, persisted in AppSettings)
            ForEach(engine.customPatterns) { pattern in
                patternRow(pattern)
            }

            Button {
                showPatternCreator = true
            } label: {
                Label("Create custom pattern", systemImage: "plus")
            }
            .disabled(!store.isPatternsUnlocked)
            .foregroundStyle(store.isPatternsUnlocked ? Color("BrandAccent") : Color("BrandTextSecondary"))
        } header: {
            Text("Pattern")
        } footer: {
            Text("Box is the default. Inhale, hold, exhale, hold. Tap to switch.")
                .font(.footnote)
        }
    }

    @ViewBuilder
    private var sessionSection: some View {
        Section {
            Picker("Rounds", selection: $engine.targetRounds) {
                ForEach(AppSettings.RoundCount.allCases) { count in
                    Text(count.label).tag(count.targetRoundsValue)
                }
            }
            .pickerStyle(.segmented)
            .disabled(!store.isPatternsUnlocked && engine.targetRounds == nil)
        } header: {
            Text("Session length")
        } footer: {
            Text("Continuous mode is unlocked with the Patterns IAP.")
                .font(.footnote)
        }
    }

    @ViewBuilder
    private var feedbackSection: some View {
        Section("Feedback") {
            Toggle("Subtle chime on each phase", isOn: $engine.soundEnabled)
            Toggle("Gentle haptic on each phase", isOn: $engine.hapticsEnabled)
            Toggle("Reduce motion", isOn: Binding(
                get: { engine.effectiveReduceMotion },
                set: { engine.reduceMotionOverride = $0 }
            ))
        }
    }

    @ViewBuilder
    private var unlockSection: some View {
        Section {
            if store.isPatternsUnlocked {
                Label("Patterns unlocked. Thank you.", systemImage: "checkmark.seal")
                    .foregroundStyle(Color("BrandTextSecondary"))
            } else {
                Button {
                    Task { await purchasePatterns() }
                } label: {
                    HStack {
                        Text("Unlock patterns & custom creator")
                        Spacer()
                        Text("$2.99")
                            .foregroundStyle(Color("BrandTextSecondary"))
                    }
                }
                .foregroundStyle(Color("BrandAccent"))
            }

            Button {
                showTipJar = true
            } label: {
                Label("Tip jar", systemImage: "heart")
            }
            .disabled(!store.isPatternsUnlocked)
            .foregroundStyle(store.isPatternsUnlocked ? Color("BrandAccent") : Color("BrandTextSecondary"))
        } footer: {
            Text("One-time purchase. No subscription. No tracking.")
                .font(.footnote)
        }
        .sheet(isPresented: $showTipJar) {
            TipJarView()
                .environmentObject(store)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Row helpers

    @ViewBuilder
    private func patternRow(_ pattern: BreathingPattern) -> some View {
        Button {
            engine.pattern = pattern
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(pattern.name)
                    Text(pattern.summary)
                        .font(.footnote)
                        .foregroundStyle(Color("BrandTextSecondary"))
                }
                Spacer()
                if engine.pattern == pattern {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color("BrandAccent"))
                }
            }
        }
        .foregroundStyle(Color("BrandTextPrimary"))
    }

    // MARK: - Actions

    private func purchasePatterns() async {
        do {
            let products = try await Product.products(for: [StoreManager.patternsProductID])
            guard let product = products.first else { return }
            await store.purchase(product)
        } catch {
            #if DEBUG
            print("[StillBox] Patterns purchase lookup failed: \(error.localizedDescription)")
            #endif
        }
    }
}

/// "Tip jar" sheet — three tip tiers via IAP. Never required, never nagged.
struct TipJarView: View {

    @EnvironmentObject private var store: StoreManager
    @Environment(\.dismiss) private var dismiss

    /// Tiers shown in the sheet. None of these unlocks additional features;
    /// they are pure acknowledgments.
    private let tips: [(label: String, productID: String)] = [
        ("$1", StoreManager.tipProductIDs[0]),
        ("$3", StoreManager.tipProductIDs[1]),
        ("$5", StoreManager.tipProductIDs[2])
    ]

    var body: some View {
        VStack(spacing: 24) {
            Text("StillBox is a small, careful app. If it helps, a tip is appreciated.")
                .font(.system(.body, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color("BrandTextPrimary"))
                .padding(.top, 32)

            Spacer()

            ForEach(tips, id: \.label) { tip in
                Button {
                    Task { await tap(tip.productID) }
                } label: {
                    Text(tip.label)
                        .font(.system(.title2, design: .rounded).weight(.heavy))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color("BrandBoxStroke"), lineWidth: 1)
                        )
                }
                .foregroundStyle(Color("BrandAccent"))
            }

            Spacer()

            Button("Not today") { dismiss() }
                .font(.system(.footnote, design: .rounded))
                .foregroundStyle(Color("BrandTextSecondary"))
                .padding(.bottom, 16)
        }
        .padding(.horizontal, 32)
        .background(Color("BrandBackground").ignoresSafeArea())
    }

    private func tap(_ productID: String) async {
        do {
            let products = try await Product.products(for: [productID])
            guard let product = products.first else { return }
            await store.purchase(product)
            await MainActor.run { dismiss() }
        } catch {
            #if DEBUG
            print("[StillBox] Tip lookup failed: \(error.localizedDescription)")
            #endif
        }
    }
}

#Preview {
    SettingsSheet()
        .environmentObject(BreathEngine())
        .environmentObject(StoreManager())
}
