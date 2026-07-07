import Foundation
import StoreKit

@MainActor
final class PurchaseManager: ObservableObject {
    static let productID = "com.shimondeitel.tuitionlog.pro_unlock"

    @Published private(set) var isPro: Bool = false
    @Published private(set) var product: Product?

    private var updatesTask: Task<Void, Never>?

    init() {
        updatesTask = Task { [weak self] in
            for await update in Transaction.updates {
                if case .verified(let transaction) = update {
                    await self?.refresh()
                    await transaction.finish()
                }
            }
        }
        Task { await loadProducts() }
        Task { await refresh() }
    }

    deinit {
        updatesTask?.cancel()
    }

    func loadProducts() async {
        guard let products = try? await Product.products(for: [Self.productID]) else { return }
        product = products.first
    }

    func purchase() async {
        guard let product else { return }
        guard let result = try? await product.purchase() else { return }
        switch result {
        case .success(let verification):
            if case .verified(let transaction) = verification {
                await transaction.finish()
                await refresh()
            }
        default:
            break
        }
    }

    func restore() async {
        try? await AppStore.sync()
        await refresh()
    }

    func refresh() async {
        var active = false
        for await entitlement in Transaction.currentEntitlements {
            if case .verified(let transaction) = entitlement, transaction.productID == Self.productID {
                active = true
            }
        }
        isPro = active
    }
}
