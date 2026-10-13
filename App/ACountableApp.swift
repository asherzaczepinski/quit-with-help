import SwiftUI
import FirebaseCore

@main
struct ACountableApp: App {
    @StateObject private var store = HabitStore()
    @StateObject private var auth = AuthModel()

    init() {
        FirebaseApp.configure()
        Notifier.setup()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(auth)
                .preferredColorScheme(.light)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var store: HabitStore
    @EnvironmentObject var auth: AuthModel
    var body: some View {
        #if DEBUG
        if let screen = DemoScreen.current {
            DemoRoot(screen: screen)
        } else {
            real
        }
        #else
        real
        #endif
    }

    private var real: some View {
        Group {
            if auth.isLoading || (auth.isSignedIn && !store.ready) {
                ZStack { QWBackground(); ProgressView().tint(QW.accent) }
            } else if !auth.isSignedIn {
                AuthView()
            } else if store.onboarded {
                MainTabs()
            } else {
                OnboardingView()
            }
        }
        .task(id: auth.userID) {
            if let uid = auth.userID { await store.start(userID: uid, email: auth.email) }
        }
    }
}

struct MainTabs: View {
    @EnvironmentObject var store: HabitStore
    var body: some View {
        TabView {
            HomeView().tabItem { Label("Habits", systemImage: "flame.fill") }
            FriendsView().tabItem { Label("Friends", systemImage: "person.2.fill") }
                .badge(store.unseenCravings)
            WidgetGuideView().tabItem { Label("Widget", systemImage: "square.grid.2x2.fill") }
            MeView().tabItem { Label("Me", systemImage: "person.crop.circle.fill") }
        }
        .tint(QW.accent)
        .task { Notifier.enable() }
    }
}
