import SwiftUI

/// Settings sheet — modal, drag-to-dismiss. Hosts the pattern picker, round
/// count, sound/haptics/reduce-motion toggles, and a sub-screen navigation
/// to the pattern creator and About.
///
/// Ship-spec v2 (2026-08-19): all patterns + continuous mode free; no IAP,
/// no tip jar, no StoreKit surface.
public struct SettingsSheet: View {

    @EnvironmentObject private var engine: BreathEngine

    @Environment(\.dismiss) private var dismiss
    @State private var showPatternCreator: Bool = false

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
            .foregroundStyle(Color("BrandAccent"))
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
        } header: {
            Text("Session length")
        } footer: {
            Text("Continuous mode runs until you stop the session.")
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
}

#Preview {
    SettingsSheet()
        .environmentObject(BreathEngine())
}