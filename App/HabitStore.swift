import Foundation
import SwiftUI
import WidgetKit
import FirebaseFirestore

// ── Firestore document shapes ──
private struct FSHabit: Codable {
    @DocumentID var id: String?
    var userId = ""; var name = ""; var emoji = ""; var colorHex = "2F80ED"
    var mode: String?
    var startedAt: Timestamp?
    var createdAt: Timestamp?
}
private struct FSProfileAC: Codable {
    @DocumentID var id: String?
    var name = ""; var shareCode = ""
    var sosHabit: String?
    var sosNote: String?
    var sosAt: Timestamp?
    var brokeHabit: String?
    var brokeMode: String?
    var brokeAt: Timestamp?
}
private struct FSFollow: Codable {
    @DocumentID var id: String?
    var followerId = ""; var followeeId = ""
}

private func fsUUID(_ s: String?) -> UUID { UUID(uuidString: s ?? "") ?? UUID() }

private func stableID(_ s: String) -> UUID {
    var bytes = [UInt8](repeating: 0, count: 16)
    for (i, b) in Array(s.utf8).enumerated() { bytes[i % 16] = bytes[i % 16] &+ b &+ UInt8(i & 0x0F) }
    return NSUUID(uuidBytes: bytes) as UUID
}

@MainActor
final class HabitStore: ObservableObject {
    @Published var habits: [Habit] = []
    @Published var friends: [Friend] = []
    @Published var userName: String = "" { didSet { refreshWidget() } }
    @Published var onboarded = false
    @Published var shareCode: String = ""
    @Published var ready = false
    @Published var unseenCravings = 0   // friends' cravings you haven't opened → app-icon + tab badge

    private var userID: String?
    private var friendUID: [UUID: String] = [:]
    private var listeners: [ListenerRegistration] = []
    private var profileListeners: [ListenerRegistration] = []
    private var seenCravings: Set<String> = Set(UserDefaults.standard.stringArray(forKey: "qw_seen_cravings") ?? [])
    private var watchedProfileIDs: Set<String> = []
    private var seenSOS: Set<String> = []
    private var didFirstFriendLoad = false
    private var db: Firestore { Firestore.firestore() }
    #if DEBUG
    var demoFriendHabits: [UUID: [Habit]] = [:]
    #endif

    init() {}

    func start(userID: String, email: String) async {
        self.userID = userID
        await loadProfile()
        await reload()
        subscribe()
        ready = true
    }

    func stop() {
        (listeners + profileListeners).forEach { $0.remove() }
        listeners.removeAll(); profileListeners.removeAll()
        userID = nil
    }

    private func loadProfile() async {
        guard let me = userID else { return }
        let ref = db.collection("ac_profiles").document(me)
        do {
            let snap = try await ref.getDocument()
            if snap.exists, let p = try? snap.data(as: FSProfileAC.self) {
                userName = p.name; shareCode = p.shareCode; onboarded = !p.name.isEmpty
            } else {
                let code = HabitStore.makeCode()
                try ref.setData(from: FSProfileAC(name: "", shareCode: code))
                shareCode = code; userName = ""; onboarded = false
            }
        } catch { print("loadProfile:", error) }
    }

