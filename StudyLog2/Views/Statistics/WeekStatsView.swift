import SwiftUI
import SwiftData
import Charts

// MARK: - 週タブ
// 今週の学習データを積み上げ棒グラフと科目別割合で表示する

/// 積み上げ棒グラフ用: 日×科目ごとの学習時間データ
struct WeeklySubjectData: Identifiable {
    let id = UUID()
    let date: Date
    let subjectName: String
    let colorHex: String
    let minutes: Double
}

/// 週タブ: 積み上げ棒グラフ＋サマリーカード＋ドーナツグラフ
struct WeekStatsView: View {

    // MARK: - 外部からの入力
    let sessions: [StudySession]
    let subjects: [Subject]

    // MARK: - ViewModel
    @State private var viewModel = StatsViewModel()

    // MARK: - カレンダー
    private let calendar = Calendar.current

    // MARK: - 積み上げ棒グラフ用データ
    /// 過去7日間×各科目の学習時間を算出
    private var weeklyData: [WeeklySubjectData] {
        let today = calendar.startOfDay(for: Date())
        let startDate = calendar.date(byAdding: .day, value: -6, to: today)!

        var result: [WeeklySubjectData] = []

        // 過去7日間をイテレート
        for dayOffset in 0..<7 {
            let date = calendar.date(byAdding: .day, value: dayOffset, to: startDate)!
            let dayStart = calendar.startOfDay(for: date)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!

            // 各科目ごとに集計
            for subject in subjects {
                let minutes = sessions
                    .filter { session in
                        session.subject?.id == subject.id
                            && session.startTime >= dayStart
                            && session.startTime < dayEnd
                    }
                    .reduce(0.0) { $0 + $1.durationMinutes }

                // 0分でもエントリを追加（積み上げの整合性のため）
                result.append(WeeklySubjectData(
                    date: dayStart,
                    subjectName: subject.name,
                    colorHex: subject.color,
                    minutes: minutes
                ))
            }
        }

        return result
    }

    // MARK: - 科目カラーマッピング
    /// chartForegroundStyleScale 用のドメインとレンジ
    private var subjectDomain: [String] {
        subjects.map { $0.name }
    }

    private var subjectColorRange: [Color] {
        subjects.map { Color(hex: $0.color) }
    }

    // MARK: - 曜日フォーマッター
    /// 日本語の曜日略称を返す
    private func weekdayAbbreviation(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }

    var body: some View {
        VStack(spacing: 24) {
            // MARK: 積み上げ棒グラフ
            stackedBarChart

            // MARK: サマリーカード
            summaryCards

            // MARK: ドーナツグラフ
            donutChart
        }
        .onAppear {
            viewModel.sessions = sessions
            viewModel.subjects = subjects
            viewModel.selectedPeriod = .week
        }
    }

    // MARK: - 積み上げ棒グラフ
    private var stackedBarChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("今週の学習時間")
                .font(.headline)

            Chart {
                ForEach(weeklyData) { item in
                    BarMark(
                        x: .value("日付", item.date, unit: .day),
                        y: .value("時間", item.minutes)
                    )
                    .foregroundStyle(by: .value("科目", item.subjectName))
                }
            }
            .chartForegroundStyleScale(
                domain: subjectDomain,
                range: subjectColorRange
            )
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            Text(weekdayAbbreviation(for: date))
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let mins = value.as(Double.self) {
                            Text("\(Int(mins))分")
                        }
                    }
                }
            }
            .chartLegend(.visible)
            .frame(height: 220)
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - サマリーカード
    private var summaryCards: some View {
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
                value: viewModel.totalTimeFormatted
            )

            // 平均/日（カスタムアイコン）
            StatsSummaryCard(title: "平均/日", value: viewModel.averageTimeFormatted) {
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
                value: "\(viewModel.sessionCount)回"
            )

            // 連続日数
            StatsSummaryCard(
                icon: "flame.fill",
                title: "連続日数",
                value: "\(viewModel.streakDays)日"
            )
        }
    }

    // MARK: - ドーナツグラフ
    private var donutChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("今週の科目別割合")
                .font(.headline)

            if viewModel.pieChartData.isEmpty {
                Text("データがありません")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
            } else {
                let totalMinutes = viewModel.pieChartData.reduce(0.0) { $0 + $1.minutes }

                Chart(viewModel.pieChartData) { item in
                    SectorMark(
                        angle: .value("時間", item.minutes),
                        innerRadius: .ratio(0.5),
                        angularInset: 2
                    )
                    .foregroundStyle(item.color)
                    .annotation(position: .overlay) {
                        let percentage = item.minutes / totalMinutes * 100
                        if percentage >= 10 {
                            Text("\(Int(percentage))%")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                        }
                    }
                }
                .frame(height: 200)

                // 凡例
                donutLegend(totalMinutes: totalMinutes)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - ドーナツグラフ凡例
    private func donutLegend(totalMinutes: Double) -> some View {
        VStack(spacing: 6) {
            ForEach(viewModel.pieChartData) { item in
                HStack(spacing: 8) {
                    Circle()
                        .fill(item.color)
                        .frame(width: 10, height: 10)

                    Text(item.subjectName)
                        .font(.caption)

                    Spacer()

                    Text(formatMinutes(item.minutes))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    let percentage = item.minutes / totalMinutes * 100
                    Text("(\(Int(percentage))%)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
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

// MARK: - プレビュー用サンプルデータ生成
/// Preview内でforループが使えないため、関数として切り出す
private func weekPreviewData() -> (sessions: [StudySession], subjects: [Subject]) {
    let math = Subject(name: "数学", color: "#4A90D9", icon: "function", weeklyGoalMinutes: 300)
    let english = Subject(name: "英語", color: "#E67E22", icon: "text.book.closed", weeklyGoalMinutes: 240)
    let programming = Subject(name: "プログラミング", color: "#2ECC71", icon: "chevron.left.forwardslash.chevron.right", weeklyGoalMinutes: 420)

    let subjects = [math, english, programming]
    let calendar = Calendar.current
    let now = Date()
    var sessions: [StudySession] = []

    for dayOffset in 0..<7 {
        let date = calendar.date(byAdding: .day, value: -dayOffset, to: now)!

        // 数学: 30〜90分
        sessions.append(StudySession(
            subject: math,
            startTime: calendar.date(bySettingHour: 9, minute: 0, second: 0, of: date)!,
            endTime: calendar.date(bySettingHour: 10, minute: 0, second: 0, of: date)!,
            durationSeconds: (30 + dayOffset * 10) * 60
        ))

        // 英語: 20〜60分
        sessions.append(StudySession(
            subject: english,
            startTime: calendar.date(bySettingHour: 14, minute: 0, second: 0, of: date)!,
            endTime: calendar.date(bySettingHour: 15, minute: 0, second: 0, of: date)!,
            durationSeconds: (20 + dayOffset * 5) * 60
        ))

        // プログラミング: 40〜100分
        sessions.append(StudySession(
            subject: programming,
            startTime: calendar.date(bySettingHour: 19, minute: 0, second: 0, of: date)!,
            endTime: calendar.date(bySettingHour: 20, minute: 30, second: 0, of: date)!,
            durationSeconds: (40 + dayOffset * 10) * 60
        ))
    }

    return (sessions, subjects)
}

// MARK: - プレビュー
#Preview("週タブ") {
    let data = weekPreviewData()

    ScrollView {
        WeekStatsView(sessions: data.sessions, subjects: data.subjects)
            .padding()
    }
}
