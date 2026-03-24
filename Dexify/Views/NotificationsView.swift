import SwiftUI
import UserNotifications

// MARK: - GoalItem model
struct GoalItem: Identifiable, Codable {
    var id = UUID()
    var title: String
    var description: String
    var targetCount: Int      // e.g. 30 days
    var currentStreak: Int
    var longestStreak: Int
    var lastCheckedIn: Date?
    var completedDates: [String]  // "yyyy-MM-dd" strings
    var category: GoalCategory
    var reminderEnabled: Bool
    var reminderHour: Int
    var reminderMinute: Int
    var createdAt: Date

    enum GoalCategory: String, Codable, CaseIterable {
        case health = "Health"
        case fitness = "Fitness"
        case nutrition = "Nutrition"
        case mindfulness = "Mindfulness"
        case productivity = "Productivity"
        case custom = "Custom"

        var icon: String {
            switch self {
            case .health: return "heart.fill"
            case .fitness: return "figure.run"
            case .nutrition: return "fork.knife"
            case .mindfulness: return "brain.head.profile"
            case .productivity: return "checkmark.circle.fill"
            case .custom: return "star.fill"
            }
        }

        var color: Color {
            switch self {
            case .health: return DS.Colors.danger
            case .fitness: return DS.Colors.success
            case .nutrition: return DS.Colors.warning
            case .mindfulness: return DS.Colors.accent
            case .productivity: return DS.Colors.info
            case .custom: return Color(hex: "#EC4899")
            }
        }
    }

    var isCheckedInToday: Bool {
        let today = Self.dateKey(for: Date())
        return completedDates.contains(today)
    }

    static func dateKey(for date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    mutating func checkIn() {
        let today = Self.dateKey(for: Date())
        guard !completedDates.contains(today) else { return }
        completedDates.append(today)

        // Update streak
        let yesterday = Self.dateKey(for: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date())
        if completedDates.contains(yesterday) {
            currentStreak += 1
        } else {
            currentStreak = 1
        }
        if currentStreak > longestStreak { longestStreak = currentStreak }
        lastCheckedIn = Date()
    }

    var completionRate: Double {
        guard targetCount > 0 else { return 0 }
        return min(1.0, Double(completedDates.count) / Double(targetCount))
    }

    var last30DaysDates: [String] {
        (0..<30).compactMap { offset in
            Calendar.current.date(byAdding: .day, value: -offset, to: Date()).map { Self.dateKey(for: $0) }
        }.reversed()
    }
}

// MARK: - GoalStore
class GoalStore: ObservableObject {
    @Published var goals: [GoalItem] = []

    init() { load() }

    func save() {
        if let encoded = try? JSONEncoder().encode(goals) {
            UserDefaults.standard.set(encoded, forKey: "userGoals")
        }
        // Update streak count for home screen badge
        let maxStreak = goals.map { $0.currentStreak }.max() ?? 0
        UserDefaults.standard.set(maxStreak, forKey: "currentStreakCount")
    }

    func load() {
        if let data = UserDefaults.standard.data(forKey: "userGoals"),
           let decoded = try? JSONDecoder().decode([GoalItem].self, from: data) {
            goals = decoded
        }
    }

    func add(_ goal: GoalItem) {
        goals.append(goal)
        save()
    }

    func delete(at offsets: IndexSet) {
        goals.remove(atOffsets: offsets)
        save()
    }

    func checkIn(goal: GoalItem) {
        guard let idx = goals.firstIndex(where: { $0.id == goal.id }) else { return }
        goals[idx].checkIn()
        save()
        if goals[idx].reminderEnabled {
            scheduleGoalReminder(goals[idx])
        }
    }

    private func scheduleGoalReminder(_ goal: GoalItem) {
        NotificationManager.shared.scheduleRepeating(
            identifier: "goal_\(goal.id.uuidString)",
            title: "Goal Reminder: \(goal.title)",
            body: "Don't break your streak! Check in for '\(goal.title)' today.",
            hour: goal.reminderHour,
            minute: goal.reminderMinute
        )
    }

