import SwiftUI

/// Step 2: 生活模式选择
struct LifeModeSelectView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("选择你的生活方式")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(AppColors.textPrimary)

            Text("这将决定你和狗狗的日常节奏")
                .font(.system(size: 14))
                .foregroundStyle(AppColors.textSecondary)

            VStack(spacing: 16) {
                ForEach(LifeMode.allCases, id: \.self) { mode in
                    LifeModeCard(
                        mode: mode,
                        isSelected: viewModel.selectedLifeMode == mode
                    )
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3)) {
                            viewModel.selectedLifeMode = mode
                        }
                    }
                }
            }
            .padding(.horizontal, 24)

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
                    .background(viewModel.selectedLifeMode != nil
                                ? AppColors.primaryBrown
                                : AppColors.lightGray)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(viewModel.selectedLifeMode == nil)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 48)
    }
}

// MARK: - 生活模式卡片

private struct LifeModeCard: View {
    let mode: LifeMode
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 16) {
            Text(mode.emoji)
                .font(.system(size: 36))

            VStack(alignment: .leading, spacing: 4) {
                Text(mode.displayName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppColors.textPrimary)

                Text(mode.description)
                    .font(.system(size: 13))
                    .foregroundStyle(AppColors.textSecondary)
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(AppColors.primaryBrown)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? AppColors.primaryBrown.opacity(0.1) : .white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? AppColors.primaryBrown : AppColors.lightGray, lineWidth: 2)
        )
    }
}
