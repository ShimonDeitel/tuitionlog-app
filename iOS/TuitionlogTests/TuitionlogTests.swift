import XCTest
@testable import Tuitionlog

@MainActor
final class TuitionlogTests: XCTestCase {
    var store: Store!

    override func setUp() async throws {
        store = Store()
    }

    func testSeedDataLoadedOnFreshInstall() {
        XCTAssertFalse(store.items.isEmpty)
    }

    func testSeedCountBelowFreeLimit() {
        XCTAssertLessThan(Store.seedData.count, Store.freeLimit)
    }

    func testAddIncreasesCount() {
        let before = store.items.count
        store.add(title: "New entry")
        XCTAssertEqual(store.items.count, before + 1)
    }

    func testAddRespectsFreeLimit() {
        while store.canAddMore {
            store.add(title: "Filler")
        }
        let countAtLimit = store.items.count
        let didAdd = store.add(title: "Over limit")
        XCTAssertFalse(didAdd)
        XCTAssertEqual(store.items.count, countAtLimit)
    }

    func testDeleteRemovesItem() {
        store.add(title: "To delete")
        let item = store.items[0]
        store.delete(item)
        XCTAssertFalse(store.items.contains(item))
    }

    func testUpdateChangesFields() {
        store.add(title: "Original")
        var item = store.items[0]
        item.title = "Updated"
        store.update(item)
        XCTAssertEqual(store.items[0].title, "Updated")
    }

    func testToggleDoneFlipsState() {
        store.add(title: "Task")
        let item = store.items[0]
        XCTAssertFalse(item.isDone)
        store.toggleDone(item)
        XCTAssertTrue(store.items[0].isDone)
    }

    func testDeleteAtOffsets() {
        let before = store.items.count
        store.delete(at: IndexSet(integer: 0))
        XCTAssertEqual(store.items.count, before - 1)
    }
}
