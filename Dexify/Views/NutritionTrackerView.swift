import SwiftUI

struct NutritionTrackerView: View {
    @Binding var selectedModule: SelectedModule
    @Binding var showTracker: Bool

    let carbGoal: Double
    let proteinGoal: Double
    let fatGoal: Double
    let waterGoal: Double

    @State private var carbs: Double = UserDefaults.standard.double(forKey: "carbs")
    @State private var protein: Double = UserDefaults.standard.double(forKey: "protein")
    @State private var fat: Double = UserDefaults.standard.double(forKey: "fat")
    @State private var water: Double = UserDefaults.standard.double(forKey: "water")
    @State private var mealNote: String = UserDefaults.standard.string(forKey: "mealNote") ?? ""

    @State private var inputCarbs = ""
    @State private var inputProtein = ""
    @State private var inputFat = ""
    @State private var inputWater = ""
    @State private var showResetConfirm = false

    var calories: Double { (carbs * 4) + (protein * 4) + (fat * 9) }
    var calorieGoal: Double { (carbGoal * 4) + (proteinGoal * 4) + (fatGoal * 9) }
    var overallProgress: Double {
        guard carbGoal > 0, proteinGoal > 0, fatGoal > 0, waterGoal > 0 else { return 0 }
        let p = [carbs / carbGoal, protein / proteinGoal, fat / fatGoal, water / waterGoal]
        return min(1.0, p.reduce(0, +) / 4.0)
    }

    var body: some View {
        ZStack {
            DS.Gradients.pageBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                DexNavBar(
                    title: "Gym Tracker",
                    subtitle: "Daily Nutrition",
                    leadingAction: { selectedModule = .none },
                    trailingAction: { showResetConfirm = true },
                    trailingIcon: "arrow.counterclockwise"
                )

                ScrollView(showsIndicators: false) {
                    VStack(spacing: DS.Spacing.lg) {

                        // Overall progress card
                        DexCard(padding: DS.Spacing.lg) {
                            VStack(spacing: DS.Spacing.md) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Today's Progress")
                                            .font(.system(size: 13))
                                            .foregroundColor(DS.Colors.textSecondary)
                                        Text("\(Int(calories)) kcal")
                                            .font(.system(size: 28, weight: .black))
                                            .foregroundColor(DS.Colors.textPrimary)
                                        Text("of \(Int(calorieGoal)) kcal goal")
                                            .font(.system(size: 12))
                                            .foregroundColor(DS.Colors.textMuted)
                                    }
                                    Spacer()
                                    ZStack {
                                        Circle()
                                            .stroke(DS.Colors.border, lineWidth: 6)
                                            .frame(width: 70, height: 70)
                                        Circle()
                                            .trim(from: 0, to: overallProgress)
                                            .stroke(
                                                AngularGradient(
                                                    gradient: Gradient(colors: [DS.Colors.accent, DS.Colors.success]),
                                                    center: .center
                                                ),
                                                style: StrokeStyle(lineWidth: 6, lineCap: .round)
                                            )
                                            .frame(width: 70, height: 70)
                                            .rotationEffect(.degrees(-90))
                                        Text("\(Int(overallProgress * 100))%")
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundColor(DS.Colors.textPrimary)
                                    }
                                }
                                // Edit goals button
                                DexSecondaryButton("Edit Goals", icon: "pencil") {
                                    showTracker = false
                                }
                            }
                        }
                        .padding(.horizontal, DS.Spacing.md)

                        // Macro trackers
                        DexCard {
                            VStack(spacing: DS.Spacing.md) {
                                SectionHeader("Macros", icon: "chart.bar.fill")

                                MacroTrackerRow(
                                    emoji: "🥖", title: "Carbs", unit: "g",
                                    value: carbs, goal: carbGoal,
                                    barColor: DS.Colors.warning,
                                    inputText: $inputCarbs
                                ) {
                                    if let v = Double(inputCarbs) { carbs += v; inputCarbs = ""; save(); checkAndLogProgress() }
                                }
                                Divider().background(DS.Colors.border)
                                MacroTrackerRow(
                                    emoji: "🍗", title: "Protein", unit: "g",
                                    value: protein, goal: proteinGoal,
                                    barColor: DS.Colors.info,
                                    inputText: $inputProtein
                                ) {
                                    if let v = Double(inputProtein) { protein += v; inputProtein = ""; save(); checkAndLogProgress() }
                                }
                                Divider().background(DS.Colors.border)
                                MacroTrackerRow(
                                    emoji: "🥑", title: "Fats", unit: "g",
                                    value: fat, goal: fatGoal,
                                    barColor: DS.Colors.success,
                                    inputText: $inputFat
                                ) {
                                    if let v = Double(inputFat) { fat += v; inputFat = ""; save(); checkAndLogProgress() }
                                }
                            }
                        }
                        .padding(.horizontal, DS.Spacing.md)

                        DexCard {
                            VStack(spacing: DS.Spacing.md) {
                                SectionHeader("Hydration", icon: "drop.fill")
                                MacroTrackerRow(
                                    emoji: "💧", title: "Water", unit: "ml",
                                    value: water, goal: waterGoal,
                                    barColor: Color(hex: "#38BDF8"),
                                    inputText: $inputWater
                                ) {
                                    if let v = Double(inputWater) { water += v; inputWater = ""; save(); checkAndLogProgress() }
                                }
                            }
                        }
                        .padding(.horizontal, DS.Spacing.md)

                        // Meal notes
                        DexCard {
                            VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                                SectionHeader("What I Ate Today", icon: "note.text")
                                ZStack(alignment: .topLeading) {
                                    if mealNote.isEmpty {
                                        Text("Add your meals, snacks, notes...")
                                            .foregroundColor(DS.Colors.textMuted)
                                            .font(.system(size: 14))
                                            .padding(.top, 8)
                                            .padding(.leading, 4)
                                    }
                                    TextEditor(text: $mealNote)
                                        .frame(minHeight: 100)
                                        .foregroundColor(DS.Colors.textPrimary)
                                        .scrollContentBackground(.hidden)
                                        .background(Color.clear)
                                        .font(.system(size: 14))
                                        .onChange(of: mealNote) { save() }
                                }
                                .background(DS.Colors.surfaceElevated)
                                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.sm))
                            }
                        }
                        .padding(.horizontal, DS.Spacing.md)

                        Spacer().frame(height: DS.Spacing.xl)
                    }
                    .padding(.top, DS.Spacing.sm)
                }
            }
        }
        .preferredColorScheme(.dark)
        .confirmationDialog("Reset today's progress?", isPresented: $showResetConfirm, titleVisibility: .visible) {
            Button("Reset", role: .destructive) {
                carbs = 0; protein = 0; fat = 0; water = 0; mealNote = ""
                save()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    func save() {
        UserDefaults.standard.set(carbs, forKey: "carbs")
        UserDefaults.standard.set(protein, forKey: "protein")
        UserDefaults.standard.set(fat, forKey: "fat")
        UserDefaults.standard.set(water, forKey: "water")
        UserDefaults.standard.set(mealNote, forKey: "mealNote")
    }

    func checkAndLogProgress() {
        if carbs >= carbGoal && protein >= proteinGoal && fat >= fatGoal && water >= waterGoal {
            let dateKey = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .none)
            let logEntry: [String: Any] = [
                "carbs": carbs, "protein": protein,
                "fat": fat, "water": water, "note": mealNote
            ]
            var logs = UserDefaults.standard.dictionary(forKey: "progressLog") as? [String: [String: Any]] ?? [:]
            if logs[dateKey] == nil {
                logs[dateKey] = logEntry
                UserDefaults.standard.set(logs, forKey: "progressLog")
                NotificationManager.shared.sendGoalCompletedNotification()
            }
        }
    }
}

