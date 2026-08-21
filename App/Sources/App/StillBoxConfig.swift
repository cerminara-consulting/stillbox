import Foundation

/// Single source of truth for app-wide constants and external resource URLs.
///
/// Why this exists: app-wide URLs and identifiers must be easy to find, easy
/// to update, and impossible to drift between files. Apple's App Store
/// Review Guidelines 5.1.1 (Privacy Policy URL) and 1.4.1 (Safety info)
/// both require these URLs to be reachable *from inside the app*, so the
/// same URLs that go into App Store Connect must be the URLs that the
/// About sheet links to.
///
/// All values here are placeholders until John wires them up at submission
/// time. Update both this file AND App Store Connect together so they can
/// never drift.
public enum StillBoxConfig {

    // MARK: - App identity

    /// PLACEHOLDER — John will pick a real name before App Store submission.
    public static let displayName = "StillBox"

    /// App Store URL (filled in after launch).
    public static let appStoreURL = "https://apps.apple.com/app/idXXXXXXXXX"

    /// Minimum iOS version. Mirrors `IPHONEOS_DEPLOYMENT_TARGET` in `project.yml`.
    public static let minIOS = "17.0"

    // MARK: - Required URLs

    /// Privacy Policy URL. Used in:
    /// 1. About sheet — "Privacy Policy" row in the "Read More" section
    /// 2. App Store Connect listing — "Privacy Policy URL" field
    ///
    /// Apple requires both. They must match.
    ///
    /// PLACEHOLDER — point at the production privacy URL once
    /// `cerminaraconsulting.com/stillbox/privacy` is live. Until then,
    /// this is the Cloudflare Pages staging URL.
    public static let privacyPolicyURL: URL = URL(string: "https://stillbox-site-1s8.pages.dev/privacy-policy/")!

    /// Safety page URL. Required by Apple App Store Guideline 1.4.1
    /// ("Physical harm"): apps that guide users through breath-hold
    /// exercises must surface safety information from inside the app.
    ///
    /// PLACEHOLDER — same staging URL pattern as the privacy policy.
    /// Swap to production once `cerminaraconsulting.com/stillbox/safety`
    /// is live.
    public static let safetyURL: URL = URL(string: "https://stillbox-site-1s8.pages.dev/safety/")!

    /// Support URL. Used in:
    /// 1. About sheet — "Support" row in the "Read More" section
    /// 2. App Store Connect listing — "Support URL" field
    ///
    /// PLACEHOLDER — staging URL for now.
    public static let supportURL: URL = URL(string: "https://stillbox-site-1s8.pages.dev/support/")!

    // MARK: - Contact

    /// Single contact email for all inbound user messages. Configured to
    /// a real inbox John controls (per memory: must NOT be a plausible-
    /// looking address on his domain that isn't actually set up to
    /// receive mail).
    public static let supportEmail = "support@cerminaraconsulting.com"
}