    func updateReminderFor(_ goal: GoalItem) {
        if goal.reminderEnabled {
            scheduleGoalReminder(goal)
        } else {
            NotificationManager.shared.removeNotification(identifier: "goal_\(goal.id.uuidString)")
        }
    }
}

// MARK: - NotificationsView (Main Hub)
struct NotificationsView: View {
    @Binding var selectedModule: SelectedModule
    @StateObject private var store = GoalStore()

    @State private var showAddGoal = false
    @State private var selectedTab = 0

    var body: some View {
        ZStack {
            DS.Gradients.pageBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                DexNavBar(
                    title: "Goals",
                    subtitle: "Track your consistency",
                    leadingAction: { selectedModule = .none },
                    trailingAction: { showAddGoal = true },
                    trailingIcon: "plus"
                )

                // Tab bar
                HStack(spacing: 0) {
                    ForEach(["Goals", "Notifications"].indices, id: \.self) { i in
                        Button(["Goals", "Notifications"][i]) { withAnimation { selectedTab = i } }
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(selectedTab == i ? DS.Colors.textPrimary : DS.Colors.textMuted)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .overlay(
                                Rectangle()
                                    .frame(height: 2)
                                    .foregroundColor(selectedTab == i ? DS.Colors.accent : Color.clear),
                                alignment: .bottom
                            )
                    }
                }
                .background(DS.Colors.surface)
                .overlay(Rectangle().frame(height: 1).foregroundColor(DS.Colors.border), alignment: .bottom)

                if selectedTab == 0 {
                    GoalsTab(store: store)
                } else {
                    NotificationSettingsTab()
                }
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showAddGoal) {
            AddGoalSheet(store: store)
        }
    }
}

// MARK: - Goals Tab
struct GoalsTab: View {
    @ObservedObject var store: GoalStore

    var overallStreak: Int { store.goals.map { $0.currentStreak }.max() ?? 0 }
    var todayDone: Int { store.goals.filter { $0.isCheckedInToday }.count }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: DS.Spacing.lg) {

                // Summary
                HStack(spacing: DS.Spacing.sm) {
                    StatBadge(value: "\(overallStreak)", label: "Best Streak", color: DS.Colors.warning)
                    StatBadge(value: "\(store.goals.count)", label: "Active Goals", color: DS.Colors.accent)
                    StatBadge(value: "\(todayDone)/\(store.goals.count)", label: "Today", color: DS.Colors.success)
                }
                .padding(.horizontal, DS.Spacing.md)

                if store.goals.isEmpty {
                    VStack(spacing: DS.Spacing.md) {
                        Image(systemName: "target")
                            .font(.system(size: 48))
                            .foregroundColor(DS.Colors.textMuted)
                        Text("No goals yet")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(DS.Colors.textPrimary)
                        Text("Tap + to add your first goal and start tracking consistency.")
                            .font(.system(size: 13))
                            .foregroundColor(DS.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, DS.Spacing.xl)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DS.Spacing.xxl)
                } else {
                    VStack(spacing: DS.Spacing.sm) {
                        ForEach(store.goals) { goal in
                            GoalCard(goal: goal, onCheckIn: {
                                store.checkIn(goal: goal)
                            })
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

// MARK: - Goal Card
struct GoalCard: View {
    let goal: GoalItem
    let onCheckIn: () -> Void
    @State private var expanded = false

    var body: some View {
        DexCard(padding: DS.Spacing.md) {
            VStack(spacing: DS.Spacing.sm) {
                // Header row
                HStack(spacing: DS.Spacing.sm) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(goal.category.color.opacity(0.2))
                            .frame(width: 44, height: 44)
                        Image(systemName: goal.category.icon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(goal.category.color)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(goal.title)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(DS.Colors.textPrimary)
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 10))
                                .foregroundColor(DS.Colors.warning)
                            Text("\(goal.currentStreak) day streak")
                                .font(.system(size: 12))
                                .foregroundColor(DS.Colors.textMuted)
                        }
                    }
                    Spacer()
                    // Check-in button
                    Button(action: onCheckIn) {
                        ZStack {
                            Circle()
                                .fill(goal.isCheckedInToday ? DS.Colors.success : DS.Colors.surfaceElevated)
                                .frame(width: 40, height: 40)
                            Image(systemName: goal.isCheckedInToday ? "checkmark" : "plus")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(goal.isCheckedInToday ? .white : DS.Colors.textMuted)
                        }
                    }
                    .disabled(goal.isCheckedInToday)
                }

                // Progress bar
                VStack(spacing: 4) {
                    HStack {
                        Text("\(goal.completedDates.count) / \(goal.targetCount) days")
                            .font(.system(size: 11))
                            .foregroundColor(DS.Colors.textMuted)
                        Spacer()
                        Text("\(Int(goal.completionRate * 100))%")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(goal.category.color)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(DS.Colors.surfaceElevated)
                                .frame(height: 6)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(goal.category.color)
                                .frame(width: geo.size.width * goal.completionRate, height: 6)
                        }
                    }
                    .frame(height: 6)
                }

                // Expand for heatmap
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { expanded.toggle() }
                } label: {
                    HStack {
                        Text("Last 30 Days")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(DS.Colors.textMuted)
                        Spacer()
                        Image(systemName: expanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 11))
                            .foregroundColor(DS.Colors.textMuted)
                    }
                }
                .buttonStyle(PlainButtonStyle())

                if expanded {
                    ConsistencyHeatmap(goal: goal)
                }
            }
        }
    }
}

