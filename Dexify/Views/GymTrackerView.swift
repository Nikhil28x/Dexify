import SwiftUI

struct GymTrackerView: View {
    @Binding var selectedModule: SelectedModule

    @State private var showTracker = false
    @State private var carbGoal: Double = UserDefaults.standard.double(forKey: "carbGoal")
    @State private var proteinGoal: Double = UserDefaults.standard.double(forKey: "proteinGoal")
    @State private var fatGoal: Double = UserDefaults.standard.double(forKey: "fatGoal")
    @State private var waterGoal: Double = UserDefaults.standard.double(forKey: "waterGoal")

    var body: some View {
        if showTracker {
            NutritionTrackerView(
                selectedModule: $selectedModule,
                showTracker: $showTracker,
                carbGoal: carbGoal,
                proteinGoal: proteinGoal,
                fatGoal: fatGoal,
                waterGoal: waterGoal
            )
        } else {
            GoalInputView(
                showTracker: $showTracker,
                carbGoal: $carbGoal,
                proteinGoal: $proteinGoal,
                fatGoal: $fatGoal,
                waterGoal: $waterGoal,
                selectedModule: $selectedModule
            )
        }
    }
}

