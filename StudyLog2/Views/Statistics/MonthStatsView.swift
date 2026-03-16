import SwiftUI
import SwiftData
import Charts

// MARK: - 月タブ
// 今月の学習データを週ごとの折れ線グラフで表示する

/// 週ごとの集計データ（折れ線グラフ用）
struct WeeklyAggregateData: Identifiable {
    let id = UUID()
    let weekLabel: String  // "第1週", "第2週", etc.
    let weekNumber: Int
    let totalMinutes: Double
}

/// 月タブ: 折れ線グラフ＋サマリーカード＋ドーナツグラフ
struct MonthStatsView: View {

    // MARK: - 外部からの入力
    let sessions: [StudySession]
    let subjects: [Subject]

    // MARK: - ViewModel
    @State private var viewModel = StatsViewModel()

    // MARK: - カレンダー
    private let calendar = Calendar.current

    // MARK: - 今月の期間
    private var monthStart: Date {
        let components = calendar.dateComponents([.year, .month], from: Date())
        return calendar.date(from: components)!
    }

    private var monthEnd: Date {
        calendar.date(byAdding: .month, value: 1, to: monthStart)!
    }

    // MARK: - 今月のセッション
    private var currentMonthSessions: [StudySession] {
        sessions.filter { $0.startTime >= monthStart && $0.startTime < monthEnd }
    }

    // MARK: - 週ごとの集計データ
    private var weeklyData: [WeeklyAggregateData] {
        let filtered = currentMonthSessions

        // 週ごとにグルーピング
        var weekMinutes: [Int: Double] = [:]
        for session in filtered {
            let weekOfMonth = calendar.component(.weekOfMonth, from: session.startTime)
            weekMinutes[weekOfMonth, default: 0] += session.durationMinutes
        }

        // 今月に存在する週の範囲を取得
        let lastDay = calendar.date(byAdding: .day, value: -1, to: monthEnd)!
        let maxWeek = calendar.component(.weekOfMonth, from: lastDay)

        // 全週のデータを生成（データがない週は0分）
        return (1...maxWeek).map { week in
            WeeklyAggregateData(
                weekLabel: "第\(week)週",
                weekNumber: week,
                totalMinutes: weekMinutes[week, default: 0]
            )
        }
    }

