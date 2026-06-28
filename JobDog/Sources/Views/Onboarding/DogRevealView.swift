import SwiftUI

/// Step 4: 犬种揭示
struct DogRevealView: View {
    @Bindable var viewModel: OnboardingViewModel
    @State private var isRevealed = false
    @State private var showNameInput = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            if !isRevealed {
                // 揭示前
                VStack(spacing: 24) {
                    Text("🥚")
                        .font(.system(size: 80))
                        .scaleEffect(isRevealed ? 1.2 : 1.0)

                    Text("一只神秘的狗狗即将出现...")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(AppColors.textPrimary)

                    Button {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                            isRevealed = true
                        }
                    } label: {
                        Text("打开蛋")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 200, height: 52)
                            .background(AppColors.primaryBrown)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            } else {
                // 揭示后
                VStack(spacing: 16) {
                    if let breed = viewModel.generatedBreed {
                        Text(breed.emoji)
                            .font(.system(size: 80))

                        Text("一只 \(breed.displayName) 出现了！")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(AppColors.textPrimary)

                        Text(breed.description)
                            .font(.system(size: 14))
                            .foregroundStyle(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)

                        Button {
                            withAnimation {
                                viewModel.rerollBreed()
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.clockwise")
                                Text("换一只")
                            }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(AppColors.primaryBrown)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(AppColors.primaryBrown.opacity(0.1))
                            .clipShape(Capsule())
                        }
                    }

                    // 命名输入
                    if showNameInput {
                        VStack(spacing: 12) {
                            Text("给它取个名字吧")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(AppColors.textPrimary)

                            TextField("名字", text: $viewModel.dogName)
                                .textFieldStyle(.plain)
                                .font(.system(size: 18))
                                .multilineTextAlignment(.center)
                                .frame(height: 44)
                                .frame(maxWidth: 200)
                                .background(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(AppColors.lightGray, lineWidth: 1)
                                )
                        }
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
            }

            Spacer()

            // 底部按钮
            if isRevealed {
                if !showNameInput {
                    Button {
                        withAnimation {
                            showNameInput = true
                        }
                    } label: {
                        Text("就是它了！")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(AppColors.primaryBrown)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 32)
                } else {
                    Button {
                        viewModel.nextStep()
                    } label: {
                        Text("领养它")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(viewModel.dogName.isEmpty
                                        ? AppColors.lightGray
                                        : AppColors.primaryBrown)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(viewModel.dogName.isEmpty)
                    .padding(.horizontal, 32)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.bottom, 48)
    }
}
