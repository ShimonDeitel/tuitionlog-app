import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: Store
    @EnvironmentObject var purchases: PurchaseManager

    @State private var showingAdd = false
    @State private var showingSettings = false
    @State private var showingPaywall = false
    @State private var editingItem: TuitionlogItem?

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                if store.items.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(store.items) { item in
                            row(for: item)
                                .listRowBackground(Theme.card)
                                .contentShape(Rectangle())
                                .onTapGesture { editingItem = item }
                        }
                        .onDelete { offsets in store.delete(at: offsets) }
                    }
                    .scrollContentBackground(.hidden)
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Tuitionlog")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                    }
                    .accessibilityIdentifier("settingsButton")
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        if store.canAddMore || purchases.isPro {
                            showingAdd = true
                        } else {
                            showingPaywall = true
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                    .accessibilityIdentifier("addButton")
                }
            }
            .sheet(isPresented: $showingAdd) {
                EditItemView(item: nil) { title, note, value, date in
                    store.add(title: title, note: note, value: value, date: date)
                }
            }
            .sheet(item: $editingItem) { item in
                EditItemView(item: item) { title, note, value, date in
                    var updated = item
                    updated.title = title
                    updated.note = note
                    updated.value = value
                    updated.date = date
                    store.update(updated)
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
        }
        .tint(Theme.accent)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 44))
                .foregroundStyle(Theme.textSecondary)
            Text("No entries yet")
                .font(Theme.headlineFont)
                .foregroundStyle(Theme.textPrimary)
            Text("Tap + to add your first installment.")
                .font(Theme.captionFont)
                .foregroundStyle(Theme.textSecondary)
        }
    }

    private func row(for item: TuitionlogItem) -> some View {
        HStack {
            Button {
                store.toggleDone(item)
            } label: {
                Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(item.isDone ? Theme.accent : Theme.textSecondary)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("toggleDone_\(item.id)")

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(Theme.bodyFont)
                    .foregroundStyle(Theme.textPrimary)
                    .strikethrough(item.isDone)
                if !item.note.isEmpty {
                    Text(item.note)
                        .font(Theme.captionFont)
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(2)
                }
            }
            Spacer()
            Text(item.date, style: .date)
                .font(Theme.captionFont)
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(.vertical, 4)
    }
}

struct EditItemView: View {
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?

    enum Field { case title, note, value }

    let item: TuitionlogItem?
    let onSave: (String, String, Double, Date) -> Void

    @State private var title: String
    @State private var note: String
    @State private var value: String
    @State private var date: Date

    init(item: TuitionlogItem?, onSave: @escaping (String, String, Double, Date) -> Void) {
        self.item = item
        self.onSave = onSave
        _title = State(initialValue: item?.title ?? "")
        _note = State(initialValue: item?.note ?? "")
        _value = State(initialValue: item != nil ? String(item!.value) : "")
        _date = State(initialValue: item?.date ?? Date())
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                Form {
                    Section("Details") {
                        TextField("Title", text: $title)
                            .focused($focusedField, equals: .title)
                            .accessibilityIdentifier("titleField")
                        TextField("Note", text: $note)
                            .focused($focusedField, equals: .note)
                            .accessibilityIdentifier("noteField")
                        TextField("Value", text: $value)
                            .keyboardType(.decimalPad)
                            .focused($focusedField, equals: .value)
                            .accessibilityIdentifier("valueField")
                        DatePicker("Date", selection: $date, displayedComponents: .date)
                    }
                }
                .scrollContentBackground(.hidden)
                .contentShape(Rectangle())
                .onTapGesture { focusedField = nil }
            }
            .navigationTitle(item == nil ? "Add" : "Edit")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .accessibilityIdentifier("cancelButton")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(title, note, Double(value) ?? 0, date)
                        dismiss()
                    }
                    .accessibilityIdentifier("saveButton")
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