    func reload() async {
        guard let me = userID else { return }
        do {
            var mine = try await db.collection("habits").whereField("userId", isEqualTo: me)
                .getDocuments().documents.compactMap { try? $0.data(as: FSHabit.self) }
            mine.sort { ($0.createdAt?.dateValue() ?? .distantPast) < ($1.createdAt?.dateValue() ?? .distantPast) }
            habits = mine.map(Self.toHabit)

            let follows = try await db.collection("follows").whereField("followerId", isEqualTo: me)
                .getDocuments().documents.compactMap { try? $0.data(as: FSFollow.self) }
            let followeeIDs = follows.map { $0.followeeId }.filter { !$0.isEmpty }

            var newFriends: [Friend] = []
            var map: [UUID: String] = [:]
            for fid in followeeIDs {
                let prof = try? await db.collection("ac_profiles").document(fid).getDocument().data(as: FSProfileAC.self)
                let theirs = try await db.collection("habits").whereField("userId", isEqualTo: fid)
                    .getDocuments().documents.compactMap { try? $0.data(as: FSHabit.self) }.map(Self.toHabit)
                let top = theirs.max(by: { $0.streak < $1.streak })
                let name = (prof?.name.isEmpty == false ? prof!.name : "Friend")

                var sos: String? = nil
                var sosName: String? = nil
                var sosDate: Date? = nil
                if let at = prof?.sosAt?.dateValue(), Date().timeIntervalSince(at) < 24 * 3600 {
                    let h = prof?.sosHabit ?? "a habit"
                    let n = (prof?.sosNote ?? "").trimmingCharacters(in: .whitespaces)
                    sos = n.isEmpty ? "craving \(h)" : "craving \(h): \(n)"
                    sosName = prof?.sosHabit
                    sosDate = at

                    let key = "\(fid)_\(Int(at.timeIntervalSince1970))"
                    if didFirstFriendLoad, !seenSOS.contains(key) {
                        Notifier.fire(title: "🆘 \(name) needs a hand", body: sos ?? "craving help")
                    }
                    seenSOS.insert(key)
                }

                var broke: String? = nil
                var brokeDate: Date? = nil
                if let at = prof?.brokeAt?.dateValue(), Date().timeIntervalSince(at) < 24 * 3600 {
                    let h = prof?.brokeHabit ?? "a habit"
                    let isQuit = (prof?.brokeMode ?? "quit") == "quit"
                    broke = isQuit ? "went back to \(h)" : "broke their \(h) streak"
                    brokeDate = at

                    let key = "broke_\(fid)_\(Int(at.timeIntervalSince1970))"
                    if didFirstFriendLoad, !seenSOS.contains(key) {
                        Notifier.fire(title: "\(name) \(isQuit ? "relapsed" : "broke a streak")",
                                      body: broke ?? "")
                    }
                    seenSOS.insert(key)
                }


                let id = stableID(fid)
                map[id] = fid
                newFriends.append(Friend(id: id, name: name, shareCode: prof?.shareCode ?? "",
                                         topHabit: top?.name ?? "Habit", streak: top?.streak ?? 0,
                                         sos: sos, sosHabitName: sosName, sosAt: sosDate,
                                         broke: broke, brokeAt: brokeDate))
            }
            friends = newFriends
            friendUID = map
            didFirstFriendLoad = true
            subscribeFriendProfiles(followeeIDs)
            recomputeBadge()
            refreshWidget()
        } catch { print("HabitStore.reload:", error) }
    }

    private static func toHabit(_ d: FSHabit) -> Habit {
        let started = (d.startedAt ?? d.createdAt)?.dateValue() ?? Date()
        let mode = HabitMode(rawValue: d.mode ?? "build") ?? .build
        return Habit(id: fsUUID(d.id), name: d.name, emoji: d.emoji, colorHex: d.colorHex, mode: mode, startedAt: started)
    }

    private func subscribe() {
        guard let me = userID else { return }
        listeners.append(db.collection("habits").whereField("userId", isEqualTo: me)
            .addSnapshotListener { [weak self] _, _ in Task { await self?.reload() } })
        listeners.append(db.collection("follows").whereField("followerId", isEqualTo: me)
            .addSnapshotListener { [weak self] _, _ in Task { await self?.reload() } })
    }

    // Watch friends' profiles so their SOS/craving fires live (skip each listener's first echo).
    private func subscribeFriendProfiles(_ ids: [String]) {
        guard Set(ids) != watchedProfileIDs else { return }
        watchedProfileIDs = Set(ids)
        profileListeners.forEach { $0.remove() }
        profileListeners = ids.map { fid in
            var first = true
            return db.collection("ac_profiles").document(fid).addSnapshotListener { [weak self] _, _ in
                if first { first = false; return }
                Task { await self?.reload() }
            }
        }
    }

    // MARK: - Habits

    func addHabit(_ name: String, emoji: String, colorHex: String, mode: HabitMode) {
        guard let me = userID else { return }
        let h = Habit(name: name, emoji: emoji, colorHex: colorHex, mode: mode)
        habits.insert(h, at: 0)
        refreshWidget()
        let ref = db.collection("habits").document(h.id.uuidString)
        Task {
            do {
                try await ref.setData([
                    "userId": me, "name": name, "emoji": emoji, "colorHex": colorHex,
                    "mode": mode.rawValue,
                    "startedAt": FieldValue.serverTimestamp(),
                    "createdAt": FieldValue.serverTimestamp(),
                ])
                await reload()
            } catch { print("addHabit:", error) }
        }
    }

    func reset(_ habit: Habit) {
        guard let i = habits.firstIndex(where: { $0.id == habit.id }) else { return }
        habits[i].startedAt = Date()
        refreshWidget()
        let id = habit.id
        let hname = habit.name, hmode = habit.mode.rawValue
        Task {
            try? await db.collection("habits").document(id.uuidString)
                .updateData(["startedAt": FieldValue.serverTimestamp()])
            // Tell your friends you broke it (accountability).
            if let me = userID {
                try? await db.collection("ac_profiles").document(me).updateData([
                    "brokeHabit": hname, "brokeMode": hmode, "brokeAt": FieldValue.serverTimestamp(),
                ])
            }
            await reload()
        }
    }

