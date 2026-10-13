import WidgetKit
import SwiftUI
import AppIntents

// ── Editable config: long-press the widget → Edit Widget → pick a habit ──
struct HabitEntity: AppEntity {
    let id: String
    let name: String
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Habit"
    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: "\(name)") }
    static var defaultQuery = HabitEntityQuery()
}

struct HabitEntityQuery: EntityQuery {
    func entities(for identifiers: [HabitEntity.ID]) async throws -> [HabitEntity] {
        allHabits().filter { identifiers.contains($0.id) }
    }
    func suggestedEntities() async throws -> [HabitEntity] { allHabits() }
    private func allHabits() -> [HabitEntity] {
        ACSnapshotIO.read().habits.map { HabitEntity(id: $0.name, name: $0.name) }
    }
}

struct QWConfig: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Quit With Help"
    static var description = IntentDescription("Pick a habit to feature, or leave blank for your top streak.")
    @Parameter(title: "Habit (blank = top streak)") var habit: HabitEntity?
}

// ── Timeline ──
struct QWEntry: TimelineEntry { let date: Date; let snap: WidgetSnapshot; let pick: String? }

private let sampleSnap: WidgetSnapshot = {
    var s = WidgetSnapshot(); s.myName = "You"
    s.habits = [
        WidgetHabit(name: "Quit YouTube", emoji: "", colorHex: "2F80ED", startedAt: Date().addingTimeInterval(-12 * 86400), mode: "quit", streak: 12),
        WidgetHabit(name: "Run", emoji: "", colorHex: "2F80ED", startedAt: Date().addingTimeInterval(-5 * 86400), mode: "build", streak: 5),
    ]
    s.friends = [WidgetFriend(name: "Maya", streak: 8, sos: "craving a smoke")]
    return s
}()

struct QWProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> QWEntry { QWEntry(date: Date(), snap: sampleSnap, pick: nil) }
    func snapshot(for configuration: QWConfig, in context: Context) async -> QWEntry {
        QWEntry(date: Date(), snap: context.isPreview ? sampleSnap : ACSnapshotIO.read(), pick: configuration.habit?.id)
    }
    func timeline(for configuration: QWConfig, in context: Context) async -> Timeline<QWEntry> {
        let entry = QWEntry(date: Date(), snap: ACSnapshotIO.read(), pick: configuration.habit?.id)
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date().addingTimeInterval(3600)
        return Timeline(entries: [entry], policy: .after(next))
    }
}

// ── Views ──
struct QWWidgetView: View {
    @Environment(\.widgetFamily) var family
    var entry: QWEntry
    private let amber = Color(hex: "2F80ED")
    private let danger = Color(hex: "EF5350")

    private var featured: WidgetHabit? {
        let hs = entry.snap.habits
        if let pick = entry.pick, let h = hs.first(where: { $0.name == pick }) { return h }
        return hs.max(by: { $0.streak < $1.streak })
    }

    var body: some View {
        switch family {
        case .systemLarge: large
        case .systemMedium: medium
        default: small
        }
    }

    private var small: some View {
        VStack(alignment: .leading, spacing: 3) {
            if let h = featured {
                Text(h.startedAt, style: .relative)
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(1).minimumScaleFactor(0.6)
                Text(h.name).font(.system(size: 12, weight: .semibold, design: .rounded)).lineLimit(1).foregroundStyle(.secondary)
            } else {
                Text("Add a habit").font(.system(size: 14, design: .rounded)).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
    }

    private var medium: some View {
        HStack(spacing: 16) {
            small.frame(maxWidth: .infinity, alignment: .leading)
            VStack(alignment: .leading, spacing: 7) {
                Text("Friends").font(.system(size: 11, weight: .bold, design: .rounded)).foregroundStyle(.secondary)
                if entry.snap.friends.isEmpty {
                    Text("none yet").font(.system(size: 12, design: .rounded)).foregroundStyle(.secondary)
                }
                ForEach(entry.snap.friends.prefix(3), id: \.self) { f in
                    HStack {
                        Text(f.name).font(.system(size: 12, weight: .semibold, design: .rounded)).lineLimit(1)
                        Spacer()
                        if f.sos != nil { Text("🆘").font(.system(size: 12)) }
                        else { Text("\(f.streak)").font(.system(size: 13, weight: .heavy, design: .rounded)).foregroundStyle(f.broke != nil ? danger : amber) }
                    }
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var large: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your streaks").font(.system(size: 12, weight: .bold, design: .rounded)).foregroundStyle(.secondary)
            ForEach(entry.snap.habits.prefix(3), id: \.self) { h in
                HStack {
                        Text(h.name).font(.system(size: 13, weight: .semibold, design: .rounded)).lineLimit(1)
                    Spacer()
                    Text(h.startedAt, style: .relative)
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundStyle(.primary).lineLimit(1)
                }
            }
            Divider().opacity(0.25).padding(.vertical, 2)
            Text("Friends").font(.system(size: 12, weight: .bold, design: .rounded)).foregroundStyle(.secondary)
            if entry.snap.friends.isEmpty {
                Text("no friends yet").font(.system(size: 12, design: .rounded)).foregroundStyle(.secondary)
            }
            ForEach(entry.snap.friends.prefix(4), id: \.self) { f in
                HStack {
                    Text(f.name).font(.system(size: 13, weight: .semibold, design: .rounded)).lineLimit(1)
                    Spacer()
                    if let sos = f.sos {
                        Text("🆘 \(sos)").font(.system(size: 11, design: .rounded)).foregroundStyle(danger).lineLimit(1)
                    } else if let broke = f.broke {
                        Text(broke).font(.system(size: 11, design: .rounded)).foregroundStyle(danger).lineLimit(1)
                    } else {
                        Text("\(f.streak)").font(.system(size: 15, weight: .heavy, design: .rounded)).foregroundStyle(amber)
                    }
                }
            }
            Spacer(minLength: 0)
        }
    }
}

struct QWWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "QWStreak", intent: QWConfig.self, provider: QWProvider()) { entry in
            QWWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Quit With Help")
        .description("Your streaks and friends. Long-press → Edit Widget to feature one habit.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

@main
struct ACountableWidgetBundle: WidgetBundle {
    var body: some Widget { QWWidget() }
}
