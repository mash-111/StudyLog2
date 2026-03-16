import Foundation
import SwiftData

/// 日次目標モデル
/// 1日あたりの学習目標時間と通知設定を管理する。
@Model
final class DailyGoal {
    var id: UUID
    /// 目標時間（分単位）
    var targetMinutes: Int
    /// 通知の有効/無効
    var notificationEnabled: Bool
    /// 通知時刻（時刻部分のみ使用）
    var notificationTime: Date

    /// 目標時間を時間・分のフォーマットで取得（例："1時間30分"）
    var formattedTarget: String {
        let hours = targetMinutes / 60
        let minutes = targetMinutes % 60
        if hours > 0 && minutes > 0 {
            return "\(hours)時間\(minutes)分"
        } else if hours > 0 {
            return "\(hours)時間"
        } else {
            return "\(minutes)分"
        }
    }

    init(
        id: UUID = UUID(),
        targetMinutes: Int = 60,
        notificationEnabled: Bool = false,
        notificationTime: Date = Calendar.current.date(from: DateComponents(hour: 21, minute: 0)) ?? Date()
    ) {
        self.id = id
        self.targetMinutes = targetMinutes
        self.notificationEnabled = notificationEnabled
        self.notificationTime = notificationTime
    }
}
