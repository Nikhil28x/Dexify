import SwiftUI

struct ModuleCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let gradient: LinearGradient
    let accentColor: Color
    let action: () -> Void

    @State private var pressed = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: DS.Spacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: DS.Radius.md)
                        .fill(accentColor.opacity(0.2))
                        .frame(width: 52, height: 52)
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(accentColor)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(DS.Colors.textPrimary)
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(DS.Colors.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(DS.Colors.textMuted)
            }
            .padding(DS.Spacing.md)
            .background(DS.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.lg)
                    .stroke(DS.Colors.border, lineWidth: 1)
            )
            .scaleEffect(pressed ? 0.97 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in withAnimation(.easeInOut(duration: 0.1)) { pressed = true } }
                .onEnded { _ in withAnimation(.easeInOut(duration: 0.15)) { pressed = false } }
        )
    }
}

struct ModuleSelectionView: View {
    var userName: String
    var onModuleSelected: (SelectedModule) -> Void

    @State private var animate = false
    @State private var glowPulse = false

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<21: return "Good evening"
        default: return "Hey"
        }
    }

    var body: some View {
        ZStack {
            DS.Gradients.pageBackground
                .ignoresSafeArea()

            // Ambient glow
            Circle()
                .fill(DS.Colors.accent.opacity(0.12))
                .frame(width: 300, height: 300)
                .blur(radius: 90)
                .offset(x: 80, y: -120)
                .scaleEffect(glowPulse ? 1.15 : 0.9)
                .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: glowPulse)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {

                    // Header
                    VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                        Text(greeting + ",")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(DS.Colors.textSecondary)
                        Text(userName)
                            .font(.system(size: 32, weight: .black, design: .rounded))
                            .foregroundColor(DS.Colors.textPrimary)
                        Text(formattedDate())
                            .font(.system(size: 13))
                            .foregroundColor(DS.Colors.textMuted)
                    }
                    .padding(.horizontal, DS.Spacing.md)
                    .padding(.top, DS.Spacing.xl)
                    .padding(.bottom, DS.Spacing.lg)
                    .opacity(animate ? 1 : 0)
                    .offset(y: animate ? 0 : 16)
                    .animation(.easeOut(duration: 0.6).delay(0.1), value: animate)

                    // Quick stats row
                    HStack(spacing: DS.Spacing.sm) {
                        StatBadge(value: "3", label: "Modules", color: DS.Colors.accent)
                        StatBadge(value: streakDays(), label: "Day Streak", color: DS.Colors.success)
                        StatBadge(value: pendingTasks(), label: "Tasks Due", color: DS.Colors.warning)
                    }
                    .padding(.horizontal, DS.Spacing.md)
                    .padding(.bottom, DS.Spacing.lg)
                    .opacity(animate ? 1 : 0)
                    .offset(y: animate ? 0 : 16)
                    .animation(.easeOut(duration: 0.6).delay(0.2), value: animate)

                    // Modules section
                    VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                        SectionHeader("Your Modules", icon: "square.grid.2x2")
                            .padding(.horizontal, DS.Spacing.md)

                        VStack(spacing: DS.Spacing.sm) {
                            ModuleCard(
                                icon: "checkmark.circle.fill",
                                title: "To-Do List",
                                subtitle: "Tasks, categories & streaks",
                                gradient: DS.Gradients.cardBlue,
                                accentColor: DS.Colors.info
                            ) { onModuleSelected(.todo) }

                            ModuleCard(
                                icon: "flame.fill",
                                title: "Gym Tracker",
                                subtitle: "Macros, water & nutrition",
                                gradient: DS.Gradients.cardGreen,
                                accentColor: DS.Colors.success
                            ) { onModuleSelected(.gym) }

                            ModuleCard(
                                icon: "chart.bar.fill",
                                title: "Progress Log",
                                subtitle: "Daily history & achievements",
                                gradient: DS.Gradients.cardAmber,
                                accentColor: DS.Colors.warning
                            ) { onModuleSelected(.progressLog) }

                            ModuleCard(
                                icon: "bell.badge.fill",
                                title: "Goals & Notifications",
                                subtitle: "Set goals, track consistency",
                                gradient: DS.Gradients.cardPurple,
                                accentColor: DS.Colors.accent
                            ) { onModuleSelected(.notifications) }
                        }
                        .padding(.horizontal, DS.Spacing.md)
                    }
                    .opacity(animate ? 1 : 0)
                    .offset(y: animate ? 0 : 20)
                    .animation(.easeOut(duration: 0.6).delay(0.3), value: animate)

                    // Mascot
                    HStack {
                        Spacer()
                        DinosaurView()
                            .opacity(animate ? 1 : 0)
                            .animation(.easeOut(duration: 0.6).delay(0.5), value: animate)
                    }
                    .padding(.horizontal, DS.Spacing.md)
                    .padding(.top, DS.Spacing.lg)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            animate = true
            glowPulse = true
        }
    }

    func formattedDate() -> String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, d MMMM"
        return f.string(from: Date())
    }

    func streakDays() -> String {
        // Reads from UserDefaults streak logic
        let count = UserDefaults.standard.integer(forKey: "currentStreakCount")
        return "\(count)"
    }

    func pendingTasks() -> String {
        guard let data = UserDefaults.standard.data(forKey: "tasks"),
              let decoded = try? JSONDecoder().decode([Task].self, from: data) else { return "0" }
        let pending = decoded.filter { !$0.isCompleted && $0.category == "Daily" }.count
        return "\(pending)"
    }
}
