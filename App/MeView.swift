import SwiftUI
import UserNotifications

struct MeView: View {
    @EnvironmentObject var store: HabitStore
    @EnvironmentObject var auth: AuthModel
    @State private var notifOn = false

    var body: some View {
        NavigationStack {
            ZStack {
                QWBackground()
                ScrollView {
                    VStack(spacing: 14) {
                        // profile + share code
                        VStack(spacing: 6) {
                            Text(store.userName.isEmpty ? "You" : store.userName)
                                .font(.round(24, .bold)).foregroundStyle(QW.text)
                            Text("share code").font(.system(size: 12)).foregroundStyle(QW.muted)
                            Text(store.shareCode)
                                .font(.round(24, .heavy)).foregroundStyle(QW.accent).tracking(4)
                            ShareLink(item: "Follow my streaks on Quit With Help — my code is \(store.shareCode)") {
                                Label("Share my code", systemImage: "square.and.arrow.up")
                                    .font(.round(15, .semibold))
                            }
                            .tint(QW.accent)
                            .padding(.top, 6)
                        }
                        .frame(maxWidth: .infinity)
                        .qwCard(22)

                        // stats
                        HStack(spacing: 12) {
                            stat("Habits", "\(store.habits.count)")
                            stat("Best", "\(store.habits.map { $0.streak }.max() ?? 0)")
                            stat("Friends", "\(store.friends.count)")
                        }

                        Button {
                            Notifier.enable()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { refreshNotif() }
                        } label: {
                            HStack {
                                Image(systemName: "bell.fill").foregroundStyle(QW.accent)
                                Text(notifOn ? "Notifications are on" : "Turn on notifications")
                                    .font(.round(15, .semibold)).foregroundStyle(QW.text)
                                Spacer()
                                Image(systemName: notifOn ? "checkmark" : "chevron.right")
                                    .foregroundStyle(notifOn ? QW.accent : QW.muted)
                            }
                            .qwCard(16)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 4)

                        Button(role: .destructive) {
                            Task { await auth.signOut() }
                        } label: {
                            Label("Sign out", systemImage: "rectangle.portrait.and.arrow.right")
                                .font(.round(16, .semibold))
                                .frame(maxWidth: .infinity)
                        }
                        .tint(QW.danger)
                        .padding(.top, 8)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Me")
            .onAppear { refreshNotif() }
        }
    }

    private func refreshNotif() {
        UNUserNotificationCenter.current().getNotificationSettings { s in
            let on = (s.authorizationStatus == .authorized || s.authorizationStatus == .provisional)
            DispatchQueue.main.async { notifOn = on }
        }
    }

    private func stat(_ t: String, _ v: String) -> some View {
        VStack(spacing: 4) {
            Text(v).font(.round(24, .heavy)).foregroundStyle(QW.text)
            Text(t).font(.system(size: 12)).foregroundStyle(QW.muted)
        }
        .frame(maxWidth: .infinity)
        .qwCard(16)
    }
}