// MARK: - Consistency Heatmap
struct ConsistencyHeatmap: View {
    let goal: GoalItem

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 10)

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(goal.last30DaysDates, id: \.self) { dateKey in
                    let filled = goal.completedDates.contains(dateKey)
                    let isToday = dateKey == GoalItem.dateKey(for: Date())
                    RoundedRectangle(cornerRadius: 3)
                        .fill(filled ? goal.category.color : DS.Colors.surfaceElevated)
                        .frame(height: 24)
                        .overlay(
                            isToday ? RoundedRectangle(cornerRadius: 3)
                                .stroke(goal.category.color, lineWidth: 1.5) : nil
                        )
                }
            }
            HStack {
                Circle().fill(DS.Colors.surfaceElevated).frame(width: 10, height: 10)
                Text("Missed").font(.system(size: 10)).foregroundColor(DS.Colors.textMuted)
                Spacer().frame(width: 12)
                Circle().fill(goal.category.color).frame(width: 10, height: 10)
                Text("Completed").font(.system(size: 10)).foregroundColor(DS.Colors.textMuted)
            }
        }
    }
}

// MARK: - Notification Settings Tab
struct NotificationSettingsTab: View {
    @AppStorage("taskReminderEnabled") private var taskReminderEnabled = false
    @AppStorage("taskReminderHour") private var taskReminderHour = 9
    @AppStorage("waterReminderEnabled") private var waterReminderEnabled = false
    @AppStorage("nutritionReminderEnabled") private var nutritionReminderEnabled = false
    @AppStorage("consistencyReminderEnabled") private var consistencyReminderEnabled = false
    @AppStorage("consistencyReminderHour") private var consistencyReminderHour = 20

