import SwiftUI

struct AddHabitView: View {
    @EnvironmentObject var store: HabitStore
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var mode: HabitMode

    init(mode: HabitMode = .quit) { _mode = State(initialValue: mode) }

    var body: some View {
        NavigationStack {
            ZStack {
                QWBackground()
                ScrollView {
                    VStack(spacing: 22) {
                        Picker("", selection: $mode) {
                            Text("Quit something").tag(HabitMode.quit)
                            Text("Build a habit").tag(HabitMode.build)
                        }
                        .pickerStyle(.segmented)

                        TextField("", text: $name, prompt: Text(mode == .quit ? "Name it (e.g. Quit YouTube)" : "Name it (e.g. Workout each day)").foregroundColor(QW.muted))
                            .font(.round(20, .semibold)).foregroundStyle(QW.text)
                            .multilineTextAlignment(.center)
                            .padding(16)
                            .background(QW.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .padding(24)
                }
            }
            .navigationTitle("New habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() }.tint(QW.muted) }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let n = name.trimmingCharacters(in: .whitespaces)
                        if !n.isEmpty { store.addHabit(n, emoji: "", colorHex: "2F80ED", mode: mode); dismiss() }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    .tint(QW.accent).fontWeight(.bold)
                }
            }
        }
    }
}
