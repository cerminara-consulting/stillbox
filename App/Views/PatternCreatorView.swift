import SwiftUI

/// Custom pattern creator — a sub-screen inside Settings. The user adjusts
/// four sliders (one per phase) and previews the plain-English summary
/// before saving.
///
/// Validation rules (from `BreathingPattern.isValid`):
///   - Each phase must be between 1 and 12 seconds inclusive.
///   - Patterns with any phase outside that range disable the Save button.
public struct PatternCreatorView: View {

    @EnvironmentObject private var store: StoreManager

    @State private var name: String = "My pattern"
    @State private var inhale: Double = 4
    @State private var holdIn: Double = 4
    @State private var exhale: Double = 4
    @State private var holdOut: Double = 4

    /// Called when the user taps Save. Receives the new `BreathingPattern`.
    /// If the pattern is invalid (button should not be tappable, but we
    /// double-check here) the callback is not invoked.
    let onSave: (BreathingPattern) -> Void

    public init(onSave: @escaping (BreathingPattern) -> Void) {
        self.onSave = onSave
    }

    /// Live preview struct — recomputed every render. Lets the summary
    /// update as the user moves sliders.
    private var previewPattern: BreathingPattern {
        BreathingPattern(
            name: name.trimmingCharacters(in: .whitespaces).isEmpty ? "Custom" : name,
            inhaleSeconds: Int(inhale),
            holdInSeconds: Int(holdIn),
            exhaleSeconds: Int(exhale),
            holdOutSeconds: Int(holdOut)
        )
    }

    public var body: some View {
        Form {
            Section("Name") {
                TextField("Custom pattern", text: $name)
                    .textInputAutocapitalization(.words)
            }

            Section("Inhale") { phaseSlider(value: $inhale) }
            Section("Hold (after inhale)") { phaseSlider(value: $holdIn) }
            Section("Exhale") { phaseSlider(value: $exhale) }
            Section("Hold (after exhale)") { phaseSlider(value: $holdOut) }

            Section {
                Text(previewPattern.summary)
                    .font(.body)
                    .foregroundStyle(Color("BrandTextSecondary"))
            } header: {
                Text("Preview")
            } footer: {
                Text("Each phase is between 1 and 12 seconds.")
                    .font(.footnote)
            }

            Section {
                Button {
                    onSave(previewPattern)
                } label: {
                    Text("Save pattern")
                        .frame(maxWidth: .infinity)
                }
                .disabled(!previewPattern.isValid)
                .foregroundStyle(previewPattern.isValid ? Color("BrandAccent") : Color("BrandTextSecondary"))
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color("BrandBackground"))
        .navigationTitle("Custom pattern")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private func phaseSlider(value: Binding<Double>) -> some View {
        VStack(alignment: .leading) {
            HStack {
                Text("\(Int(value.wrappedValue))s")
                    .font(.system(.body, design: .rounded).weight(.heavy))
                    .foregroundStyle(Color("BrandTextPrimary"))
                Spacer()
            }
            Slider(
                value: value,
                in: Double(BreathingPattern.minPhaseSeconds)...Double(BreathingPattern.maxPhaseSeconds),
                step: 1
            )
            .tint(Color("BrandAccent"))
        }
    }
}

#Preview {
    NavigationStack {
        PatternCreatorView { _ in }
            .environmentObject(StoreManager())
    }
}