    @State private var permissionGranted = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: DS.Spacing.lg) {

                // Permission banner
                if !permissionGranted {
                    DexCard(padding: DS.Spacing.md) {
                        HStack(spacing: DS.Spacing.sm) {
                            Image(systemName: "bell.badge.fill")
                                .font(.system(size: 22))
                                .foregroundColor(DS.Colors.warning)
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Enable Notifications")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(DS.Colors.textPrimary)
                                Text("Allow Dexify to send you reminders.")
                                    .font(.system(size: 12))
                                    .foregroundColor(DS.Colors.textSecondary)
                            }
                            Spacer()
                            Button("Enable") {
                                NotificationManager.shared.requestPermission()
                            }
                            .font(.system(size: 13, weight: .semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(DS.Colors.warning.opacity(0.2))
                            .foregroundColor(DS.Colors.warning)
                            .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal, DS.Spacing.md)
                }

                // Settings cards
                DexCard {
                    VStack(spacing: DS.Spacing.md) {
                        SectionHeader("Reminders", icon: "bell.fill")

                        NotifToggleRow(
                            icon: "checkmark.circle.fill",
                            title: "Task Reminder",
                            subtitle: "Daily nudge to complete your tasks",
                            color: DS.Colors.info,
                            isOn: $taskReminderEnabled,
                            onChange: { NotificationManager.shared.scheduleTaskReminder() }
                        )

                        Divider().background(DS.Colors.border)

                        NotifToggleRow(
                            icon: "drop.fill",
                            title: "Water Reminders",
                            subtitle: "Every 3 hrs from 9am",
                            color: Color(hex: "#38BDF8"),
                            isOn: $waterReminderEnabled,
                            onChange: { NotificationManager.shared.scheduleWaterReminder() }
                        )

                        Divider().background(DS.Colors.border)

                        NotifToggleRow(
                            icon: "fork.knife",
                            title: "Nutrition Log Reminder",
                            subtitle: "Nudge at 1pm to log your meals",
                            color: DS.Colors.warning,
                            isOn: $nutritionReminderEnabled,
                            onChange: { NotificationManager.shared.scheduleNutritionReminder() }
                        )

                        Divider().background(DS.Colors.border)

                        NotifToggleRow(
                            icon: "flame.fill",
                            title: "Consistency Reminder",
                            subtitle: "Evening nudge to keep your streak",
                            color: DS.Colors.danger,
                            isOn: $consistencyReminderEnabled,
                            onChange: { NotificationManager.shared.scheduleConsistencyReminder() }
                        )
                    }
                }
                .padding(.horizontal, DS.Spacing.md)

                Spacer().frame(height: DS.Spacing.xl)
            }
            .padding(.top, DS.Spacing.sm)
        }
        .onAppear {
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                DispatchQueue.main.async {
                    permissionGranted = settings.authorizationStatus == .authorized
                }
            }
        }
    }
}

struct NotifToggleRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    @Binding var isOn: Bool
    let onChange: () -> Void

    var body: some View {
        HStack(spacing: DS.Spacing.sm) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.2))
                    .frame(width: 38, height: 38)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(DS.Colors.textPrimary)
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(DS.Colors.textMuted)
            }
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(color)
                .onChange(of: isOn) { _ in onChange() }
        }
    }
}

// MARK: - Add Goal Sheet
struct AddGoalSheet: View {
    @ObservedObject var store: GoalStore
    @Environment(\.dismiss) var dismiss

    @State private var title = ""
    @State private var description = ""
    @State private var targetCount = 30
    @State private var category: GoalItem.GoalCategory = .fitness
    @State private var reminderEnabled = false
    @State private var reminderHour = 20
    @State private var reminderMinute = 0

