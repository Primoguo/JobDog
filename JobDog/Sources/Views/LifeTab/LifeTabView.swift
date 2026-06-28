import SwiftUI

/// 生活 Tab 主视图
struct LifeTabView: View {
    @Environment(GameStore.self) private var store
    @State private var viewModel = LifeTabViewModel()

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // 状态栏
                if let dog = store.saveData?.dog,
                   let economy = store.saveData?.economy,
                   let sceneState = store.saveData?.sceneState {
                    StatusBarView(
                        attributes: dog.attributes,
                        goldCoins: economy.goldCoins,
                        weather: sceneState.currentWeather,
                        timeSlot: store.timeService.currentTimeSlot
                    )
                }

                Spacer().frame(height: 12)

                // 场景 Canvas
                if let variant = store.currentVariant,
                   let dog = store.saveData?.dog {
                    SceneCanvasView(
                        variant: variant,
                        dog: dog,
                        isFocused: viewModel.isFocusedOnDog
                    )
                    .frame(height: geometry.size.height * 0.5)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            viewModel.toggleFocus()
                        }
                    }
                } else {
                    // 加载占位
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppColors.lightGray)
                        .frame(height: geometry.size.height * 0.5)
                        .overlay {
                            ProgressView("加载中...")
                        }
                        .padding(.horizontal, 16)
                }

                Spacer().frame(height: 12)

                // 快捷操作栏
                if let variant = store.currentVariant,
                   let economy = store.saveData?.economy {
                    QuickActionBar(
                        variant: variant,
                        goldCoins: economy.goldCoins,
                        onInteract: { prop in
                            viewModel.interact(with: prop, in: store)
                        }
                    )
                }

                // 警告提示
                if !store.attributeWarnings.isEmpty {
                    warningBanner
                }
            }
            .padding(.vertical, 12)
            .background(AppColors.creamBackground)
        }
    }

    private var warningBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(AppColors.warningRed)

            Text(store.attributeWarnings.joined(separator: " · "))
                .font(.system(size: 12))
                .foregroundStyle(AppColors.textPrimary)
                .lineLimit(2)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(AppColors.warningRed.opacity(0.1))
        )
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}
