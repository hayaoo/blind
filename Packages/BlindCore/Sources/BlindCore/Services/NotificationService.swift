import UserNotifications

public class NotificationService: NSObject {
    public static let shared = NotificationService()

    private var onNotificationAction: (() -> Void)?

    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        setupCategories()
    }

    public func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }

    public func showReminder(onStart: @escaping () -> Void) {
        onNotificationAction = onStart

        let content = UNMutableNotificationContent()
        content.title = "Blind"
        content.body = "目を閉じて、今を確認しましょう"
        content.sound = .default
        content.categoryIdentifier = "REMINDER"

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // Deliver immediately
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to show notification: \(error)")
            }
        }
    }

    public func setupCategories() {
        let startAction = UNNotificationAction(
            identifier: "START",
            title: "開始",
            options: [.foreground]
        )

        let laterAction = UNNotificationAction(
            identifier: "LATER",
            title: "後で",
            options: []
        )

        let category = UNNotificationCategory(
            identifier: "REMINDER",
            actions: [startAction, laterAction],
            intentIdentifiers: [],
            options: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
}

extension NotificationService: UNUserNotificationCenterDelegate {
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if response.actionIdentifier == "START" ||
           response.actionIdentifier == UNNotificationDefaultActionIdentifier {
            onNotificationAction?()
        }
        completionHandler()
    }

    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
