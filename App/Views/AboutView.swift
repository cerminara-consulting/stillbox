import SwiftUI

/// About sheet — version info, attribution, privacy link, restore purchases.
public struct AboutView: View {

    @EnvironmentObject private var store: StoreManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingRestoreConfirmation: Bool = false

    private var versionString: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 4) {
                Text("StillBox")
                    .font(.system(.largeTitle, design: .rounded).weight(.heavy))
                    .foregroundStyle(Color("BrandTextPrimary"))
                Text("Version \(versionString)")
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(Color("BrandTextSecondary"))
            }

            Text("A small, careful breathwork app from Cerminara Consulting.")
                .font(.system(.body, design: .rounded))
                .foregroundStyle(Color("BrandTextPrimary"))

            VStack(alignment: .leading, spacing: 12) {
                row("Privacy", value: "No data is collected.")
                row("Tracking", value: "None.")
                row("Account", value: "None.")
            }

            Spacer()

            Button {
                Task {
                    await store.restorePurchases()
                    showingRestoreConfirmation = true
                }
            } label: {
                Text("Restore purchases")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color("BrandBoxStroke"), lineWidth: 1)
                    )
            }
            .foregroundStyle(Color("BrandAccent"))

            Button {
                dismiss()
            } label: {
                Text("Close")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .foregroundStyle(Color("BrandTextSecondary"))
            .font(.system(.body, design: .rounded).weight(.regular))
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color("BrandBackground").ignoresSafeArea())
        .alert("Restore complete", isPresented: $showingRestoreConfirmation) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your purchases have been restored.")
        }
    }

    @ViewBuilder
    private func row(_ label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(label)
                .font(.system(.caption, design: .rounded).weight(.heavy))
                .foregroundStyle(Color("BrandTextSecondary"))
                .frame(width: 80, alignment: .leading)
            Text(value)
                .font(.system(.body, design: .rounded))
                .foregroundStyle(Color("BrandTextPrimary"))
            Spacer()
        }
    }
}

#Preview {
    AboutView()
        .environmentObject(StoreManager())
}
