import SwiftUI

@main
struct JobDogApp: App {
    @State private var store = GameStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .onAppear {
                    store.onAppLaunch()
                }
                .onOpenURL { _ in
                    // 处理深度链接（预留）
                }
        }
        #if os(iOS)
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                store.onForeground()
            case .background, .inactive:
                store.save()
            @unknown default:
                break
            }
        }
        #endif
    }

    #if os(iOS)
    @Environment(\.scenePhase) private var scenePhase
    #endif
}
