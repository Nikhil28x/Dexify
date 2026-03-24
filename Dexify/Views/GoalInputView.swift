import SwiftUI

struct GoalInputView: View {
    @Binding var showTracker: Bool
    @Binding var carbGoal: Double
    @Binding var proteinGoal: Double
    @Binding var fatGoal: Double
    @Binding var waterGoal: Double
    @Binding var selectedModule: SelectedModule

    var body: some View {
        ZStack {
            DS.Gradients.pageBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                DexNavBar(
                    title: "Daily Goals",
                    subtitle: "Set your nutrition targets",
                    leadingAction: { selectedModule = .none }
                )

                ScrollView(showsIndicators: false) {
                    VStack(spacing: DS.Spacing.lg) {

                        // Hero banner
                        DexCard(padding: DS.Spacing.lg) {
                            HStack(spacing: DS.Spacing.md) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Fuel Your Goals")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(DS.Colors.textPrimary)
                                    Text("Set your daily macro and hydration targets to start tracking.")
                                        .font(.system(size: 13))
                                        .foregroundColor(DS.Colors.textSecondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                Spacer()
                                Image(systemName: "target")
                                    .font(.system(size: 36))
                                    .foregroundColor(DS.Colors.success.opacity(0.6))
                            }
                        }
                        .padding(.horizontal, DS.Spacing.md)

                        // Goal fields
                        DexCard {
                            VStack(spacing: DS.Spacing.md) {
                                SectionHeader("Macronutrients", icon: "fork.knife")

                                GoalFieldRow(icon: "🥖", title: "Carbohydrates", unit: "g", value: $carbGoal, color: DS.Colors.warning)
                                Divider().background(DS.Colors.border)
                                GoalFieldRow(icon: "🍗", title: "Protein", unit: "g", value: $proteinGoal, color: DS.Colors.info)
                                Divider().background(DS.Colors.border)
                                GoalFieldRow(icon: "🥑", title: "Fats", unit: "g", value: $fatGoal, color: DS.Colors.success)
                            }
                        }
                        .padding(.horizontal, DS.Spacing.md)

                        DexCard {
                            VStack(spacing: DS.Spacing.md) {
                                SectionHeader("Hydration", icon: "drop.fill")
                                GoalFieldRow(icon: "💧", title: "Water", unit: "ml", value: $waterGoal, color: Color(hex: "#38BDF8"))
                            }
                        }
                        .padding(.horizontal, DS.Spacing.md)

                        // Calorie estimate
                        let estCals = Int(carbGoal * 4 + proteinGoal * 4 + fatGoal * 9)
                        DexCard {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Estimated Daily Calories")
                                        .font(.system(size: 13))
                                        .foregroundColor(DS.Colors.textSecondary)
                                    Text("\(estCals) kcal")
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(DS.Colors.textPrimary)
                                }
                                Spacer()
                                Image(systemName: "bolt.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(DS.Colors.warning.opacity(0.5))
                            }
                        }
                        .padding(.horizontal, DS.Spacing.md)

                        DexPrimaryButton("Start Tracking", icon: "play.fill") {
                            UserDefaults.standard.set(carbGoal, forKey: "carbGoal")
                            UserDefaults.standard.set(proteinGoal, forKey: "proteinGoal")
                            UserDefaults.standard.set(fatGoal, forKey: "fatGoal")
                            UserDefaults.standard.set(waterGoal, forKey: "waterGoal")
                            showTracker = true
                        }
                        .padding(.horizontal, DS.Spacing.md)

                        Spacer().frame(height: DS.Spacing.xl)
                    }
                    .padding(.top, DS.Spacing.sm)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct GoalFieldRow: View {
    let icon: String
    let title: String
    let unit: String
    @Binding var value: Double
    let color: Color

    @State private var text: String = ""

    var body: some View {
        HStack(spacing: DS.Spacing.sm) {
            Text(icon)
                .font(.system(size: 20))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(DS.Colors.textPrimary)
                Text(unit)
                    .font(.system(size: 11))
                    .foregroundColor(DS.Colors.textMuted)
            }
            Spacer()
            HStack(spacing: 6) {
                TextField("0", text: $text)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(color)
                    .frame(width: 70)
                    .onChange(of: text) { newVal in
                        if let d = Double(newVal) { value = d }
                    }
                    .onAppear {
                        text = value == 0 ? "" : String(Int(value))
                    }
                Text(unit)
                    .font(.system(size: 13))
                    .foregroundColor(DS.Colors.textMuted)
            }
        }
    }
}