    // MARK: - 科目別データ（ドーナツグラフ用）
    private var subjectData: [SubjectStudyData] {
        let filtered = currentMonthSessions

        // 科目ごとに学習時間を集計
        var subjectMinutes: [UUID: Double] = [:]
        for session in filtered {
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

    // MARK: - サマリー値
    private var totalMinutes: Double {
        currentMonthSessions.reduce(0.0) { $0 + $1.durationMinutes }
    }

    private var totalTimeFormatted: String {
        formatMinutes(totalMinutes)
    }

    private var daysInCurrentMonth: Int {
        let range = calendar.range(of: .day, in: .month, for: Date())!
        return range.count
    }

    private var averageMinutesPerDay: Double {
        // 今日が月の何日目かを使って平均を計算（未来の日は含めない）
        let dayOfMonth = calendar.component(.day, from: Date())
        return totalMinutes / Double(max(dayOfMonth, 1))
    }

    private var averageTimeFormatted: String {
        formatMinutes(averageMinutesPerDay)
    }

    private var sessionCount: Int {
        currentMonthSessions.count
    }

    // MARK: - ビュー本体
    var body: some View {
        VStack(spacing: 24) {
            // MARK: - 折れ線グラフ
            lineChartSection

            // MARK: - サマリーカード
            summaryCardsSection

            // MARK: - ドーナツグラフ
            if !subjectData.isEmpty {
                donutChartSection
            }
        }
        .onAppear {
            viewModel.sessions = sessions
            viewModel.subjects = subjects
            viewModel.selectedPeriod = .month
        }
    }

    // MARK: - 折れ線グラフセクション
    private var lineChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("週ごとの学習時間")
                .font(.headline)

            Chart(weeklyData) { item in
                LineMark(
                    x: .value("週", item.weekLabel),
                    y: .value("時間", item.totalMinutes)
                )
                .foregroundStyle(Color("AccentColor"))
                .interpolationMethod(.linear)

                PointMark(
                    x: .value("週", item.weekLabel),
                    y: .value("時間", item.totalMinutes)
                )
                .foregroundStyle(Color("AccentColor"))
                .symbolSize(100)
            }
            .chartYAxisLabel("分")
            .frame(height: 200)
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - サマリーカードセクション
    private var summaryCardsSection: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
            ],
            spacing: 12
        ) {
            // 合計時間
            StatsSummaryCard(
                icon: "clock.fill",
                title: "合計時間",
                value: totalTimeFormatted
            )

            // 平均/日（カスタムアイコン）
            StatsSummaryCard(title: "平均/日", value: averageTimeFormatted) {
                HStack(spacing: 2) {
                    Image(systemName: "clock.fill")
                    Text("/").fontWeight(.bold)
                    Image(systemName: "calendar")
                }
            }

            // セッション数
            StatsSummaryCard(
                icon: "number.circle.fill",
                title: "セッション数",
                value: "\(sessionCount)回"
            )

            // 連続日数
            StatsSummaryCard(
                icon: "flame.fill",
                title: "連続日数",
                value: "\(viewModel.streakDays)日"
            )
        }
        .padding(.horizontal)
    }

    // MARK: - ドーナツグラフセクション
    private var donutChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("今月の科目別割合")
                .font(.headline)

            Chart(subjectData) { item in
                SectorMark(
                    angle: .value("時間", item.minutes),
                    innerRadius: .ratio(0.5),
                    angularInset: 2
                )
                .foregroundStyle(item.color)
            }
            .frame(height: 200)

            // 凡例
            donutLegend
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - ドーナツグラフの凡例
    private var donutLegend: some View {
        let totalMins = subjectData.reduce(0.0) { $0 + $1.minutes }

        return VStack(alignment: .leading, spacing: 8) {
            ForEach(subjectData) { item in
                HStack(spacing: 8) {
                    Circle()
                        .fill(item.color)
                        .frame(width: 12, height: 12)

                    Text(item.subjectName)
                        .font(.subheadline)

                    Spacer()

                    Text(formatMinutes(item.minutes))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    let percentage = totalMins > 0 ? (item.minutes / totalMins * 100) : 0
                    Text(String(format: "%.0f%%", percentage))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .frame(width: 40, alignment: .trailing)
                }
            }
        }
    }

    // MARK: - ヘルパー

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

// MARK: - プレビュー
#Preview("月タブ") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: StudySession.self, Subject.self, DailyGoal.self,
        configurations: config
    )
    let context = container.mainContext

    // 科目を作成
    let subjectMath = Subject(name: "数学", color: "#FF6B6B", icon: "function")
    let subjectEnglish = Subject(name: "英語", color: "#4ECDC4", icon: "book")
    let subjectScience = Subject(name: "理科", color: "#45B7D1", icon: "flask")
    context.insert(subjectMath)
    context.insert(subjectEnglish)
    context.insert(subjectScience)

    // 30日分のセッションデータを生成（今月の1日から）
    let calendar = Calendar.current
    let today = Date()
    let monthComponents = calendar.dateComponents([.year, .month], from: today)
    let monthStart = calendar.date(from: monthComponents)!
    let subjects = [subjectMath, subjectEnglish, subjectScience]

    // 今月の1日目から今日までのデータを生成
    let dayOfMonth = calendar.component(.day, from: today)
    let daysToGenerate = min(dayOfMonth, 30)

    for dayOffset in 0..<daysToGenerate {
        let baseDate = calendar.date(byAdding: .day, value: dayOffset, to: monthStart)!
        // 各科目ごとにセッションを作成
        for (subjectIndex, subject) in subjects.enumerated() {
            let hour = 9 + subjectIndex * 3
            let startTime = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: baseDate)!
            let durationSeconds = (30 + (dayOffset * 7 + subjectIndex * 13) % 90) * 60
            let endTime = startTime.addingTimeInterval(Double(durationSeconds))
            let session = StudySession(
                subject: subject,
                startTime: startTime,
                endTime: endTime,
                durationSeconds: durationSeconds
            )
            context.insert(session)
        }
    }

    // セッションを取得してビューに渡す
    let descriptor = FetchDescriptor<StudySession>()
    let allSessions = (try? context.fetch(descriptor)) ?? []
    let subjectDescriptor = FetchDescriptor<Subject>()
    let allSubjects = (try? context.fetch(subjectDescriptor)) ?? []

    return MonthStatsView(sessions: allSessions, subjects: allSubjects)
        .modelContainer(container)
}