// MARK: - Macro Tracker Row
struct MacroTrackerRow: View {
    let emoji: String
    let title: String
    let unit: String
    let value: Double
    let goal: Double
    let barColor: Color
    @Binding var inputText: String
    let onAdd: () -> Void

    var progress: Double { goal > 0 ? min(1.0, value / goal) : 0 }
    var isReached: Bool { value >= goal && goal > 0 }

    var body: some View {
        VStack(spacing: DS.Spacing.sm) {
            HStack {
                Text(emoji)
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(DS.Colors.textPrimary)
                Spacer()
                HStack(spacing: 3) {
                    Text("\(Int(value))")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(isReached ? DS.Colors.success : barColor)
                    Text("/ \(Int(goal)) \(unit)")
                        .font(.system(size: 12))
                        .foregroundColor(DS.Colors.textMuted)
                }
                if isReached {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(DS.Colors.success)
                        .font(.system(size: 14))
                }
            }
            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(DS.Colors.surfaceElevated)
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isReached ? DS.Colors.success : barColor)
                        .frame(width: geo.size.width * progress, height: 6)
                }
            }
            .frame(height: 6)
            // Input row
            HStack(spacing: DS.Spacing.sm) {
                TextField("Add \(unit)", text: $inputText)
                    .keyboardType(.decimalPad)
                    .foregroundColor(DS.Colors.textPrimary)
                    .font(.system(size: 14))
                    .padding(.horizontal, DS.Spacing.sm)
                    .padding(.vertical, 8)
                    .background(DS.Colors.surfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: DS.Radius.sm))
                Button(action: onAdd) {
                    Text("Add")
                        .font(.system(size: 13, weight: .semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(barColor.opacity(0.2))
                        .foregroundColor(barColor)
                        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.sm))
                }
            }
        }
    }
}
