import Foundation
import Observation

// MARK: - 生活 Tab ViewModel

@Observable
class LifeTabViewModel {
    var isFocusedOnDog: Bool = false

    /// 切换镜头聚焦状态
    func toggleFocus() {
        isFocusedOnDog.toggle()
    }

    /// 执行场景互动
    func interact(with prop: InteractiveProp, in store: GameStore) {
        store.interact(with: prop)
    }

    /// 手动刷新场景
    func refreshScene(in store: GameStore) {
        store.updateScene()
    }
}
