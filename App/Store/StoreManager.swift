import Foundation
import StoreKit

/// A thin facade over `StoreKit 2`.
///
/// Exposes:
///   - `isPatternsUnlocked`     — whether the one-time unlock has been purchased
///   - `tipProducts`            — the three tip jar products (loaded async)
///   - `purchase(_:)`           — buy a product
///   - `restorePurchases()`     — restore non-consumables from the Apple ID
///
/// Why a separate type: keeping StoreKit out of the view layer means views
/// can be tested against a mock `StoreManager` without real App Store
/// connections. Reduces cognitive surface area.
@MainActor
public final class StoreManager: ObservableObject {

    @Published public private(set) var isPatternsUnlocked: Bool = false
    @Published public private(set) var tipProducts: [Product] = []

    /// Product identifiers registered in App Store Connect.
    public static let patternsProductID = "com.cerminara.stillbox.patterns"
    public static let tipProductIDs: [String] = [
        "com.cerminara.stillbox.tip.1",
        "com.cerminara.stillbox.tip.3",
        "com.cerminara.stillbox.tip.5"
    ]

    private var transactionListener: Task<Void, Never>?

    public init() {
        transactionListener = listenForTransactions()
        Task { await refresh() }
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - Products

    /// Load the available products and check for existing unlocks.
    public func refresh() async {
        do {
            let allIDs = [Self.patternsProductID] + Self.tipProductIDs
            let loadedProducts = try await Product.products(for: allIDs)
            self.tipProducts = loadedProducts.filter { Self.tipProductIDs.contains($0.id) }
        } catch {
            // StoreKit error: log to console in debug, never surface to user.
            #if DEBUG
            print("[StillBox] Product load failed: \(error.localizedDescription)")
            #endif
        }
        await refreshEntitlements()
    }

    /// Check the user's transaction history for the unlock.
    public func refreshEntitlements() async {
        for await result in Transaction.currentEntitlements {
            guard case .verified(let tx) = result else { continue }
            if tx.productID == Self.patternsProductID {
                self.isPatternsUnlocked = true
            }
        }
    }

    // MARK: - Purchasing

    /// Begin a purchase. Returns true if the purchase completed successfully
    /// (including for the user's own already-restored entitlement).
    @discardableResult
    public func purchase(_ product: Product) async -> Bool {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let tx):
                    await tx.finish()
                    await refreshEntitlements()
                    return true
                case .unverified:
                    return false
                }
            case .userCancelled, .pending:
                return false
            @unknown default:
                return false
            }
        } catch {
            #if DEBUG
            print("[StillBox] Purchase failed: \(error.localizedDescription)")
            #endif
            return false
        }
    }

    /// Restore previously purchased non-consumables. Called from the
    /// About screen's "Restore Purchases" button.
    public func restorePurchases() async {
        try? await AppStore.sync()
        await refreshEntitlements()
    }

    // MARK: - Transaction listener

    /// Listen for new transactions while the app is running. Persists any
    /// new unlocks without requiring the user to re-open the app.
    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached(priority: .background) { [weak self] in
            for await result in Transaction.updates {
                guard
                    case .verified(let tx) = result,
                    let self
                else { continue }
                await MainActor.run {
                    Task { await self.refreshEntitlements() }
                }
                await tx.finish()
            }
        }
    }
}
