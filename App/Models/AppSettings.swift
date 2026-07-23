import Foundation

/// All UserDefaults-backed user settings. Stored separately from
/// `BreathEngine` because we want settings to persist independently of the
/// engine's transient runtime state.
///
/// Why a separate type: makes "what does this app remember about the user?"
/// answerable in one file. v1 collects zero data; everything in this struct is
/// opt-in configuration, no telemetry.
public struct AppSettings: Codable, Equatable {

    // MARK: - Pattern

    /// The user's selected pattern, persisted as a UUID. Maps back to either
    /// a built-in preset or a `BreathingPattern` in the custom-patterns store.
    public var selectedPatternID: UUID?

    /// Custom patterns the user has created. Decoded lazily.
    public var customPatterns: [BreathingPattern]

    // MARK: - Session

    public var roundCount: RoundCount
    public var soundEnabled: Bool
    public var hapticsEnabled: Bool
    public var reduceMotionOverride: Bool?

    // MARK: - Tip jar + unlocks (UI-only mirror of StoreManager state)

    /// True if the user has unlocked the "Patterns" IAP. Mirrored from
    /// StoreManager for fast Settings-sheet access.
    public var patternsUnlocked: Bool

    // MARK: - Init / defaults

    public init(
        selectedPatternID: UUID? = nil,
        customPatterns: [BreathingPattern] = [],
        roundCount: RoundCount = .four,
        soundEnabled: Bool = false,
        hapticsEnabled: Bool = true,
        reduceMotionOverride: Bool? = nil,
        patternsUnlocked: Bool = false
    ) {
        self.selectedPatternID = selectedPatternID
        self.customPatterns = customPatterns
        self.roundCount = roundCount
        self.soundEnabled = soundEnabled
        self.hapticsEnabled = hapticsEnabled
        self.reduceMotionOverride = reduceMotionOverride
        self.patternsUnlocked = patternsUnlocked
    }

    public static let defaults = AppSettings()

    // MARK: - RoundCount

    public enum RoundCount: String, CaseIterable, Codable, Identifiable {
        case four
        case eight
        case twelve
        case continuous

        public var id: String { rawValue }

        public var label: String {
            switch self {
            case .four:        return "4 rounds"
            case .eight:       return "8 rounds"
            case .twelve:      return "12 rounds"
            case .continuous:  return "Continuous"
            }
        }

        /// Integer value for the engine's `targetRounds`. `.continuous` is nil.
        public var targetRoundsValue: Int? {
            switch self {
            case .four:        return 4
            case .eight:       return 8
            case .twelve:      return 12
            case .continuous:  return nil
            }
        }
    }

    // MARK: - Persistence

    private static let userDefaultsKey = "stillbox.settings.v1"

    /// Decode the settings struct from UserDefaults. Returns `.defaults` if
    /// nothing has ever been saved or if decoding fails (e.g. across a
    /// breaking-version schema change).
    public static func load() -> AppSettings {
        guard
            let data = UserDefaults.standard.data(forKey: userDefaultsKey),
            let decoded = try? JSONDecoder().decode(AppSettings.self, from: data)
        else {
            return .defaults
        }
        return decoded
    }

    /// Encode and persist the settings struct.
    public func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        UserDefaults.standard.set(data, forKey: Self.userDefaultsKey)
    }
}
