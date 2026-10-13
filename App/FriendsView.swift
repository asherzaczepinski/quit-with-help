import SwiftUI

struct FriendsView: View {
    @EnvironmentObject var store: HabitStore
    @State private var code = ""

    var body: some View {
        NavigationStack {
            ZStack {
                QWBackground()
                ScrollView {
                    VStack(spacing: 14) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Add a friend").font(.round(14, .semibold)).foregroundStyle(QW.muted)
                            HStack(spacing: 10) {
                                TextField("", text: $code, prompt: Text("Their share code").foregroundColor(QW.muted))
                                    .textInputAutocapitalization(.characters)
                                    .autocorrectionDisabled()
                                    .font(.round(16, .semibold)).foregroundStyle(QW.text)
                                    .padding(14)
                                    .background(QW.surface2, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                                Button("Add") { store.addFriend(code: code); code = ""; hideKeyboard() }
                                    .buttonStyle(QWButtonStyle())
                                    .frame(width: 88)
                                    .disabled(code.trimmingCharacters(in: .whitespaces).count < 4)
                            }
                        }
                        .qwCard()

                        if store.friends.isEmpty {
                            Text("No friends yet. Add someone's code to cheer each other on — and be there when they hit a craving.")
                                .font(.system(size: 14)).foregroundStyle(QW.muted)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .qwCard(16)
                        }

                        ForEach(store.friends) { f in
                            NavigationLink(value: f) { FriendCard(friend: f) }
                                .buttonStyle(.plain)
                        }
                    }
                    .padding(20)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("Friends")
            .navigationDestination(for: Friend.self) { FriendDetailView(friend: $0) }
        }
        .tint(QW.accent)
    }
}

struct FriendCard: View {
    @EnvironmentObject var store: HabitStore
    let friend: Friend

    var body: some View {
        HStack(spacing: 14) {
            Circle().fill(QW.surface2).frame(width: 44, height: 44)
                .overlay(Text(String(friend.name.prefix(1)).uppercased()).font(.round(18, .bold)).foregroundStyle(QW.accent))
            VStack(alignment: .leading, spacing: 2) {
                Text(friend.name).font(.round(16, .semibold)).foregroundStyle(QW.text)
                if friend.sos != nil {
                    Text("🆘 needs a hand right now").font(.round(12, .semibold)).foregroundStyle(QW.danger)
                } else {
                    Text("top: \(friend.topHabit)").font(.system(size: 12)).foregroundStyle(QW.muted)
                }
            }
            Spacer()
            Text("\(friend.streak)").font(.round(24, .heavy))
                .foregroundStyle(friend.sos != nil ? QW.danger : QW.accent)
            Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold)).foregroundStyle(QW.muted)
        }
        .qwCard(16)
        .contextMenu {
            Button(role: .destructive) { store.removeFriend(friend) } label: {
                Label("Remove", systemImage: "trash")
            }
        }
    }
}

struct FriendDetailView: View {
    @EnvironmentObject var store: HabitStore
    let friend: Friend
    @State private var habits: [Habit] = []
    @State private var loading = true

    private func craving(_ h: Habit) -> Bool { friend.sos != nil && friend.sosHabitName == h.name }

    var body: some View {
        ZStack {
            QWBackground()
            ScrollView {
                VStack(spacing: 16) {
                    VStack(spacing: 8) {
                        Circle().fill(QW.surface2).frame(width: 66, height: 66)
                            .overlay(Text(String(friend.name.prefix(1)).uppercased()).font(.round(28, .bold)).foregroundStyle(QW.accent))
                        Text(friend.name).font(.round(24, .bold)).foregroundStyle(QW.text)
                    }
                    .padding(.top, 8)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Their streaks — tap one").font(.round(14, .semibold)).foregroundStyle(QW.muted)
                        if loading {
                            ProgressView().tint(QW.accent).frame(maxWidth: .infinity)
                        } else if habits.isEmpty {
                            Text("No habits yet.").font(.system(size: 14)).foregroundStyle(QW.muted)
                        } else {
                            ForEach(habits) { h in
                                NavigationLink { FriendStreakView(friend: friend, habit: h) } label: {
                                    FriendStreakRow(habit: h, craving: craving(h))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .qwCard()
                }
                .padding(20)
            }
        }
        .navigationTitle(friend.shareCode.isEmpty ? friend.name : "@\(friend.shareCode)")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            habits = await store.friendHabits(friend)
            loading = false
        }
    }
}

// One tappable streak row in a friend's list.
struct FriendStreakRow: View {
    let habit: Habit
    let craving: Bool

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(habit.name).font(.round(16, .semibold)).foregroundStyle(QW.text)
                if craving {
                    Text("🆘 needs a hand right now").font(.round(12, .semibold)).foregroundStyle(QW.danger)
                } else {
                    Text(habit.liveSubtitle()).font(.system(size: 12)).foregroundStyle(QW.muted)
                }
            }
            Spacer()
            Text("\(habit.primaryValue())").font(.round(24, .heavy)).foregroundStyle(QW.text)
            Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold)).foregroundStyle(QW.muted)
        }
        .padding(.vertical, 4)
    }
}

// A friend's single streak, with craving help if it's the one they're fighting.
struct FriendStreakView: View {
    @EnvironmentObject var store: HabitStore
    let friend: Friend
    let habit: Habit

    private var isCraving: Bool { friend.sos != nil && friend.sosHabitName == habit.name }

    var body: some View {
        ZStack {
            QWBackground()
            ScrollView {
                VStack(spacing: 20) {
                    TimelineView(.periodic(from: Date(), by: 1)) { ctx in
                        VStack(spacing: 2) {
                            Text("\(habit.primaryValue(ctx.date))")
                                .font(.round(84, .heavy)).foregroundStyle(QW.text)
                                .contentTransition(.numericText())
                            Text(habit.primaryUnit(ctx.date))
                                .font(.round(16, .medium)).foregroundStyle(QW.muted)
                        }
                    }
                    .padding(.top, 16)

                    if isCraving {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack { Image(systemName: "hand.raised.fill"); Text("Craving help").font(.round(15, .bold)); Spacer() }
                            Text(friend.sos ?? "").font(.round(16, .medium))
                            if let at = friend.sosAt {
                                Text("\(at, style: .relative) ago · \(at.formatted(date: .abbreviated, time: .shortened))")
                                    .font(.system(size: 12)).foregroundStyle(QW.danger.opacity(0.8))
                            }
                            Text("\(friend.name) is fighting the urge right now. Reach out to them.")
                                .font(.system(size: 13)).foregroundStyle(QW.danger.opacity(0.9))
                        }
                        .foregroundStyle(QW.danger)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(QW.danger.opacity(0.14), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .padding(.horizontal, 20)
                    } else {
                        Text("No craving on \(habit.name) right now — they're doing great.")
                            .font(.system(size: 14)).foregroundStyle(QW.muted)
                            .multilineTextAlignment(.center).padding(.horizontal, 30)
                    }
                }
                .padding(.bottom, 34)
            }
        }
        .navigationTitle(habit.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { if isCraving { store.markCravingSeen(friend) } }
    }
}
