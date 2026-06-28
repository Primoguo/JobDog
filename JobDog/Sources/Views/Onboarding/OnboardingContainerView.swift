import SwiftUI

/// Onboarding 容器 - 管理步骤切换
struct OnboardingContainerView: View {
    @Environment(GameStore.self) private var store
    @State private var viewModel = OnboardingViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // 进度指示器
            progressBar

            // 步骤内容
            Group {
                switch viewModel.currentStep {
                case .welcome:
                    WelcomeView(viewModel: viewModel)
                case .lifeMode:
                    LifeModeSelectView(viewModel: viewModel)
                case .gender:
                    GenderSelectView(viewModel: viewModel)
                case .dogReveal:
                    DogRevealView(viewModel: viewModel)
                case .adoptionCeremony:
                    AdoptionCeremonyView(viewModel: viewModel, store: store)
                }
            }
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
        }
        .background(AppColors.creamBackground)
        .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
    }

    private var progressBar: some View {
        HStack(spacing: 8) {
            ForEach(OnboardingStep.allCases, id: \.rawValue) { step in
                RoundedRectangle(cornerRadius: 2)
                    .fill(step.rawValue <= viewModel.currentStep.rawValue
                          ? AppColors.primaryBrown
                          : AppColors.lightGray)
                    .frame(height: 4)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }
}
