#if DEBUG
import SwiftUI

// Screenshot mode: launch with QW_DEMO=<screen> to show a screen filled with sample data,
// no sign-in or Firestore needed. Debug builds only.
enum DemoScreen: String {
    case auth, onboarding, habits, addQuit, addBuild, detail, reset, sos,
         friends, friend, friendCraving, widget, me

    static var current: DemoScreen? {
        ProcessInfo.processInfo.environment["QW_DEMO"].flatMap(DemoScreen.init(rawValue:))
    }
}

private enum Sample {
    static func ago(days: Double, hours: Double = 0) -> Date {
        Date().addingTimeInterval(-(days * 86400 + hours * 3600))
    }

    static let habits = [
        Habit(name: "Quit YouTube", mode: .quit, startedAt: ago(days: 12, hours: 5)),
        Habit(name: "Workout each day", mode: .build, startedAt: ago(days: 6, hours: 3)),
        Habit(name: "Quit soda", mode: .quit, startedAt: ago(days: 41, hours: 2)),
        Habit(name: "Read 20 minutes", mode: .build, startedAt: ago(days: 2, hours: 7)),
    ]

    static let jordan = Friend(name: "Jordan", shareCode: "JRD4KX", topHabit: "Run each morning", streak: 15,
                               sos: "craving Quit TikTok: just got home, really want to scroll",
                               sosHabitName: "Quit TikTok", sosAt: Date().addingTimeInterval(-6 * 60))
    static let maya = Friend(name: "Maya", shareCode: "MAYA22", topHabit: "Quit Instagram", streak: 23)
    static let sam = Friend(name: "Sam", shareCode: "SAM9PQ", topHabit: "Workout each day", streak: 9)

    static let jordanHabits = [
        Habit(name: "Run each morning", mode: .build, startedAt: ago(days: 15, hours: 4)),
        Habit(name: "Quit TikTok", mode: .quit, startedAt: ago(days: 8, hours: 11)),
    ]

    @MainActor static func fill(_ store: HabitStore) {
        store.userName = "Alex"
        store.shareCode = "K7Q2M9"
        store.onboarded = true
        store.habits = habits
        store.friends = [jordan, maya, sam]
        store.demoFriendHabits = [
            jordan.id: jordanHabits,
            maya.id: [Habit(name: "Quit Instagram", mode: .quit, startedAt: ago(days: 23, hours: 6))],
            sam.id: [Habit(name: "Workout each day", mode: .build, startedAt: ago(days: 9, hours: 1))],
        ]
        store.unseenCravings = 1
    }
}

struct DemoRoot: View {
    @EnvironmentObject var store: HabitStore
    let screen: DemoScreen
    @State private var filled = false

    var body: some View {
        Group {
            if filled { content } else { QWBackground() }
        }
        .onAppear { Sample.fill(store); filled = true }
    }

    @ViewBuilder private var content: some View {
        switch screen {
        case .auth: AuthView()
        case .onboarding: OnboardingView()
        case .habits: DemoTabs(tab: 0) { HomeView() }
        case .addQuit: DemoTabs(tab: 0) { HomeView() }.sheet(isPresented: .constant(true)) { AddHabitView(mode: .quit) }
        case .addBuild: DemoTabs(tab: 0) { HomeView() }.sheet(isPresented: .constant(true)) { AddHabitView(mode: .build) }
        case .detail: DemoTabs(tab: 0) { NavigationStack { HabitDetailView(habit: Sample.habits[0]) } }
        case .reset: DemoTabs(tab: 0) { NavigationStack { HabitDetailView(habit: Sample.habits[0], confirmReset: true) } }
        case .sos: DemoTabs(tab: 0) { NavigationStack { HabitDetailView(habit: Sample.habits[0], showSOS: true) } }
        case .friends: DemoTabs(tab: 1) { EmptyView() }
        case .friend: DemoTabs(tab: 1) { NavigationStack { FriendDetailView(friend: Sample.jordan) } }
        case .friendCraving: DemoTabs(tab: 1) { NavigationStack { FriendStreakView(friend: Sample.jordan, habit: Sample.jordanHabits[1]) } }
        case .widget: DemoTabs(tab: 2) { EmptyView() }
        case .me: DemoTabs(tab: 3) { EmptyView() }
        }
    }
}

// Same tabs as MainTabs, with the selected tab's content swappable (for pushed screens).
private struct DemoTabs<Content: View>: View {
    @EnvironmentObject var store: HabitStore
    @State var tab: Int
    let custom: Content

    init(tab: Int, @ViewBuilder custom: () -> Content) {
        _tab = State(initialValue: tab)
        self.custom = custom()
    }

    private var hasCustom: Bool { !(Content.self == EmptyView.self) }

    var body: some View {
        TabView(selection: $tab) {
            Group { if tab == 0 && hasCustom { custom } else { HomeView() } }
                .tabItem { Label("Habits", systemImage: "flame.fill") }.tag(0)
            Group { if tab == 1 && hasCustom { custom } else { FriendsView() } }
                .tabItem { Label("Friends", systemImage: "person.2.fill") }.tag(1)
                .badge(store.unseenCravings)
            WidgetGuideView().tabItem { Label("Widget", systemImage: "square.grid.2x2.fill") }.tag(2)
            MeView().tabItem { Label("Me", systemImage: "person.crop.circle.fill") }.tag(3)
        }
        .tint(QW.accent)
    }
}
#endif
