import Foundation
import SwiftData

/// 学習記録モデル
/// 1回の学習セッション（開始〜終了）を表す。
@Model
final class StudySession {
    var id: UUID
    /// 紐づく科目
    var subject: Subject?
    /// 開始日時
    var startTime: Date
    /// 終了日時
    var endTime: Date
    /// 学習時間（秒単位）
    var durationSeconds: Int
    /// メモ（振り返りや感想など）
    var memo: String

    /// 学習時間を分単位で取得
    var durationMinutes: Double {
        Double(durationSeconds) / 60.0
    }

    init(
        id: UUID = UUID(),
        subject: Subject? = nil,
        startTime: Date,
        endTime: Date,
        durationSeconds: Int,
        memo: String = ""
    ) {
        self.id = id
        self.subject = subject
        self.startTime = startTime
        self.endTime = endTime
        self.durationSeconds = durationSeconds
        self.memo = memo
    }
}
