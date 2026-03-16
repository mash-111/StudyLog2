import Foundation
import UserNotifications

/// 通知管理サービス
/// ローカル通知の許可リクエスト・スケジュール・キャンセルを担当する。
@Observable
final class NotificationManager {

    // MARK: - シングルトン
    static let shared = NotificationManager()

    /// 通知許可の状態
    var isAuthorized: Bool = false

    private let center = UNUserNotificationCenter.current()

    private init() {
        // 初期化時に現在の許可状態を取得
        Task { @MainActor in
            await checkAuthorizationStatus()
        }
    }

    // MARK: - 許可状態の確認

    /// 現在の通知許可状態を確認して更新する
    @MainActor
    func checkAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
    }

    // MARK: - 通知許可リクエスト

    /// 通知の許可をユーザーにリクエストする
    /// - Returns: 許可されたかどうか
    @MainActor
    @discardableResult
    func requestPermission() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            isAuthorized = granted
            return granted
        } catch {
            print("通知許可リクエストエラー: \(error.localizedDescription)")
            isAuthorized = false
            return false
        }
    }

    // MARK: - 目標達成通知のスケジュール

    /// 目標達成時の通知をスケジュールする
    /// - Parameter goalMinutes: 目標時間（分単位）
    func scheduleGoalAchievedNotification(goalMinutes: Int) {
        let content = UNMutableNotificationContent()
        content.title = "目標達成！🎉"
        content.body = "今日の学習目標（\(formattedMinutes(goalMinutes))）を達成しました！素晴らしい！"
        content.sound = .default

        // 目標達成通知は即座にトリガー（学習完了時に呼ばれる想定）
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "goalAchieved",
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error {
                print("目標達成通知のスケジュールエラー: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - 毎日のリマインダー通知

    /// 毎日のリマインダー通知をスケジュールする
    /// - Parameter time: リマインダーの通知時刻
    func scheduleDailyReminder(at time: Date) {
        // 既存のリマインダーをキャンセル
        center.removePendingNotificationRequests(withIdentifiers: ["dailyReminder"])

        let content = UNMutableNotificationContent()
        content.title = "学習リマインダー"
        content.body = "今日の学習を始めましょう！目標達成に向けて頑張りましょう。"
        content.sound = .default

        // 指定時刻から時・分を抽出して毎日繰り返すトリガーを作成
        let calendar = Calendar.current
        var dateComponents = DateComponents()
        dateComponents.hour = calendar.component(.hour, from: time)
        dateComponents.minute = calendar.component(.minute, from: time)

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "dailyReminder",
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error {
                print("リマインダー通知のスケジュールエラー: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - 通知の全キャンセル

    /// すべての保留中の通知をキャンセルする
    func cancelAll() {
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
    }

    /// リマインダー通知のみキャンセルする
    func cancelDailyReminder() {
        center.removePendingNotificationRequests(withIdentifiers: ["dailyReminder"])
    }

    // MARK: - ヘルパー

    /// 分数を「◯時間◯分」形式にフォーマットする
    private func formattedMinutes(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 && mins > 0 {
            return "\(hours)時間\(mins)分"
        } else if hours > 0 {
            return "\(hours)時間"
        } else {
            return "\(mins)分"
        }
    }
}
