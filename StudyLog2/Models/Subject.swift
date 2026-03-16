import Foundation
import SwiftData

/// 科目モデル
/// 学習する科目（教科）を表す。StudySessionと1対多のリレーションを持つ。
@Model
final class Subject {
    var id: UUID
    /// 科目名（例：数学、英語）
    var name: String
    /// 表示色（16進カラーコード、例："#FF5733"）
    var color: String
    /// SFSymbol名（例："function", "book"）
    var icon: String
    /// 週間目標（分単位）
    var weeklyGoalMinutes: Int
    /// 作成日時（表示順のソートに使用）
    var createdAt: Date = Date()

    /// この科目に紐づく学習記録（カスケード削除）
    @Relationship(deleteRule: .cascade, inverse: \StudySession.subject)
    var sessions: [StudySession] = []

    init(
        id: UUID = UUID(),
        name: String,
        color: String,
        icon: String,
        weeklyGoalMinutes: Int = 0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.color = color
        self.icon = icon
        self.weeklyGoalMinutes = weeklyGoalMinutes
        self.createdAt = createdAt
    }
}
