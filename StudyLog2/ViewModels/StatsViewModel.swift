import Foundation
import SwiftUI

// MARK: - 統計画面ViewModel
// 学習データからグラフ・集計値を算出するロジック

/// 表示期間の列挙型
enum StatsPeriod: String, CaseIterable {
    case day = "日"
    case week = "週"
    case month = "月"
}

/// 棒グラフ用: 日別の学習時間データ
struct DailyStudyData: Identifiable {
    let id = UUID()
    let date: Date
    let minutes: Double
}

/// 円グラフ用: 科目別の学習時間データ
struct SubjectStudyData: Identifiable {
    let id = UUID()
    let subjectName: String
    let colorHex: String
    let minutes: Double

    /// 16進カラーコードからColorを生成
    var color: Color {
        Color(hex: colorHex)
    }
}

/// 統計画面のViewModel
/// セッションと科目のデータを受け取り、各種統計値を算出する
@Observable
final class StatsViewModel {

    // MARK: - 入力データ
    var sessions: [StudySession] = []
    var subjects: [Subject] = []

    // MARK: - 選択中の表示期間
    var selectedPeriod: StatsPeriod = .week

    // MARK: - カレンダー
    private let calendar = Calendar.current

    // MARK: - 棒グラフ用データ（選択期間内の日別学習時間）
    var barChartData: [DailyStudyData] {
        let (startDate, endDate) = dateRange(for: selectedPeriod)
        let filteredSessions = sessions.filter { $0.startTime >= startDate && $0.startTime < endDate }

        // 期間内の全日付を生成
        var dates: [Date] = []
        var current = startDate
        while current < endDate {
            dates.append(current)
            current = calendar.date(byAdding: .day, value: 1, to: current)!
        }

        return dates.map { date in
            let dayStart = calendar.startOfDay(for: date)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            let totalMinutes = filteredSessions
                .filter { $0.startTime >= dayStart && $0.startTime < dayEnd }
                .reduce(0.0) { $0 + $1.durationMinutes }
            return DailyStudyData(date: dayStart, minutes: totalMinutes)
        }
    }

    // MARK: - 円グラフ用データ（科目別学習時間）
    var pieChartData: [SubjectStudyData] {
        let (startDate, endDate) = dateRange(for: selectedPeriod)
        let filteredSessions = sessions.filter { $0.startTime >= startDate && $0.startTime < endDate }

        // 科目ごとに学習時間を集計
        var subjectMinutes: [UUID: Double] = [:]
        for session in filteredSessions {
            guard let subject = session.subject else { continue }
            subjectMinutes[subject.id, default: 0] += session.durationMinutes
        }

        return subjects.compactMap { subject in
            guard let minutes = subjectMinutes[subject.id], minutes > 0 else { return nil }
            return SubjectStudyData(
                subjectName: subject.name,
                colorHex: subject.color,
                minutes: minutes
            )
        }
        .sorted { $0.minutes > $1.minutes }
    }

    // MARK: - サマリー指標

    /// 選択期間内の合計学習時間（分）
    var totalMinutes: Double {
        let (startDate, endDate) = dateRange(for: selectedPeriod)
        return sessions
            .filter { $0.startTime >= startDate && $0.startTime < endDate }
            .reduce(0.0) { $0 + $1.durationMinutes }
    }

    /// 合計時間をフォーマットした文字列
    var totalTimeFormatted: String {
        formatMinutes(totalMinutes)
    }

    /// 1日あたりの平均学習時間（分）
    var averageMinutesPerDay: Double {
        let days = max(daysInPeriod, 1)
        return totalMinutes / Double(days)
    }

    /// 平均時間をフォーマットした文字列
    var averageTimeFormatted: String {
        formatMinutes(averageMinutesPerDay)
    }

    /// 選択期間内のセッション数
    var sessionCount: Int {
        let (startDate, endDate) = dateRange(for: selectedPeriod)
        return sessions
            .filter { $0.startTime >= startDate && $0.startTime < endDate }
            .count
    }

    /// 連続学習日数（ストリーク）
    /// 今日から遡って、1日でもセッションがあった連続日数を算出
    var streakDays: Int {
        let today = calendar.startOfDay(for: Date())

        // 各日付にセッションがあるかをSetで管理
        let studyDays: Set<Date> = Set(
            sessions.map { calendar.startOfDay(for: $0.startTime) }
        )

        var streak = 0
        var checkDate = today

        while studyDays.contains(checkDate) {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = previousDay
        }

        return streak
    }

    // MARK: - ヘルパー

    /// 選択期間の開始日と終了日を返す
    private func dateRange(for period: StatsPeriod) -> (start: Date, end: Date) {
        let now = Date()
        let todayStart = calendar.startOfDay(for: now)
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: todayStart)!

        switch period {
        case .day:
            // 今日を含む過去7日間（日別表示）
            let weekAgo = calendar.date(byAdding: .day, value: -6, to: todayStart)!
            return (weekAgo, tomorrow)
        case .week:
            // 今日を含む過去7日間
            let weekAgo = calendar.date(byAdding: .day, value: -6, to: todayStart)!
            return (weekAgo, tomorrow)
        case .month:
            // 今日を含む過去30日間
            let monthAgo = calendar.date(byAdding: .day, value: -29, to: todayStart)!
            return (monthAgo, tomorrow)
        }
    }

    /// 選択期間の日数
    private var daysInPeriod: Int {
        switch selectedPeriod {
        case .day: return 7
        case .week: return 7
        case .month: return 30
        }
    }

    /// 分数を「X時間Y分」形式にフォーマット
    private func formatMinutes(_ minutes: Double) -> String {
        let totalMins = Int(minutes)
        let hours = totalMins / 60
        let mins = totalMins % 60
        if hours > 0 {
            return "\(hours)時間\(mins)分"
        } else {
            return "\(mins)分"
        }
    }
}

// Color(hex:) は Extensions/Color+Hex.swift で定義済み
