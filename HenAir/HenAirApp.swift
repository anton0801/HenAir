import SwiftUI

@main
struct HenAirApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var coopsVM = CoopsViewModel()
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var app

    var body: some Scene {
        WindowGroup {
            SplashView()
                .environmentObject(appState)
                .environmentObject(coopsVM)
        }
    }
}

// MARK: - Root View (Splash → Onboarding → Main)
struct RootView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Group {
            if !appState.hasCompletedOnboarding {
                OnboardingView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            } else {
                MainTabView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: appState.hasCompletedOnboarding)
        .preferredColorScheme(appState.colorScheme)
    }
}

// MARK: - Main Tab View
struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var coopsVM: CoopsViewModel
    @State private var selectedTab = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                DashboardView()
                    .tag(0)
                CoopsListView()
                    .tag(1)
                AlertsView()
                    .tag(2)
                TasksView()
                    .tag(3)
                ProfileView()
                    .tag(4)
            }

            // Custom Tab Bar
            CustomTabBar(selectedTab: $selectedTab, unreadAlerts: coopsVM.unreadAlertCount)
        }
        .ignoresSafeArea(.keyboard)
    }
}

// MARK: - Custom Tab Bar
struct CustomTabBar: View {
    @Binding var selectedTab: Int
    let unreadAlerts: Int

    let items: [(String, String, String)] = [
        ("house.fill", "house", "Dashboard"),
        ("square.grid.2x2.fill", "square.grid.2x2", "Coops"),
        ("bell.fill", "bell", "Alerts"),
        ("checkmark.circle.fill", "checkmark.circle", "Tasks"),
        ("person.fill", "person", "Profile")
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<items.count, id: \.self) { i in
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        selectedTab = i
                    }
                }) {
                    VStack(spacing: 4) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: selectedTab == i ? items[i].0 : items[i].1)
                                .font(.system(size: 22, weight: selectedTab == i ? .semibold : .regular))
                                .foregroundColor(selectedTab == i ? .accentGreen : .textInactive)
                                .scaleEffect(selectedTab == i ? 1.1 : 1.0)

                            // Badge for alerts
                            if i == 2 && unreadAlerts > 0 {
                                ZStack {
                                    Circle().fill(Color.statusDanger).frame(width: 16, height: 16)
                                    Text("\(min(unreadAlerts, 9))").font(.system(size: 9, weight: .bold)).foregroundColor(.white)
                                }
                                .offset(x: 8, y: -4)
                            }
                        }

                        Text(items[i].2)
                            .font(.system(size: 10, weight: selectedTab == i ? .semibold : .regular))
                            .foregroundColor(selectedTab == i ? .accentGreen : .textInactive)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
            }
        }
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(Color.white)
                .shadow(color: Color.accentGreen.opacity(0.12), radius: 16, y: -4)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}
