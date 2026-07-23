import Foundation

/// The four phases of a breath cycle. Order is significant: a complete cycle
/// proceeds from `.inhale` -> `.holdIn` -> `.exhale` -> `.holdOut`.
public enum BreathPhase: String, CaseIterable, Equatable {
    case inhale
    case holdIn
    case exhale
    case holdOut

    /// Human-readable label rendered inside the box during the phase.
    /// Kept in plain English per the SPEC §12 Understandable clause.
    public var label: String {
        switch self {
        case .inhale:   return "in"
        case .holdIn:   return "hold"
        case .exhale:   return "out"
        case .holdOut:  return "hold"
        }
    }

    /// VoiceOver announcement for this phase. Verbose so screen-reader users
    /// know what's happening and what comes next.
    public var accessibilityLabel: String {
        switch self {
        case .inhale:   return "Inhaling"
        case .holdIn:   return "Holding breath in"
        case .exhale:   return "Exhaling"
        case .holdOut:  return "Holding breath out"
        }
    }

    /// The next phase in the cycle. The cycle wraps from `.holdOut` back to
    /// `.inhale` — there is no end phase.
    public var next: BreathPhase {
        switch self {
        case .inhale:   return .holdIn
        case .holdIn:   return .exhale
        case .exhale:   return .holdOut
        case .holdOut:  return .inhale
        }
    }
}
