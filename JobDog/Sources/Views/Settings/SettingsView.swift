import SwiftUI

/// 设置 Tab
struct SettingsView: View {
    @Environment(GameStore.self) private var store
    @State private var showResetAlert = false

    var body: some View {
        List {
            // 通知设置
            Section("通知") {
                Toggle("每日提醒", isOn: .constant(true))
                Toggle("属性警告", isOn: .constant(true))
            }

            // 显示设置
            Section("显示") {
                Toggle("减少动画", isOn: .constant(false))
                Toggle("高对比度", isOn: .constant(false))
            }

            // 数据管理
            Section("数据管理") {
                Button("导出存档") {
                    // TODO: 导出功能
                }

                Button("导入存档") {
                    // TODO: 导入功能
                }

                Button("重置游戏", role: .destructive) {
                    showResetAlert = true
                }
            }

            // 关于
            Section("关于") {
                HStack {
                    Text("版本")
                    Spacer()
                    Text("1.0.0")
                        .foregroundStyle(AppColors.textSecondary)
                }

                Link("隐私政策", destination: URL(string: "https://example.com/privacy")!)
                Link("用户协议", destination: URL(string: "https://example.com/terms")!)
            }
        }
        .listStyle(.insetGrouped)
        .background(AppColors.creamBackground)
        .navigationTitle("设置")
        .alert("确认重置", isPresented: $showResetAlert) {
            Button("取消", role: .cancel) {}
            Button("重置", role: .destructive) {
                store.resetGame()
            }
        } message: {
            Text("这将删除所有游戏数据，无法恢复。确定要重置吗？")
        }
    }
}
