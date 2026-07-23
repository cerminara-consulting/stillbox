import Foundation
import UIKit

/// A thin wrapper around `UIImpactFeedbackGenerator` with a single, calm
/// haptic style. The view layer calls `phaseChanged()` on every breath phase
/// transition.
///
/// Why a wrapper: keeping all `import UIKit` references in one file makes
/// the View layer testable as a pure-Swift dependency.
@MainActor
public final class HapticEngine {

    private let generator: UIImpactFeedbackGenerator

    public init() {
        // `.soft` is the lightest, most breath-appropriate haptic style.
        // Pre-prepare so the first tap has no latency.
        self.generator = UIImpactFeedbackGenerator(style: .soft)
        self.generator.prepare()
    }

    /// Single tap intended to be called on each breath phase change.
    public func phaseChanged() {
        generator.impactOccurred(intensity: 0.6)
        // Re-prepare for next call.
        generator.prepare()
    }

    /// Single subtle tap used for the completion pulse. Even gentler than
    /// phase transitions.
    public func completionPulse() {
        generator.impactOccurred(intensity: 0.4)
        generator.prepare()
    }
}
