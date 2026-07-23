import Foundation

/// A breathing pattern: per-phase durations in seconds, plus a name and
/// plain-English summary.
///
/// Use one of the static `.box`, `.fourSevenEight`, `.threeFourFiveThree`
/// presets, or build a `BreathingPattern` directly for user-created patterns.
public struct BreathingPattern: Equatable, Codable, Hashable, Identifiable {
    public var id: UUID
    public var name: String
    public var inhaleSeconds: Int
    public var holdInSeconds: Int
    public var exhaleSeconds: Int
    public var holdOutSeconds: Int

    /// Total cycle length, in seconds. Useful for the UI summary.
    public var totalCycleSeconds: Int {
        inhaleSeconds + holdInSeconds + exhaleSeconds + holdOutSeconds
    }

    public init(
        id: UUID = UUID(),
        name: String,
        inhaleSeconds: Int,
        holdInSeconds: Int,
        exhaleSeconds: Int,
        holdOutSeconds: Int
    ) {
        self.id = id
        self.name = name
        self.inhaleSeconds = inhaleSeconds
        self.holdInSeconds = holdInSeconds
        self.exhaleSeconds = exhaleSeconds
        self.holdOutSeconds = holdOutSeconds
    }
}

// MARK: - Presets

public extension BreathingPattern {
    /// 4-4-4-4 box breath. Balanced, often used as a default for focus reset.
    static let box = BreathingPattern(
        name: "Box",
        inhaleSeconds: 4,
        holdInSeconds: 4,
        exhaleSeconds: 4,
        holdOutSeconds: 4
    )

    /// 4-7-8 breath. Designed for sleep onset / deep relaxation.
    static let fourSevenEight = BreathingPattern(
        name: "4-7-8",
        inhaleSeconds: 4,
        holdInSeconds: 7,
        exhaleSeconds: 8,
        holdOutSeconds: 0
    )

    /// 3-4-5-3 — a softer variation; exhale is the longest phase, which some
    /// practitioners find easier on the diaphragm.
    static let threeFourFiveThree = BreathingPattern(
        name: "3-4-5-3",
        inhaleSeconds: 3,
        holdInSeconds: 4,
        exhaleSeconds: 5,
        holdOutSeconds: 3
    )
}

// MARK: - Validation

public extension BreathingPattern {
    /// Per-phase validation bounds. Less than 1 second isn't really a phase;
    /// more than 12 seconds feels uncomfortable to maintain.
    /// Spec'd in SPEC §7 Settings > Pattern creator.
    static let minPhaseSeconds = 1
    static let maxPhaseSeconds = 12

    /// True if every phase is within the allowed range.
    var isValid: Bool {
        let phases = [inhaleSeconds, holdInSeconds, exhaleSeconds, holdOutSeconds]
        return phases.allSatisfy { ($0 >= Self.minPhaseSeconds) && ($0 <= Self.maxPhaseSeconds) }
    }
}

// MARK: - Plain-English summary

public extension BreathingPattern {
    /// Plain-English description used in the pattern-creator preview and in
    /// the Settings picker. Wording avoids the medical/clinical register
    /// and stays helpful.
    var summary: String {
        let phases = [
            "Inhale \(inhaleSeconds)",
            "hold \(holdInSeconds)",
            "exhale \(exhaleSeconds)",
            "hold \(holdOutSeconds)"
        ].filter { !$0.hasSuffix("hold 0") } // omit holds that are zero

        let body = phases.joined(separator: ", ")

        switch name {
        case "Box": return "Inhale 4, hold 4, exhale 4, hold 4 — a balanced reset."
        case "4-7-8": return "Inhale 4, hold 7, exhale 8 — a slower pattern for deep relaxation."
        case "3-4-5-3": return "Inhale 3, hold 4, exhale 5, hold 3 — softer on the diaphragm."
        default: return "\(body)."
        }
    }
}

// MARK: - Persistence (custom patterns)

public extension BreathingPattern {
    /// UserDefaults key for storing custom patterns, encoded as JSON.
    static let userDefaultsKey = "stillbox.customPatterns.v1"

    /// Encode/decode helpers. We round-trip through JSON so adding a new
    /// optional field is naturally backward-compatible (Codable tolerates
    /// unknown keys when synthesized key set is preserved).
    static func encode(_ patterns: [BreathingPattern]) -> Data? {
        try? JSONEncoder().encode(patterns)
    }

    static func decode(_ data: Data?) -> [BreathingPattern] {
        guard let data, let decoded = try? JSONDecoder().decode([BreathingPattern].self, from: data) else {
            return []
        }
        return decoded.filter(\.isValid)
    }
}
