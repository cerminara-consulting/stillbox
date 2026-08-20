import SwiftUI

/// "About this quote" sheet — opened by tapping the attribution line under
/// the quote on the home screen. Shows the full citation + a link to the
/// primary source so users can dig deeper if they want.
///
/// Why a separate sheet (not inline expansion): the quote's job on the
/// home screen is to set a tone, not to be a research artifact. Hiding the
/// academic details behind a tap keeps the surface calm.
public struct QuoteDetailSheet: View {

    @Environment(\.dismiss) private var dismiss

    public let quote: CalmQuote

    public init(quote: CalmQuote) {
        self.quote = quote
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("About this quote")
                .font(.system(.title3, design: .rounded).weight(.heavy))
                .foregroundStyle(Color("BrandTextPrimary"))

            // The quote itself, repeated here for context.
            VStack(alignment: .leading, spacing: 12) {
                Text(quote.text)
                    .font(.system(.body, design: .rounded).weight(.regular))
                    .italic()
                    .foregroundStyle(Color("BrandTextPrimary"))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Text("— \(quote.attribution)")
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(Color("BrandTextSecondary"))
            }

            if let url = quote.sourceURL {
                Link(destination: url) {
                    HStack(spacing: 6) {
                        Text("Read at the source")
                            .font(.system(.body, design: .rounded).weight(.semibold))
                        Image(systemName: "arrow.up.forward")
                            .font(.system(.footnote, design: .rounded).weight(.semibold))
                    }
                    .foregroundStyle(Color("BrandAccent"))
                    .padding(.vertical, 12)
                    .padding(.horizontal, 18)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .stroke(Color("BrandBoxStroke"), lineWidth: 1.5)
                    )
                }
                .accessibilityLabel("Read the source text. Opens in Safari.")
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
        .padding(.top, 32)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color("BrandBackground").ignoresSafeArea())
    }
}

#Preview {
    QuoteDetailSheet(quote: CalmQuote.library[2])
}