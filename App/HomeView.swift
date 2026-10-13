import SwiftUI

struct HomeView: View {
    @EnvironmentObject var store: HabitStore
    @State private var showAdd = false

    var body: some View {
        NavigationStack {
            ZStack {
                QWBackground()
                ScrollView {
                    TimelineView(.periodic(from: Date(), by: 1)) { ctx in
                        VStack(spacing: 12) {
                            if store.habits.isEmpty {
                                EmptyHabits()
                            } else {
                                ForEach(store.habits) { h in HabitCard(habit: h, now: ctx.date) }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 6)
                        .padding(.bottom, 28)
                    }
                }
            }
            .navigationTitle("Your Habits")
            .navigationDestination(for: Habit.self) { HabitDetailView(habit: $0) }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAdd = true } label: { Image(systemName: "plus").font(.round(17, .bold)) }
                        .tint(QW.accent)
                }
            }
            .sheet(isPresented: $showAdd) { AddHabitView() }
        }
        .tint(QW.accent)
    }
}

struct HabitCard: View {
    @EnvironmentObject var store: HabitStore
    let habit: Habit
    var now: Date = Date()
    @State private var confirmReset = false

    var body: some View {
        NavigationLink(value: habit) {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(habit.name).font(.round(17, .semibold)).foregroundStyle(QW.text)
                    Text(habit.liveSubtitle(now)).font(.system(size: 13)).foregroundStyle(QW.muted)
                        .contentTransition(.numericText())
                }
                Spacer()
                Text("\(habit.primaryValue(now))").font(.round(30, .heavy)).foregroundStyle(QW.text)
                    .contentTransition(.numericText())
            }
            .padding(16)
            .background(QW.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: Color(hex: "3E63A8").opacity(0.12), radius: 14, x: 0, y: 6)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button { confirmReset = true } label: { Label(habit.resetTitle, systemImage: "arrow.counterclockwise") }
            Button(role: .destructive) { store.delete(habit) } label: { Label("Delete", systemImage: "trash") }
        }
        .alert("Reset \(habit.name) to 0?", isPresented: $confirmReset) {
            Button("Reset to 0", role: .destructive) { store.reset(habit) }
            Button("Cancel", role: .cancel) {}
        }
    }
}

// Its own tab: how to add the Home Screen widget.
struct WidgetGuideView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                QWBackground()
                ScrollView {
                    VStack(spacing: 16) {
                        Image(systemName: "square.grid.2x2.fill").font(.system(size: 44)).foregroundStyle(QW.accent)
                            .padding(.top, 12)

                        VStack(alignment: .leading, spacing: 16) {
                            step(1, "Touch and hold any empty spot on your Home Screen until the apps jiggle.")
                            step(2, "Tap the + in the top corner.")
                            step(3, "Search \"Quit With Help\" and pick a size — small, medium, or large.")
                            step(4, "Tap Add Widget, then Done.")
                        }
                        .qwCard()
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Widget")
        }
        .tint(QW.accent)
    }

    private func step(_ n: Int, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(n)").font(.round(15, .heavy)).foregroundStyle(.white)
                .frame(width: 28, height: 28).background(QW.accent, in: Circle())
            Text(text).font(.system(size: 15)).foregroundStyle(QW.text)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }
}

struct EmptyHabits: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "flame").font(.system(size: 44)).foregroundStyle(QW.accent.opacity(0.7))
            Text("Nothing to keep yet").font(.round(20, .bold)).foregroundStyle(QW.text)
            Text("Tap + to add the first thing you want to quit or build.")
                .font(.system(size: 14)).foregroundStyle(QW.muted).multilineTextAlignment(.center)
        }
        .padding(.top, 80).padding(.horizontal, 30)
    }
}
