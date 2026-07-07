import Foundation

struct TuitionlogItem: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var note: String
    var value: Double
    var date: Date
    var isDone: Bool = false

    init(id: UUID = UUID(), title: String, note: String = "", value: Double = 0, date: Date = Date(), isDone: Bool = false) {
        self.id = id
        self.title = title
        self.note = note
        self.value = value
        self.date = date
        self.isDone = isDone
    }
}
