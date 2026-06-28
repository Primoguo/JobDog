import SwiftUI

/// 属性胶囊条
struct AttributeCapsule: View {
    let title: String
    let value: Int
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            // 数值
            Text("\(value)")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary)

            // 进度条
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // 背景
                    Capsule()
                        .fill(color.opacity(0.2))

                    // 进度
                    Capsule()
                        .fill(color)
                        .frame(width: geometry.size.width * CGFloat(value) / 100)
                }
            }
            .frame(height: 6)

            // 标题
            Text(title)
                .font(.system(size: 9))
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}