    func delete(_ habit: Habit) {
        habits.removeAll { $0.id == habit.id }
        refreshWidget()
        let id = habit.id
        Task { try? await db.collection("habits").document(id.uuidString).delete() }
    }

    // MARK: - Craving SOS (rides on your profile → friends see it, no extra rules)

    func sendSOS(for habit: Habit, note: String) {
        guard let me = userID else { return }
        Task {
            try? await db.collection("ac_profiles").document(me).updateData([
                "sosHabit": habit.name,
                "sosNote": note.trimmingCharacters(in: .whitespaces),
                "sosAt": FieldValue.serverTimestamp(),
            ])
            await reload()
        }
    }

    // MARK: - Onboarding / friends

    func finishOnboarding(name: String) {
        userName = name; onboarded = true
        guard let me = userID else { return }
        Task { try? await db.collection("ac_profiles").document(me).updateData(["name": name]) }
    }

    func addFriend(code: String) {
        let clean = code.uppercased().trimmingCharacters(in: .whitespaces)
        guard clean.count >= 4, let me = userID else { return }
        Task {
            do {
                let q = try await db.collection("ac_profiles").whereField("shareCode", isEqualTo: clean).getDocuments()
                guard let target = q.documents.first else { return }
                let followeeUid = target.documentID
                guard followeeUid != me else { return }   // can't follow yourself
                try db.collection("follows").document("\(me)_\(followeeUid)")
                    .setData(from: FSFollow(followerId: me, followeeId: followeeUid))
                await reload()
            } catch { print("addFriend:", error) }
        }
    }

    func removeFriend(_ f: Friend) {
        friends.removeAll { $0.id == f.id }
        guard let me = userID, let followeeUid = friendUID[f.id] else { return }
        Task {
            try? await db.collection("follows").document("\(me)_\(followeeUid)").delete()
            await reload()
        }
    }

    // Their full habit list, for the friend detail screen.
    func friendHabits(_ f: Friend) async -> [Habit] {
        #if DEBUG
        if let demo = demoFriendHabits[f.id] { return demo }
        #endif
        guard let uid = friendUID[f.id] else { return [] }
        let docs = try? await db.collection("habits").whereField("userId", isEqualTo: uid).getDocuments()
        return (docs?.documents.compactMap { try? $0.data(as: FSHabit.self) }.map(Self.toHabit) ?? [])
            .sorted { $0.streak > $1.streak }
    }

    // MARK: - Craving badge (unseen friend cravings → app-icon + Friends-tab badge)

    private func cravingKey(_ uid: String, _ at: Date) -> String { "\(uid)_\(Int(at.timeIntervalSince1970))" }

    // Count active cravings you haven't opened yet, and light up the badges.
    private func recomputeBadge() {
        let unseen = friends.reduce(0) { acc, f in
            guard let at = f.sosAt, let uid = friendUID[f.id] else { return acc }
            return acc + (seenCravings.contains(cravingKey(uid, at)) ? 0 : 1)
        }
        unseenCravings = unseen
        Notifier.setBadge(unseen)
    }

    // Call when you open a friend's craving so it stops nagging you.
    func markCravingSeen(_ friend: Friend) {
        guard let at = friend.sosAt, let uid = friendUID[friend.id] else { return }
        let key = cravingKey(uid, at)
        guard !seenCravings.contains(key) else { return }
        seenCravings.insert(key)
        UserDefaults.standard.set(Array(seenCravings), forKey: "qw_seen_cravings")
        recomputeBadge()
    }

    // MARK: widget bridge
    func refreshWidget() {
        guard onboarded, !habits.isEmpty else { return }
        var snap = WidgetSnapshot()
        snap.myName = userName.isEmpty ? "You" : userName
        snap.habits = habits.map { WidgetHabit(name: $0.name, emoji: $0.emoji, colorHex: $0.colorHex, startedAt: $0.startedAt, mode: $0.mode.rawValue, streak: $0.streak) }
        snap.friends = friends.map { WidgetFriend(name: $0.name, streak: $0.streak, sos: $0.sos, broke: $0.broke) }
        ACSnapshotIO.write(snap)
        WidgetCenter.shared.reloadAllTimelines()
    }

    static func makeCode() -> String {
        let a = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        return String((0..<6).map { _ in a.randomElement()! })
    }
}