    var body: some View {
        ZStack {
            DS.Gradients.pageBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                // Sheet handle
                RoundedRectangle(cornerRadius: 3)
                    .fill(DS.Colors.border)
                    .frame(width: 36, height: 4)
                    .padding(.top, DS.Spacing.sm)

                HStack {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(DS.Colors.textSecondary)
                    Spacer()
                    Text("New Goal")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(DS.Colors.textPrimary)
                    Spacer()
                    Button("Add") {
                        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        var goal = GoalItem(
                            title: title.trimmingCharacters(in: .whitespaces),
                            description: description,
                            targetCount: targetCount,
                            currentStreak: 0,
                            longestStreak: 0,
                            completedDates: [],
                            category: category,
                            reminderEnabled: reminderEnabled,
                            reminderHour: reminderHour,
                            reminderMinute: reminderMinute,
                            createdAt: Date()
                        )
                        store.add(goal)
                        if reminderEnabled {
                            store.updateReminderFor(goal)
                        }
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(title.trimmingCharacters(in: .whitespaces).isEmpty ? DS.Colors.textMuted : DS.Colors.accent)
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: DS.Spacing.lg) {
                        DexCard {
                            VStack(spacing: DS.Spacing.md) {
                                SectionHeader("Goal Details", icon: "pencil")
                                DexTextField(placeholder: "Goal title (e.g. Meditate daily)", text: $title)
                                DexTextField(placeholder: "Description (optional)", text: $description)
                            }
                        }
                        .padding(.horizontal, DS.Spacing.md)

                        DexCard {
                            VStack(spacing: DS.Spacing.md) {
                                SectionHeader("Category", icon: "tag")
                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: DS.Spacing.sm) {
                                    ForEach(GoalItem.GoalCategory.allCases, id: \.self) { cat in
                                        Button {
                                            category = cat
                                        } label: {
                                            VStack(spacing: 6) {
                                                Image(systemName: cat.icon)
                                                    .font(.system(size: 18))
                                                    .foregroundColor(category == cat ? .white : cat.color)
                                                Text(cat.rawValue)
                                                    .font(.system(size: 10, weight: .semibold))
                                                    .foregroundColor(category == cat ? .white : DS.Colors.textSecondary)
                                            }
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, DS.Spacing.sm)
                                            .background(category == cat ? cat.color : DS.Colors.surfaceElevated)
                                            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.sm))
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, DS.Spacing.md)

                        DexCard {
                            VStack(spacing: DS.Spacing.md) {
                                SectionHeader("Target", icon: "flag.fill")
                                HStack {
                                    Text("Target days")
                                        .font(.system(size: 14))
                                        .foregroundColor(DS.Colors.textSecondary)
                                    Spacer()
                                    HStack(spacing: DS.Spacing.sm) {
                                        Button { if targetCount > 1 { targetCount -= 1 } } label: {
                                            Image(systemName: "minus.circle.fill")
                                                .font(.system(size: 22))
                                                .foregroundColor(DS.Colors.textMuted)
                                        }
                                        Text("\(targetCount)")
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundColor(DS.Colors.textPrimary)
                                            .frame(minWidth: 36, alignment: .center)
                                        Button { targetCount += 1 } label: {
                                            Image(systemName: "plus.circle.fill")
                                                .font(.system(size: 22))
                                                .foregroundColor(DS.Colors.accent)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, DS.Spacing.md)

                        DexCard {
                            VStack(spacing: DS.Spacing.md) {
                                SectionHeader("Reminder", icon: "bell.fill")
                                HStack {
                                    Text("Daily reminder")
                                        .font(.system(size: 14))
                                        .foregroundColor(DS.Colors.textSecondary)
                                    Spacer()
                                    Toggle("", isOn: $reminderEnabled)
                                        .labelsHidden()
                                        .tint(DS.Colors.accent)
                                }
                                if reminderEnabled {
                                    DatePicker("Time", selection: Binding(
                                        get: {
                                            Calendar.current.date(from: DateComponents(hour: reminderHour, minute: reminderMinute)) ?? Date()
                                        },
                                        set: { date in
                                            reminderHour = Calendar.current.component(.hour, from: date)
                                            reminderMinute = Calendar.current.component(.minute, from: date)
                                        }
                                    ), displayedComponents: .hourAndMinute)
                                    .colorScheme(.dark)
                                }
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
    }
}
