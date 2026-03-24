import SwiftUI
import UserNotifications

// MARK: - Task Model
struct Task: Identifiable, Codable {
    var id = UUID()
    var title: String
    var isCompleted: Bool
    var previousTitle: String?
    var category: String
    var status: String // Completed, Ongoing, Not Today
}

// MARK: - ChecklistView
struct ChecklistView: View {
    @Binding var selectedModule: SelectedModule

    @State private var tasks: [Task] = []
    @State private var lastResetDate: Date?
    @State private var newTaskTitle: String = ""
    @State private var selectedCategory: String = "Daily"
    @State private var activeFilter: String = "All"
    @State private var showStreak = false
    @State private var userName: String? = UserDefaults.standard.string(forKey: "userName")

    private let categories = ["Daily", "Work", "Personal"]
    private let filters = ["All", "Daily", "Work", "Personal"]

    var filteredTasks: [Task] {
        if activeFilter == "All" { return tasks }
        return tasks.filter { $0.category == activeFilter }
    }

    var completedCount: Int { tasks.filter { $0.isCompleted }.count }

    var body: some View {
        ZStack(alignment: .bottom) {
            DS.Gradients.pageBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Nav bar
                DexNavBar(
                    title: "\(userName ?? "Your") Tasks",
                    subtitle: formattedDate(),
                    leadingAction: {
                        selectedModule = .none
                        UserDefaults.standard.removeObject(forKey: "lastModule")
                    }
                )

                ScrollView(showsIndicators: false) {
                    VStack(spacing: DS.Spacing.lg) {

                        // Progress summary
                        DexCard {
                            VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("\(completedCount) of \(tasks.count)")
                                            .font(.system(size: 26, weight: .black))
                                            .foregroundColor(DS.Colors.textPrimary)
                                        Text("tasks completed today")
                                            .font(.system(size: 13))
                                            .foregroundColor(DS.Colors.textSecondary)
                                    }
                                    Spacer()
                                    ZStack {
                                        Circle()
                                            .stroke(DS.Colors.border, lineWidth: 4)
                                            .frame(width: 56, height: 56)
                                        Circle()
                                            .trim(from: 0, to: tasks.isEmpty ? 0 : CGFloat(completedCount) / CGFloat(tasks.count))
                                            .stroke(DS.Colors.success, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                                            .frame(width: 56, height: 56)
                                            .rotationEffect(.degrees(-90))
                                        Text("\(tasks.isEmpty ? 0 : Int(Double(completedCount) / Double(tasks.count) * 100))%")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(DS.Colors.textPrimary)
                                    }
                                }
                                if !tasks.isEmpty {
                                    ProgressView(value: Double(completedCount), total: Double(tasks.count))
                                        .tint(DS.Colors.success)
                                        .background(DS.Colors.border)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .padding(.horizontal, DS.Spacing.md)

                        // Add task input
                        DexCard {
                            VStack(spacing: DS.Spacing.sm) {
                                SectionHeader("New Task", icon: "plus.circle")
                                HStack(spacing: DS.Spacing.sm) {
                                    DexTextField(placeholder: "What do you need to do?", text: $newTaskTitle)
                                    Button(action: addTaskFromInput) {
                                        Image(systemName: "arrow.up.circle.fill")
                                            .font(.system(size: 36))
                                            .foregroundColor(newTaskTitle.trimmingCharacters(in: .whitespaces).isEmpty
                                                ? DS.Colors.textMuted : DS.Colors.accent)
                                    }
                                    .disabled(newTaskTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                                }
                                // Category picker
                                HStack(spacing: DS.Spacing.sm) {
                                    ForEach(categories, id: \.self) { cat in
                                        Button(cat) { selectedCategory = cat }
                                            .font(.system(size: 12, weight: .semibold))
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 7)
                                            .background(selectedCategory == cat ? DS.Colors.accent : DS.Colors.surfaceElevated)
                                            .foregroundColor(selectedCategory == cat ? .white : DS.Colors.textSecondary)
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, DS.Spacing.md)

                        // Filter bar
                        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                            SectionHeader("Tasks", icon: "list.bullet")
                                .padding(.horizontal, DS.Spacing.md)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: DS.Spacing.sm) {
                                    ForEach(filters, id: \.self) { f in
                                        Button(f) { activeFilter = f }
                                            .font(.system(size: 13, weight: .semibold))
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(activeFilter == f ? DS.Colors.accent : DS.Colors.surface)
                                            .foregroundColor(activeFilter == f ? .white : DS.Colors.textSecondary)
                                            .clipShape(Capsule())
                                            .overlay(
                                                Capsule().stroke(
                                                    activeFilter == f ? Color.clear : DS.Colors.border,
                                                    lineWidth: 1
                                                )
                                            )
                                    }
                                }
                                .padding(.horizontal, DS.Spacing.md)
                            }
                        }

                        // Task list
                        if filteredTasks.isEmpty {
                            VStack(spacing: DS.Spacing.sm) {
                                Image(systemName: "checkmark.seal")
                                    .font(.system(size: 40))
                                    .foregroundColor(DS.Colors.textMuted)
                                Text("No tasks here")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(DS.Colors.textMuted)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, DS.Spacing.xxl)
                        } else {
                            VStack(spacing: DS.Spacing.sm) {
                                ForEach($tasks) { $task in
                                    if activeFilter == "All" || task.category == activeFilter {
                                        TaskRowView(task: $task, onSave: saveTasks, onDelete: {
                                            if let idx = tasks.firstIndex(where: { $0.id == task.id }) {
                                                tasks.remove(at: idx)
                                                saveTasks()
                                            }
                                        })
                                    }
                                }
                            }
                            .padding(.horizontal, DS.Spacing.md)
                        }

                        // Streak link
                        Button { showStreak = true } label: {
                            DexCard {
                                HStack {
                                    Image(systemName: "flame.fill")
                                        .foregroundColor(DS.Colors.warning)
                                    Text("View Weekly Streak")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(DS.Colors.textPrimary)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(DS.Colors.textMuted)
                                }
                            }
                            .padding(.horizontal, DS.Spacing.md)
                        }
                        .buttonStyle(PlainButtonStyle())

                        Spacer().frame(height: DS.Spacing.xxl)
                    }
                    .padding(.top, DS.Spacing.sm)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear(perform: onAppStart)
        .sheet(isPresented: $showStreak) { TaskStreakView() }
    }

    // MARK: - Helpers

    func addTaskFromInput() {
        let trimmed = newTaskTitle.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let newTask = Task(title: trimmed, isCompleted: false, category: selectedCategory, status: "Ongoing")
        tasks.append(newTask)
        newTaskTitle = ""
        saveTasks()
    }

    func saveTasks() {
        if let encoded = try? JSONEncoder().encode(tasks) {
            UserDefaults.standard.set(encoded, forKey: "tasks")
        }
        UserDefaults.standard.set(Date(), forKey: "lastResetDate")
    }

    func loadTasks() {
        if let data = UserDefaults.standard.data(forKey: "tasks"),
           let decoded = try? JSONDecoder().decode([Task].self, from: data) {
            tasks = decoded
        }
        lastResetDate = UserDefaults.standard.object(forKey: "lastResetDate") as? Date
    }

    func checkAndResetTasks() {
        let calendar = Calendar.current
        if let lastReset = lastResetDate, !calendar.isDateInToday(lastReset) {
            for i in tasks.indices where tasks[i].category == "Daily" {
                tasks[i].isCompleted = false
                tasks[i].status = "Ongoing"
            }
            saveTasks()
        }
    }

    func onAppStart() {
        loadTasks()
        checkAndResetTasks()
        NotificationManager.shared.requestPermission()
        NotificationManager.shared.scheduleTaskReminder()
    }

    func formattedDate() -> String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, d MMMM"
        return f.string(from: Date())
    }
}

// MARK: - Task Row
struct TaskRowView: View {
    @Binding var task: Task
    let onSave: () -> Void
    let onDelete: () -> Void

    @State private var isEditing = false

    var statusColor: Color {
        switch task.status {
        case "Completed": return DS.Colors.success
        case "Ongoing": return DS.Colors.warning
        case "Not today": return DS.Colors.textMuted
        default: return DS.Colors.textMuted
        }
    }

    var body: some View {
        HStack(spacing: DS.Spacing.sm) {
            // Complete toggle
            Button {
                task.isCompleted.toggle()
                task.status = task.isCompleted ? "Completed" : "Ongoing"
                onSave()
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(task.isCompleted ? DS.Colors.success : DS.Colors.textMuted)
            }

            // Title
            TextField("Task name", text: $task.title, onEditingChanged: { editing in
                if editing { isEditing = true }
                else if isEditing {
                    onSave()
                    isEditing = false
                }
            })
            .font(.system(size: 15, weight: .medium))
            .foregroundColor(task.isCompleted ? DS.Colors.textMuted : DS.Colors.textPrimary)
            .strikethrough(task.isCompleted, color: DS.Colors.textMuted)

            Spacer(minLength: 0)

            // Category badge
            Text(task.category)
                .font(.system(size: 10, weight: .semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(DS.Colors.surfaceElevated)
                .foregroundColor(DS.Colors.textMuted)
                .clipShape(Capsule())

            // Status dot menu
            Menu {
                Button("Completed") { task.status = "Completed"; task.isCompleted = true; onSave() }
                Button("Ongoing") { task.status = "Ongoing"; task.isCompleted = false; onSave() }
                Button("Not today") { task.status = "Not today"; onSave() }
                Divider()
                Button(role: .destructive, action: onDelete) {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Circle()
                    .fill(statusColor)
                    .frame(width: 10, height: 10)
                    .padding(4)
            }
        }
        .padding(.horizontal, DS.Spacing.md)
        .padding(.vertical, 13)
        .background(DS.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.md)
                .stroke(task.isCompleted ? DS.Colors.success.opacity(0.3) : DS.Colors.border, lineWidth: 1)
        )
    }
}

// MARK: - Task Streak View
struct TaskStreakView: View {
    private let orderedDays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    @State private var streaks: [String: Bool] = {
        if let saved = UserDefaults.standard.dictionary(forKey: "taskStreaks") as? [String: Bool] {
            return saved
        }
        return ["Mon": false, "Tue": false, "Wed": false, "Thu": false, "Fri": false, "Sat": false, "Sun": false]
    }()

    var streakCount: Int { streaks.values.filter { $0 }.count }

    var body: some View {
        ZStack {
            DS.Gradients.pageBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: DS.Spacing.lg) {
                    // Header summary
                    DexCard {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(streakCount)")
                                    .font(.system(size: 42, weight: .black))
                                    .foregroundColor(DS.Colors.warning)
                                Text("days this week")
                                    .font(.system(size: 14))
                                    .foregroundColor(DS.Colors.textSecondary)
                            }
                            Spacer()
                            Image(systemName: "flame.fill")
                                .font(.system(size: 48))
                                .foregroundColor(DS.Colors.warning.opacity(0.3))
                        }
                    }
                    .padding(.horizontal, DS.Spacing.md)

                    // Day grid
                    DexCard {
                        VStack(spacing: DS.Spacing.sm) {
                            SectionHeader("Weekly Progress", icon: "calendar")
                            HStack(spacing: DS.Spacing.sm) {
                                ForEach(orderedDays, id: \.self) { day in
                                    Button {
                                        streaks[day] = !(streaks[day] ?? false)
                                        UserDefaults.standard.set(streaks, forKey: "taskStreaks")
                                    } label: {
                                        VStack(spacing: 6) {
                                            Text(String(day.prefix(1)))
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundColor(streaks[day] == true ? .white : DS.Colors.textMuted)
                                            Circle()
                                                .fill(streaks[day] == true ? DS.Colors.warning : DS.Colors.surfaceElevated)
                                                .frame(width: 32, height: 32)
                                                .overlay(
                                                    streaks[day] == true
                                                    ? AnyView(Image(systemName: "checkmark").font(.system(size: 12, weight: .bold)).foregroundColor(.white))
                                                    : AnyView(EmptyView())
                                                )
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, DS.Spacing.md)

                    Spacer()
                }
                .padding(.top, DS.Spacing.lg)
            }
        }
        .preferredColorScheme(.dark)
        .navigationTitle("Weekly Streak")
        .navigationBarTitleDisplayMode(.inline)
    }
}
