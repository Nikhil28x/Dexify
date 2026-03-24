import Foundation
import UserNotifications

// MARK: - NotificationManager
final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    // MARK: - Permission
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in }
    }

    // MARK: - Scheduling helpers
    func scheduleRepeating(identifier: String, title: String, body: String, hour: Int, minute: Int) {
        removeNotification(identifier: identifier)
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let req = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(req)
    }

    func removeNotification(identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    // MARK: - Pre-built notifications
    func scheduleTaskReminder() {
        let hour = UserDefaults.standard.integer(forKey: "taskReminderHour")
        let minute = UserDefaults.standard.integer(forKey: "taskReminderMinute")
        let enabled = UserDefaults.standard.bool(forKey: "taskReminderEnabled")
        if enabled {
            scheduleRepeating(
                identifier: "taskReminder",
                title: "Daily Tasks",
                body: "Don't forget to check off your tasks today!",
                hour: hour == 0 ? 9 : hour,
                minute: minute
            )
        } else {
            removeNotification(identifier: "taskReminder")
        }
    }

    func scheduleWaterReminder() {
        let enabled = UserDefaults.standard.bool(forKey: "waterReminderEnabled")
        if enabled {
            for i in 0..<4 {
                scheduleRepeating(
                    identifier: "waterReminder_\(i)",
                    title: "Hydration Check",
                    body: "Time to drink some water! Stay hydrated 💧",
                    hour: 9 + (i * 3),
                    minute: 0
                )
            }
        } else {
            for i in 0..<4 {
                removeNotification(identifier: "waterReminder_\(i)")
            }
        }
    }

    func scheduleNutritionReminder() {
        let enabled = UserDefaults.standard.bool(forKey: "nutritionReminderEnabled")
        if enabled {
            scheduleRepeating(
                identifier: "nutritionReminder",
                title: "Log Your Nutrition",
                body: "Have you tracked your meals today?",
                hour: 13,
                minute: 0
            )
        } else {
            removeNotification(identifier: "nutritionReminder")
        }
    }

    func scheduleConsistencyReminder() {
        let enabled = UserDefaults.standard.bool(forKey: "consistencyReminderEnabled")
        let hour = UserDefaults.standard.integer(forKey: "consistencyReminderHour")
        if enabled {
            scheduleRepeating(
                identifier: "consistencyReminder",
                title: "Consistency Check",
                body: "Keep your streak alive! Log your progress for today.",
                hour: hour == 0 ? 20 : hour,
                minute: 0
            )
        } else {
            removeNotification(identifier: "consistencyReminder")
        }
    }

    func sendGoalCompletedNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Goal Achieved! 🎉"
        content.body = "You've hit all your nutrition goals for today. Great work!"
        content.sound = .default
        let req = UNNotificationRequest(
            identifier: "goalAchieved_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(req)
    }

    func refreshAll() {
        scheduleTaskReminder()
        scheduleWaterReminder()
        scheduleNutritionReminder()
        scheduleConsistencyReminder()
    }
}
