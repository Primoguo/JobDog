import SwiftUI

/// 快捷操作栏 - 商店/背包/加速
struct QuickActionBar: View {
    let variant: SceneVariant
    let goldCoins: Int
    let onInteract: (InteractiveProp) -> Void

    var body: some View {
        VStack(spacing: 12) {
            // 可交互道具
            if !variant.interactiveProps.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(variant.interactiveProps) { prop in
                            InteractionButton(
                                prop: prop,
                                canAfford: goldCoins >= prop.cost,
                                action: { onInteract(prop) }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }

            // 底部功能按钮
            HStack(spacing: 16) {
                ActionButton(icon: "cart.fill", title: "商店", color: AppColors.primaryBrown) {
                    // TODO: 打开商店
                }

                ActionButton(icon: "bag.fill", title: "背包", color: AppColors.accentYellow) {
                    // TODO: 打开背包
                }

                ActionButton(icon: "bolt.fill", title: "加速", color: AppColors.energyGreen) {
                    // TODO: 时间加速
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.white)
                .shadow(color: .black.opacity(0.05), radius: 4, y: -2)
        )
    }
}

// MARK: - 互动按钮

private struct InteractionButton: View {
    let prop: InteractiveProp
    let canAfford: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(prop.emoji)
                    .font(.system(size: 28))

                Text(prop.label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppColors.textPrimary)

                if prop.cost > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.system(size: 10))
                        Text("\(prop.cost)")
                            .font(.system(size: 10))
                    }
                    .foregroundStyle(canAfford ? AppColors.accentYellow : AppColors.textSecondary)
                }
            }
            .frame(width: 72, height: 80)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(canAfford ? AppColors.primaryBrown.opacity(0.1) : AppColors.lightGray)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(canAfford ? AppColors.primaryBrown : AppColors.lightGray, lineWidth: 1)
            )
        }
        .disabled(!canAfford && prop.cost > 0)
    }
}

// MARK: - 功能按钮

private struct ActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(color)

                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppColors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.1))
            )
        }
    }
}
