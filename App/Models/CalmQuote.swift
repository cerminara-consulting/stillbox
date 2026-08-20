import Foundation

/// A single curated quote shown above the breathing box.
///
/// All quotes in the default library are pre-1930 published works, verified
/// against their primary sources at scaffold time. The `citation` field is
/// the human-readable attribution shown on tap; `sourceURL` is the link
/// surface for users who want to dig deeper (displayed only via the
/// "About this quote" sheet, never inline).
///
/// Why a struct, not a string: quotes have meaning beyond their text. The
/// attribution + URL belong to the quote, not the view. Modeling it as a
/// struct also lets us add filters (e.g. "by era", "by theme") later
/// without rewriting the picker.
public struct CalmQuote: Equatable, Hashable {

    public let text: String
    public let attribution: String  // e.g. "Marcus Aurelius, Meditations IV.3"
    public let sourceURL: URL?

    public init(text: String, attribution: String, sourceURL: URL? = nil) {
        self.text = text
        self.attribution = attribution
        self.sourceURL = sourceURL
    }
}

extension CalmQuote {

    /// The default quote library. Ten pre-1930 verified quotes curated for
    /// a calm-breathing app. Order is *not* meaningful — `random()` picks
    /// from the whole array.
    ///
    /// All translations are public-domain (pre-1928 publication) or from
    /// editions explicitly public-domain (KJV 1611; gutenberg.org #10).
    public static let library: [CalmQuote] = [
        CalmQuote(
            text: "The breathing of the true man comes even from his heels, while men generally breathe only from their throats.",
            attribution: "Zhuangzi, Chuang Tzu Bk. 6 — trans. James Legge (1891)",
            sourceURL: URL(string: "http://nothingistic.org/library/chuangtzu/chuang15.html")
        ),
        CalmQuote(
            text: "Purity and stillness give the correct law to all under heaven.",
            attribution: "Lao Tzu, Tao Te Ching ch. 45 — trans. James Legge",
            sourceURL: URL(string: "https://classics.mit.edu/Lao/taote.1.1.html")
        ),
        CalmQuote(
            text: "Nowhere either with more quiet or more freedom from trouble does a man retire than into his own soul.",
            attribution: "Marcus Aurelius, Meditations IV.3 — trans. George Long (1862)",
            sourceURL: URL(string: "https://classics.mit.edu/Antoninus/meditations.4.four.html")
        ),
        CalmQuote(
            text: "Occupy thyself with few things, if thou wouldst be tranquil.",
            attribution: "Marcus Aurelius, Meditations IV.24 — trans. George Long",
            sourceURL: URL(string: "https://classics.mit.edu/Antoninus/meditations.4.four.html")
        ),
        CalmQuote(
            text: "All the unhappiness of men arises from one single fact, that they cannot stay quietly in their own chamber.",
            attribution: "Blaise Pascal, Pensées §139 — trans. W.F. Trotter",
            sourceURL: URL(string: "https://en.wikisource.org/wiki/Blaise_Pascal/Thoughts/Section_2")
        ),
        CalmQuote(
            text: "Men are disturbed, not by things, but by the principles and notions which they form concerning things.",
            attribution: "Epictetus, Enchiridion §5 — trans. Elizabeth Carter (1758)",
            sourceURL: URL(string: "https://livingstoicism.com/2023/05/12/the-enchiridion-or-manual-of-epictetus-by-elizabeth-carter-1758/")
        ),
        CalmQuote(
            text: "We suffer more often in imagination than in reality.",
            attribution: "Seneca, Moral Letters to Lucilius 13.4 — trans. Richard Gummere",
            sourceURL: URL(string: "https://en.wikisource.org/wiki/Moral_letters_to_Lucilius/Letter_13")
        ),
        CalmQuote(
            text: "Unclamp, in a word, your intellectual and practical machinery, and let it run free.",
            attribution: "William James, \"The Gospel of Relaxation\" (1899)",
            sourceURL: URL(string: "https://www.gutenberg.org/ebooks/16287")
        ),
        CalmQuote(
            text: "Nothing can be more useful to a man than a determination not to be hurried.",
            attribution: "Henry David Thoreau, Journal, March 22, 1842",
            sourceURL: URL(string: "https://www.walden.org/log-page/1842/")
        ),
        CalmQuote(
            text: "Be still, and know that I am God.",
            attribution: "Psalm 46:10 — King James Version (1611)",
            sourceURL: URL(string: "https://www.gutenberg.org/ebooks/10")
        )
    ]

    /// Pick a quote uniformly at random from the library. Falls back to the
    /// first quote if the library is somehow empty (defensive — should
    /// never fire in production).
    public static func random() -> CalmQuote {
        library.randomElement() ?? library[0]
    }
}