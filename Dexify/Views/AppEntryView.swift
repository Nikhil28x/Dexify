import SwiftUI

struct AppEntryView: View {
    @State private var selectedModule: SelectedModule = .none
    @State private var userName: String = ""
    @State private var hasEnteredName: Bool = false

    init() {
        if let savedModule = UserDefaults.standard.string(forKey: "lastModule") {
            switch savedModule {
            case "todo": _selectedModule = State(initialValue: .todo)
            case "gym": _selectedModule = State(initialValue: .gym)
            case "progressLog": _selectedModule = State(initialValue: .progressLog)
            case "notifications": _selectedModule = State(initialValue: .notifications)
            default: break
            }
        }

        if let savedName = UserDefaults.standard.string(forKey: "userName") {
            _userName = State(initialValue: savedName)
            _hasEnteredName = State(initialValue: true)
        }
    }

    var body: some View {
        Group {
            switch selectedModule {
            case .todo:
                ChecklistView(selectedModule: $selectedModule)

            case .gym:
                GymTrackerView(selectedModule: $selectedModule)

            case .progressLog:
                ProgressLogView(selectedModule: $selectedModule)

            case .editGoals:
                GoalInputView(
                    showTracker: .constant(false),
                    carbGoal: .constant(UserDefaults.standard.double(forKey: "carbGoal")),
                    proteinGoal: .constant(UserDefaults.standard.double(forKey: "proteinGoal")),
                    fatGoal: .constant(UserDefaults.standard.double(forKey: "fatGoal")),
                    waterGoal: .constant(UserDefaults.standard.double(forKey: "waterGoal")),
                    selectedModule: $selectedModule
                )

            case .notifications:
                NotificationsView(selectedModule: $selectedModule)

            case .none:
                if hasEnteredName {
                    ModuleSelectionView(userName: userName) { selected in
                        self.selectedModule = selected

                        let moduleString: String = {
                            switch selected {
                            case .todo: return "todo"
                            case .gym: return "gym"
                            case .progressLog: return "progressLog"
                            case .notifications: return "notifications"
                            default: return ""
                            }
                        }()

                        if !moduleString.isEmpty {
                            UserDefaults.standard.set(moduleString, forKey: "lastModule")
                        }
                    }
                } else {
                    LaunchScreenView { name in
                        self.userName = name
                        self.hasEnteredName = true
                        UserDefaults.standard.set(name, forKey: "userName")
                    }
                }
            }
        }
        .onAppear {
            NotificationManager.shared.requestPermission()
        }
    }
}

