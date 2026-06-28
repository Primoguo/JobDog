import SwiftUI

/// Step 3: 性别选择
struct GenderSelectView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Text("选择狗狗的性别")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(AppColors.textPrimary)

            Text("性别会影响装扮风格")
                .font(.system(size: 14))
                .foregroundStyle(AppColors.textSecondary)

            HStack(spacing: 24) {
                GenderCard(
                    gender: .boy,
                    emoji: "♂️",
                    title: "男孩子",
                    description: "帅气活泼",
                    isSelected: viewModel.selectedGender == .boy
                )
                .onTapGesture {
                    withAnimation(.spring(response: 0.3)) {
                        viewModel.selectedGender = .boy
                    }
                }

                GenderCard(
                    gender: .girl,
                    emoji: "♀️",
                    title: "女孩子",
                    description: "可爱甜美",
                    isSelected: viewModel.selectedGender == .girl
                )
                .onTapGesture {
                    withAnimation(.spring(response: 0.3)) {
                        viewModel.selectedGender = .girl
                    }
                }
            }
            .padding(.horizontal, 32)

            Spacer()

            navigationButtons
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var navigationButtons: some View {
        HStack(spacing: 16) {
            Button {
                viewModel.previousStep()
            } label: {
                Text("返回")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(AppColors.textSecondary)
                    .frame(height: 48)
                    .frame(maxWidth: .infinity)
                    .background(AppColors.lightGray)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Button {
                viewModel.nextStep()
            } label: {
                Text("下一步")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(height: 48)
                    .frame(maxWidth: .infinity)
                    .background(viewModel.selectedGender != nil
                                ? AppColors.primaryBrown
                                : AppColors.lightGray)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(viewModel.selectedGender == nil)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 48)
    }
}

// MARK: - 性别卡片

private struct GenderCard: View {
    let gender: Gender
    let emoji: String
    let title: String
    let description: String
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 12) {
            Text(emoji)
                .font(.system(size: 48))

            Text(title)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary)

            Text(description)
                .font(.system(size: 13))
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isSelected ? AppColors.primaryBrown.opacity(0.1) : .white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? AppColors.primaryBrown : AppColors.lightGray, lineWidth: 2)
        )
    }
}
