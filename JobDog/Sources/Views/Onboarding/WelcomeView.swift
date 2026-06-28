import SwiftUI

/// Step 1: 欢迎页
struct WelcomeView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Logo
            VStack(spacing: 12) {
                Text("🐕")
                    .font(.system(size: 80))

                Text("Job Dog")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.primaryBrown)

                Text("你的狗狗陪你一起生活")
                    .font(.system(size: 16))
                    .foregroundStyle(AppColors.textSecondary)
            }

            Spacer()

            // 开始按钮
            Button {
                viewModel.nextStep()
            } label: {
                Text("开始新生活")
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
    }
}
