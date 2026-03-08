import UserNotifications

public class NotificationService: NSObject {
    public static let shared = NotificationService()

    private var onNotificationAction: (() -> Void)?
    private var onGraceAction: (() -> Void)?

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

    /// エスカレーションレベルに応じたリマインド通知を表示
    public func showReminder(
        escalation: EscalationLevel = .normal,
        graceAvailable: Bool = true,
        onStart: @escaping () -> Void,
        onGrace: (() -> Void)? = nil
    ) {
        onNotificationAction = onStart
        onGraceAction = onGrace

        let content = UNMutableNotificationContent()

        switch escalation {
        case .normal:
            content.title = "目を休めよう"
            content.body = "立ち止まって、今やっていることを確認しよう"
        case .elevated:
            content.title = "象が走り出しています"
            content.body = "2回連続スキップ。5秒だけ目を閉じて、象使いに確認してみませんか？"
        case .urgent:
            content.title = "象が暴走しています"
            content.body = "3回以上スキップが続いています。今すぐ立ち止まりましょう"
        }

        content.sound = .default
        content.categoryIdentifier = graceAvailable ? "REMINDER_WITH_GRACE" : "REMINDER"

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to show notification: \(error)")
            }
        }
    }

    /// 後方互換: 旧シグネチャ
    public func showReminder(onStart: @escaping () -> Void) {
        showReminder(escalation: .normal, graceAvailable: true, onStart: onStart, onGrace: nil)
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

        let graceAction = UNNotificationAction(
            identifier: "GRACE",
            title: "5分だけ猶予",
            options: []
        )

        // 猶予なし（通常 or 猶予使用済み）
        let category = UNNotificationCategory(
            identifier: "REMINDER",
            actions: [startAction, laterAction],
            intentIdentifiers: [],
            options: []
        )

        // 猶予あり（初回リマインド）
        let categoryWithGrace = UNNotificationCategory(
            identifier: "REMINDER_WITH_GRACE",
            actions: [startAction, graceAction, laterAction],
            intentIdentifiers: [],
            options: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([category, categoryWithGrace])
    }
}

extension NotificationService: UNUserNotificationCenterDelegate {
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        switch response.actionIdentifier {
        case "START", UNNotificationDefaultActionIdentifier:
            onNotificationAction?()
        case "GRACE":
            onGraceAction?()
        case "LATER":
            // スキップとして記録（AppDelegate側で処理）
            break
        default:
            break
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
