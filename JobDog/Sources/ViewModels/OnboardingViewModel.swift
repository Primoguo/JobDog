import Foundation
import Observation

// MARK: - Onboarding 流程步骤

enum OnboardingStep: Int, CaseIterable {
    case welcome = 0
    case lifeMode
    case gender
    case dogReveal
    case adoptionCeremony
}

// MARK: - Onboarding ViewModel

@Observable
class OnboardingViewModel {
    var currentStep: OnboardingStep = .welcome
    var selectedLifeMode: LifeMode?
    var selectedGender: Gender?
    var generatedBreed: Breed?
    var dogName: String = ""

    /// 进入下一步
    func nextStep() {
        guard let nextRaw = Optional(currentStep.rawValue + 1),
              let next = OnboardingStep(rawValue: nextRaw) else { return }
        currentStep = next

        // 进入犬种揭示时随机生成
        if currentStep == .dogReveal {
            generatedBreed = Breed.allCases.randomElement()
        }
    }

    /// 回到上一步
    func previousStep() {
        guard let prev = OnboardingStep(rawValue: currentStep.rawValue - 1) else { return }
        currentStep = prev
    }

    /// 完成 onboarding，创建狗狗
    func completeOnboarding(in store: GameStore) {
        guard let mode = selectedLifeMode,
              let gender = selectedGender,
              let breed = generatedBreed,
              !dogName.isEmpty else { return }

        let dog = Dog(
            name: dogName,
            breed: breed,
            gender: gender,
            lifeMode: mode
        )

        store.completeOnboarding(dog: dog)
    }

    /// 重新随机犬种
    func rerollBreed() {
        var newBreed = Breed.allCases.randomElement()
        while newBreed == generatedBreed {
            newBreed = Breed.allCases.randomElement()
        }
        generatedBreed = newBreed
    }
}
