import SwiftUI

struct ProgressLogView: View {
    @Binding var selectedModule: SelectedModule

    @State private var progressLogs: [String: [String: Any]] = [:]

    var sortedKeys: [String] {
        progressLogs.keys.sorted(by: { $0 > $1 })
    }

    var totalDays: Int { progressLogs.count }

    var body: some View {
        ZStack {
            DS.Gradients.pageBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                DexNavBar(
                    title: "Progress Log",
                    subtitle: "Your nutrition history",
                    leadingAction: { selectedModule = .none }
                )

                if progressLogs.isEmpty {
                    Spacer()
                    VStack(spacing: DS.Spacing.md) {
                        Image(systemName: "chart.bar.doc.horizontal")
                            .font(.system(size: 52))
                            .foregroundColor(DS.Colors.textMuted)
                        Text("No logs yet")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(DS.Colors.textPrimary)
                        Text("Complete your daily nutrition goals to start logging.")
                            .font(.system(size: 14))
                            .foregroundColor(DS.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, DS.Spacing.xl)
                    }
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: DS.Spacing.lg) {

                            // Stats row
                            HStack(spacing: DS.Spacing.sm) {
                                StatBadge(value: "\(totalDays)", label: "Days Logged", color: DS.Colors.accent)
                                StatBadge(value: bestStreak(), label: "Best Streak", color: DS.Colors.warning)
                                StatBadge(value: thisWeekCount(), label: "This Week", color: DS.Colors.success)
                            }
                            .padding(.horizontal, DS.Spacing.md)

                            // Log entries
                            VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                                SectionHeader("History", icon: "clock.arrow.circlepath")
                                    .padding(.horizontal, DS.Spacing.md)

                                ForEach(sortedKeys, id: \.self) { date in
                                    if let entry = progressLogs[date] {
                                        ProgressLogEntryCard(date: date, entry: entry)
                                            .padding(.horizontal, DS.Spacing.md)
                                    }
                                }
                            }

                            Spacer().frame(height: DS.Spacing.xl)
                        }
                        .padding(.top, DS.Spacing.sm)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            if let logs = UserDefaults.standard.dictionary(forKey: "progressLog") as? [String: [String: Any]] {
                self.progressLogs = logs
            }
        }
    }

    func bestStreak() -> String {
        // Simple count for now
        return "\(totalDays)"
    }

    func thisWeekCount() -> String {
        let calendar = Calendar.current
        let now = Date()
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? now
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        let count = sortedKeys.filter { key in
            if let d = formatter.date(from: key) {
                return d >= startOfWeek
            }
            return false
        }.count
        return "\(count)"
    }
}

struct ProgressLogEntryCard: View {
    let date: String
    let entry: [String: Any]

    @State private var expanded = false

    var body: some View {
        DexCard(padding: DS.Spacing.md) {
            VStack(spacing: DS.Spacing.sm) {
                // Header
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { expanded.toggle() }
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(date)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(DS.Colors.textPrimary)
                            Text(calorieSummary())
                                .font(.system(size: 12))
                                .foregroundColor(DS.Colors.textSecondary)
                        }
                        Spacer()
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(DS.Colors.success)
                                .font(.system(size: 14))
                            Text("Goal Met")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(DS.Colors.success)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(DS.Colors.success.opacity(0.12))
                        .clipShape(Capsule())

                        Image(systemName: expanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12))
                            .foregroundColor(DS.Colors.textMuted)
                    }
                }
                .buttonStyle(PlainButtonStyle())

                if expanded {
                    Divider().background(DS.Colors.border)

                    // Macro grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DS.Spacing.sm) {
                        if let carbs = entry["carbs"] as? Double {
                            MacroCell(emoji: "🥖", label: "Carbs", value: "\(Int(carbs))g", color: DS.Colors.warning)
                        }
                        if let protein = entry["protein"] as? Double {
                            MacroCell(emoji: "🍗", label: "Protein", value: "\(Int(protein))g", color: DS.Colors.info)
                        }
                        if let fat = entry["fat"] as? Double {
                            MacroCell(emoji: "🥑", label: "Fat", value: "\(Int(fat))g", color: DS.Colors.success)
                        }
                        if let water = entry["water"] as? Double {
                            MacroCell(emoji: "💧", label: "Water", value: "\(Int(water))ml", color: Color(hex: "#38BDF8"))
                        }
                    }

                    if let note = entry["note"] as? String, !note.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            SectionHeader("Meal Notes", icon: "note.text")
                            Text(note)
                                .font(.system(size: 13))
                                .foregroundColor(DS.Colors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
    }

    func calorieSummary() -> String {
        let c = (entry["carbs"] as? Double ?? 0) * 4
        let p = (entry["protein"] as? Double ?? 0) * 4
        let f = (entry["fat"] as? Double ?? 0) * 9
        return "\(Int(c + p + f)) kcal tracked"
    }
}

struct MacroCell: View {
    let emoji: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Text(emoji)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 11))
                    .foregroundColor(DS.Colors.textMuted)
                Text(value)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(color)
            }
            Spacer()
        }
        .padding(DS.Spacing.sm)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.sm))
    }
}

