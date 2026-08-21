import SwiftUI

/// About sheet — version info, attribution, links to the public
/// Privacy Policy / Safety / Support pages.
///
/// Apple App Store Review Guidelines 5.1.1 + 1.4.1 require the Privacy
/// Policy and Safety info to be reachable *from inside the app*, not just
/// from App Store Connect. This sheet is that surface.
///
/// Ship-spec v2 (2026-08-19): no Restore Purchases (StoreKit removed).
public struct AboutView: View {

    @Environment(\.dismiss) private var dismiss

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

            Divider()
                .padding(.vertical, 4)

            VStack(alignment: .leading, spacing: 12) {
                Text("READ MORE")
                    .font(.system(.caption, design: .rounded).weight(.heavy))
                    .foregroundStyle(Color("BrandTextSecondary"))
                    .accessibilityHidden(true)

                webLink("Privacy Policy", url: StillBoxConfig.privacyPolicyURL)
                webLink("Safety", url: StillBoxConfig.safetyURL)
                webLink("Support", url: StillBoxConfig.supportURL)
            }

            Spacer()

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

    /// Opens an external URL in the system browser. Uses Link so SwiftUI
    /// shows the standard Safari/Chrome chooser on iOS.
    @ViewBuilder
    private func webLink(_ title: String, url: URL) -> some View {
        Link(destination: url) {
            HStack {
                Text(title)
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(Color("BrandTextPrimary"))
                Spacer()
                Image(systemName: "arrow.up.forward")
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(Color("BrandTextSecondary"))
            }
        }
        .accessibilityHint("Opens in browser")
    }
}

#Preview {
    AboutView()
}