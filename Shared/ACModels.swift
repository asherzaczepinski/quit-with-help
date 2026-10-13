import Foundation

let kAppGroup = "group.com.quitwithhelp"

enum HabitMode: String, Codable, Hashable { case build, quit }

// Biggest sensible unit: seconds → minutes → hours → days.
func elapsedPrimary(_ start: Date, _ now: Date = Date()) -> (value: Int, unit: String) {
    let t = max(0, Int(now.timeIntervalSince(start)))
    let d = t / 86400; if d >= 1 { return (d, d == 1 ? "day" : "days") }
    let h = t / 3600;  if h >= 1 { return (h, h == 1 ? "hour" : "hours") }
    let m = t / 60;    if m >= 1 { return (m, m == 1 ? "min" : "mins") }
    return (t, t == 1 ? "second" : "seconds")
}

// Compact compound: "45s", "5m 12s", "3h 20m", "2d 5h", "5 days" (days only after 3).
func elapsedCompact(_ start: Date, _ now: Date = Date()) -> String {
    let t = max(0, Int(now.timeIntervalSince(start)))
    let s = t % 60, m = (t / 60) % 60, h = (t / 3600) % 24, d = t / 86400
    if d >= 3 { return "\(d) days" }
    if d >= 1 { return h > 0 ? "\(d)d \(h)h" : "\(d)d" }
    if h >= 1 { return m > 0 ? "\(h)h \(m)m" : "\(h)h" }
    if m >= 1 { return s > 0 ? "\(m)m \(s)s" : "\(m)m" }
    return "\(s)s"
}

struct Habit: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var emoji: String = ""
    var colorHex: String = "2F80ED"
    var mode: HabitMode = .quit
    var startedAt: Date = Date()
    var createdAt: Date = Date()

    var streak: Int {   // whole days (for friend lists / summaries)
        let cal = Calendar.current
        return max(0, cal.dateComponents([.day], from: cal.startOfDay(for: startedAt), to: cal.startOfDay(for: Date())).day ?? 0)
    }

    private var word: String { mode == .quit ? "free" : "streak" }
    func liveSubtitle(_ now: Date = Date()) -> String { "\(elapsedCompact(startedAt, now)) \(word)" }
    func primaryValue(_ now: Date = Date()) -> Int { elapsedPrimary(startedAt, now).value }
    func primaryUnit(_ now: Date = Date()) -> String { "\(elapsedPrimary(startedAt, now).unit) \(word)" }

    var resetTitle: String { mode == .quit ? "I relapsed — reset to 0" : "I slipped — reset to 0" }
}

struct Friend: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var shareCode: String
    var topHabit: String = "Habit"
    var streak: Int = 0
    var sos: String? = nil
    var sosHabitName: String? = nil   // which of their habits the craving is about
    var sosAt: Date? = nil
    var broke: String? = nil       // recent relapse / broken streak
    var brokeAt: Date? = nil
}

// ── Widget snapshot ──
struct WidgetHabit: Codable, Hashable {
    var name = ""; var emoji = ""; var colorHex = "2F80ED"
    var startedAt = Date(); var mode = "quit"; var streak = 0
}
struct WidgetFriend: Codable, Hashable {
    var name = ""; var streak = 0; var sos: String? = nil; var broke: String? = nil
}
struct WidgetSnapshot: Codable {
    var myName: String = "You"
    var habits: [WidgetHabit] = []
    var friends: [WidgetFriend] = []
}
