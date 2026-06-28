import SwiftUI

/// 我的狗 Tab - 狗狗档案
struct DogProfileView: View {
    @Environment(GameStore.self) private var store

    var body: some View {
        ScrollView {
            if let dog = store.saveData?.dog {
                VStack(spacing: 24) {
                    // 狗狗大图
                    dogPortrait(dog)

                    // 基本信息
                    basicInfo(dog)

                    // 属性详情
                    attributesDetail(dog)

                    // 履历
                   履历(dog)
                }
                .padding(.vertical, 24)
            } else {
                ProgressView("加载中...")
            }
        }
        .background(AppColors.creamBackground)
    }

    // MARK: - 狗狗肖像

    private func dogPortrait(_ dog: Dog) -> some View {
        VStack(spacing: 12) {
            Text(dog.breed.emoji)
                .font(.system(size: 100))

            Text(dog.name)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(AppColors.textPrimary)

            Text(dog.attributes.statusDescription)
                .font(.system(size: 16))
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white)
                .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        )
        .padding(.horizontal, 16)
    }

    // MARK: - 基本信息

    private func basicInfo(_ dog: Dog) -> some View {
        VStack(spacing: 12) {
            InfoRow(title: "品种", value: dog.breed.displayName)
            InfoRow(title: "性别", value: dog.gender == .boy ? "♂️ 公" : "♀️ 母")
            InfoRow(title: "生活方式", value: dog.lifeMode.displayName)
            InfoRow(title: "技能等级", value: "Lv.\(dog.skillLevel)")
            InfoRow(title: "连续出勤", value: "\(dog.consecutiveAttendance) 天")
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.white)
        )
        .padding(.horizontal, 16)
    }

    // MARK: - 属性详情

    private func attributesDetail(_ dog: Dog) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("属性详情")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary)

            AttributeDetailRow(title: "心情", value: dog.attributes.mood, color: AppColors.moodPink, emoji: "😊")
            AttributeDetailRow(title: "活力", value: dog.attributes.energy, color: AppColors.energyGreen, emoji: "⚡️")
            AttributeDetailRow(title: "饱腹", value: dog.attributes.fullness, color: AppColors.fullnessOrange, emoji: "🍖")
            AttributeDetailRow(title: "清洁", value: dog.attributes.cleanliness, color: AppColors.cleanlinessBlue, emoji: "✨")
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.white)
        )
        .padding(.horizontal, 16)
    }

    // MARK: - 履历

    private func 履历(_ dog: Dog) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("履历")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary)

            if let adoptionDate = store.saveData?.settings.onboardingCompletedAt {
                let days = Calendar.current.dateComponents([.day], from: adoptionDate, to: Date()).day ?? 0
                InfoRow(title: "陪伴天数", value: "\(days) 天")
            }

            InfoRow(title: "当前状态", value: dog.attributes.statusDescription)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.white)
        )
        .padding(.horizontal, 16)
    }
}

// MARK: - 信息行

private struct InfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 14))
                .foregroundStyle(AppColors.textSecondary)

            Spacer()

            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppColors.textPrimary)
        }
    }
}

// MARK: - 属性详情行

private struct AttributeDetailRow: View {
    let title: String
    let value: Int
    let color: Color
    let emoji: String

    var body: some View {
        HStack(spacing: 12) {
            Text(emoji)
                .font(.system(size: 20))

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppColors.textPrimary)

                    Spacer()

                    Text("\(value)/100")
                        .font(.system(size: 12))
                        .foregroundStyle(AppColors.textSecondary)
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(color.opacity(0.2))

                        Capsule()
                            .fill(color)
                            .frame(width: geometry.size.width * CGFloat(value) / 100)
                    }
                }
                .frame(height: 8)
            }
        }
    }
}
