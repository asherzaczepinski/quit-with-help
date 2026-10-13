import SwiftUI

struct HabitDetailView: View {
    @EnvironmentObject var store: HabitStore
    let habit: Habit
    @State private var showSOS: Bool
    @State private var sosSent = false
    @State private var confirmReset: Bool

    init(habit: Habit, showSOS: Bool = false, confirmReset: Bool = false) {
        self.habit = habit
        _showSOS = State(initialValue: showSOS)
        _confirmReset = State(initialValue: confirmReset)
    }
    private var live: Habit { store.habits.first { $0.id == habit.id } ?? habit }

    var body: some View {
        ZStack {
            QWBackground()
            ScrollView {
                VStack(spacing: 20) {
                    TimelineView(.periodic(from: Date(), by: 1)) { ctx in
                        VStack(spacing: 2) {
                            Text("\(live.primaryValue(ctx.date))")
                                .font(.round(84, .heavy)).foregroundStyle(QW.text)
                                .contentTransition(.numericText())
                            Text(live.primaryUnit(ctx.date))
                                .font(.round(16, .medium)).foregroundStyle(QW.muted)
                        }
                    }
                    .padding(.top, 16)

                    Button { showSOS = true } label: {
                        Label(live.mode == .quit ? "I'm craving it — tell my friends"
                                                 : "I'm struggling — tell my friends",
                              systemImage: "hand.raised.fill")
                    }
                    .buttonStyle(QWButtonStyle(bg: QW.accent, fg: .white))
                    .padding(.horizontal, 20)

                    if sosSent {
                        Text("Sent. Your friends can see you need a hand right now.")
                            .font(.system(size: 13)).foregroundStyle(QW.accent)
                    }

                    Button { confirmReset = true } label: {
                        Label(live.resetTitle, systemImage: "arrow.counterclockwise")
                    }
                    .buttonStyle(QWButtonStyle(bg: QW.surface2, fg: QW.text))
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 34)
            }
        }
        .navigationTitle(live.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showSOS) {
            SOSSheet(habitName: live.name) { note in
                store.sendSOS(for: live, note: note)
                sosSent = true
            }
        }
        .alert("Reset \(live.name) to 0?", isPresented: $confirmReset) {
            Button("Reset to 0", role: .destructive) {
                withAnimation(.snappy) { store.reset(live); sosSent = false }
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}

struct SOSSheet: View {
    let habitName: String
    var onSend: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var note = ""

    var body: some View {
        NavigationStack {
            ZStack {
                QWBackground()
                VStack(alignment: .leading, spacing: 16) {
                    Text("Let your friends know you're fighting the urge on \(habitName). They'll see it and can reach out.")
                        .font(.round(17, .medium)).foregroundStyle(QW.text)
                        .fixedSize(horizontal: false, vertical: true)

                    TextField("", text: $note,
                              prompt: Text("Add a note (optional)").foregroundColor(QW.muted),
                              axis: .vertical)
                        .lineLimit(3...6)
                        .font(.round(16, .medium)).foregroundStyle(QW.text)
                        .padding(16)
                        .background(QW.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                    Button { onSend(note); dismiss() } label: { Text("Send SOS") }
                        .buttonStyle(QWButtonStyle())
                    Spacer()
                }
                .padding(24)
            }
            .navigationTitle("Craving help")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() }.tint(QW.muted) }
            }
        }
        .presentationDetents([.medium])
    }
}
