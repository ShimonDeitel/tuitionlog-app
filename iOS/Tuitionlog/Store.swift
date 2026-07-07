import Foundation
import Combine

@MainActor
final class Store: ObservableObject {
    @Published private(set) var items: [TuitionlogItem] = []

    /// Free-tier cap. Deliberately kept well above the seed data count
    /// so a fresh install never trips the paywall immediately.
    static let freeLimit = 25

    private let fileURL: URL

    init() {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Tuitionlog", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.fileURL = dir.appendingPathComponent("items.json")
        load()
    }

    var canAddMore: Bool {
        items.count < Store.freeLimit
    }

    @discardableResult
    func add(title: String, note: String = "", value: Double = 0, date: Date = Date()) -> Bool {
        guard canAddMore else { return false }
        let item = TuitionlogItem(title: title, note: note, value: value, date: date)
        items.insert(item, at: 0)
        save()
        return true
    }

    func update(_ item: TuitionlogItem) {
        guard let idx = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[idx] = item
        save()
    }

    func delete(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
        save()
    }

    func delete(_ item: TuitionlogItem) {
        items.removeAll { $0.id == item.id }
        save()
    }

    func toggleDone(_ item: TuitionlogItem) {
        guard let idx = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[idx].isDone.toggle()
        save()
    }

    private func load() {
        if let data = try? Data(contentsOf: fileURL),
           let decoded = try? JSONDecoder().decode([TuitionlogItem].self, from: data) {
            items = decoded
        } else {
            items = Store.seedData
        }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    static var seedData: [TuitionlogItem] {
        let now = Date()
        let cal = Calendar.current
        return (0..<5).map { i in
            TuitionlogItem(
                title: "Sample Installment \(i + 1)",
                note: "Example entry — edit or delete me.",
                value: Double(i + 1) * 1.5,
                date: cal.date(byAdding: .day, value: -i, to: now) ?? now
            )
        }
    }
}
