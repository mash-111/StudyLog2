import Foundation
import SwiftData

// MARK: - Preview用サンプルデータ

extension Subject {
    /// Preview用のサンプル科目データ
    static let sampleSubjects: [Subject] = [
        Subject(name: "数学", color: "#4A90D9", icon: "function", weeklyGoalMinutes: 300),
        Subject(name: "英語", color: "#E67E22", icon: "text.book.closed", weeklyGoalMinutes: 240),
        Subject(name: "プログラミング", color: "#2ECC71", icon: "chevron.left.forwardslash.chevron.right", weeklyGoalMinutes: 420),
        Subject(name: "物理", color: "#9B59B6", icon: "atom", weeklyGoalMinutes: 180),
        Subject(name: "国語", color: "#E74C3C", icon: "book", weeklyGoalMinutes: 150),
    ]

    /// 単体のサンプル科目
    static let sampleMath = Subject(name: "数学", color: "#4A90D9", icon: "function", weeklyGoalMinutes: 300)
}

extension StudySession {
    /// Preview用のサンプル学習記録データ
    static func sampleSessions(for subject: Subject) -> [StudySession] {
        let calendar = Calendar.current
        let now = Date()

        return [
            // 今日の記録
            StudySession(
                subject: subject,
                startTime: calendar.date(byAdding: .hour, value: -2, to: now)!,
                endTime: calendar.date(byAdding: .hour, value: -1, to: now)!,
                durationSeconds: 3600,
                memo: "二次方程式の解の公式を復習した"
            ),
            // 昨日の記録
            StudySession(
                subject: subject,
                startTime: calendar.date(byAdding: .day, value: -1, to: calendar.date(bySettingHour: 19, minute: 0, second: 0, of: now)!)!,
                endTime: calendar.date(byAdding: .day, value: -1, to: calendar.date(bySettingHour: 19, minute: 45, second: 0, of: now)!)!,
                durationSeconds: 2700,
                memo: "微分の基本を学習"
            ),
            // 2日前の記録
            StudySession(
                subject: subject,
                startTime: calendar.date(byAdding: .day, value: -2, to: calendar.date(bySettingHour: 20, minute: 0, second: 0, of: now)!)!,
                endTime: calendar.date(byAdding: .day, value: -2, to: calendar.date(bySettingHour: 20, minute: 30, second: 0, of: now)!)!,
                durationSeconds: 1800,
                memo: "確率の問題演習"
            ),
        ]
    }

    /// 単体のサンプル学習記録
    static var sampleSession: StudySession {
        StudySession(
            startTime: Date().addingTimeInterval(-3600),
            endTime: Date(),
            durationSeconds: 3600,
            memo: "集中して取り組めた"
        )
    }
}

extension DailyGoal {
    /// Preview用のサンプル日次目標データ
    static let sampleGoal = DailyGoal(
        targetMinutes: 90,
        notificationEnabled: true,
        notificationTime: Calendar.current.date(from: DateComponents(hour: 21, minute: 0)) ?? Date()
    )
}

// MARK: - Preview用のModelContainerヘルパー

/// Preview用のインメモリModelContainerを生成する
@MainActor
func previewContainer() throws -> ModelContainer {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(
        for: Subject.self, StudySession.self, DailyGoal.self,
        configurations: config
    )

    // サンプル科目を挿入
    for subject in Subject.sampleSubjects {
        container.mainContext.insert(subject)

        // 各科目にサンプルセッションを追加
        for session in StudySession.sampleSessions(for: subject) {
            container.mainContext.insert(session)
        }
    }

    // サンプル日次目標を挿入
    container.mainContext.insert(DailyGoal.sampleGoal)

    return container
}
