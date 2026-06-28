import SwiftUI

/// Step 5: 领养仪式
struct AdoptionCeremonyView: View {
    @Bindable var viewModel: OnboardingViewModel
    let store: GameStore
    @State private var showConfetti = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // 庆祝动画
            if showConfetti {
                Text("🎉🎊🎉")
                    .font(.system(size: 48))
                    .transition(.scale.combined(with: .opacity))
            }

            // 狗狗展示
            VStack(spacing: 12) {
                if let breed = viewModel.generatedBreed {
                    Text(breed.emoji)
                        .font(.system(size: 72))
                }

                Text("\(viewModel.dogName) 正式成为你的伙伴！")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)
                    .multilineTextAlignment(.center)
            }

            // 信息卡片
            VStack(spacing: 8) {
                InfoRow(label: "品种", value: viewModel.generatedBreed?.displayName ?? "")
                InfoRow(label: "性别", value: viewModel.selectedGender == .boy ? "♂️ 公" : "♀️ 母")
                InfoRow(label: "生活方式", value: viewModel.selectedLifeMode?.displayName ?? "")
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.white)
            )
            .padding(.horizontal, 32)

            // 提示
            Text("记得按时照顾它哦，它会陪你度过每一天")
                .font(.system(size: 14))
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()

            // 完成按钮
            Button {
                viewModel.completeOnboarding(in: store)
            } label: {
                Text("开始新生活 🐾")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(AppColors.primaryBrown)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            withAnimation(.spring(response: 0.5).delay(0.3)) {
                showConfetti = true
            }
        }
    }
}

// MARK: - 信息行

private struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundStyle(AppColors.textSecondary)

            Spacer()

            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppColors.textPrimary)
        }
    }
}
