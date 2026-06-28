import SwiftUI

struct RootView: View {
    @Environment(GameStore.self) private var store
    @State private var selectedTab: AppTab = .life

    enum AppTab: Int, CaseIterable {
        case life = 0
        case dog = 1
        case settings = 2

        var title: String {
            switch self {
            case .life: return "生活"
            case .dog: return "我的狗"
            case .settings: return "设置"
            }
        }

        var icon: String {
            switch self {
            case .life: return "house.fill"
            case .dog: return "pawprint.fill"
            case .settings: return "gearshape.fill"
            }
        }
    }

    var body: some View {
        if store.isOnboarding {
            OnboardingContainerView()
                .environment(store)
        } else {
            TabView(selection: $selectedTab) {
                LifeTabView()
                    .environment(store)
                    .tabItem {
                        Label(AppTab.life.title, systemImage: AppTab.life.icon)
                    }
                    .tag(AppTab.life)

                DogProfileView()
                    .environment(store)
                    .tabItem {
                        Label(AppTab.dog.title, systemImage: AppTab.dog.icon)
                    }
                    .tag(AppTab.dog)

                SettingsView()
                    .environment(store)
                    .tabItem {
                        Label(AppTab.settings.title, systemImage: AppTab.settings.icon)
                    }
                    .tag(AppTab.settings)
            }
            .tint(AppColors.primaryBrown)
        }
    }
}
