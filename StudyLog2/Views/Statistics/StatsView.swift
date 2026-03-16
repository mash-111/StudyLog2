import SwiftUI
import SwiftData
import Charts

// MARK: - 統計画面
// 学習データをグラフと数値で可視化するメイン画面

/// 統計画面: 棒グラフ・円グラフ・サマリーカードで学習データを表示
struct StatsView: View {

    // MARK: - データ取得
    @Query private var sessions: [StudySession]
    @Query private var subjects: [Subject]
    @Query private var dailyGoals: [DailyGoal]

    // MARK: - ViewModel
    @State private var viewModel = StatsViewModel()

    // MARK: - ビュー本体
    var body: some View {
        NavigationStack {
            if sessions.isEmpty {
                // 学習セッションが存在しない場合の空状態表示
                emptySessionsView
                    .navigationTitle("統計")
            } else {
                ScrollView {
                    VStack(spacing: 24) {
                        // MARK: - 期間切り替えセグメント
                        periodPicker

                        // MARK: - 日別学習時間の棒グラフ
                        barChartSection

                        // MARK: - サマリーカード（2x2グリッド）
                        summaryCardsSection

                        // MARK: - 科目別割合の円グラフ
                        pieChartSection
                    }
                    .padding(.vertical)
                }
                .navigationTitle("統計")
            }
        }
        .onAppear {
            updateViewModel()
        }
        .onChange(of: sessions.count) {
            updateViewModel()
        }
        .onChange(of: subjects.count) {
            updateViewModel()
        }
    }

    // MARK: - ViewModelへデータを渡す
    private func updateViewModel() {
        viewModel.sessions = sessions
        viewModel.subjects = subjects
    }

    // MARK: - セッション未記録時の空状態ビュー

    /// 学習セッションがまだないときに表示するビュー
    private var emptySessionsView: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 64))
                .foregroundStyle(Color("AccentColor"))

            Text("まだ学習記録がありません")
                .font(.title2)
                .fontWeight(.bold)

            Text("タイマーで学習を始めると\nここに統計が表示されます")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 32)
    }

    // MARK: - 期間切り替えピッカー
    private var periodPicker: some View {
        Picker("表示期間", selection: $viewModel.selectedPeriod) {
            ForEach(StatsPeriod.allCases, id: \.self) { period in
                Text(period.rawValue).tag(period)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
    }

    // MARK: - 棒グラフセクション
    private var barChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("学習時間の推移")
                .font(.headline)
                .padding(.horizontal)

            Chart {
                ForEach(viewModel.barChartData) { item in
                    BarMark(
                        x: .value("日付", item.date, unit: .day),
                        y: .value("時間（分）", item.minutes)
                    )
                    .foregroundStyle(Color("AccentColor").gradient)
                    .cornerRadius(4)
                }

                // 目標ライン: DailyGoalのtargetMinutesを破線で表示
                // 目標未設定（0分）の場合は非表示
                // 週・月タブには表示しない（日タブのみ）
                if viewModel.selectedPeriod == .day,
                   let goal = dailyGoals.first,
                   goal.targetMinutes > 0 {
                    RuleMark(y: .value("目標", goal.targetMinutes))
                        .foregroundStyle(.orange.opacity(0.7))
                        .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [6, 3]))
                        .annotation(position: .top, alignment: .trailing) {
                            Text("目標 \(goal.targetMinutes)分")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                        }
                }
            }
            .chartXAxis {
                // 期間に応じたX軸ラベルの出し分け
                switch viewModel.selectedPeriod {
                case .week:
                    // 週表示: 曜日の略称（月〜日）を表示
                    AxisMarks(values: .stride(by: .day)) { value in
                        if let date = value.as(Date.self) {
                            AxisValueLabel {
                                Text(Self.weekdayFormatter.string(from: date))
                                    .font(.caption2)
                            }
                        }
                        AxisGridLine()
                    }
                case .month:
                    // 月表示: 7日おきにラベルを表示して重なりを防止（45度回転よりも視認性が高いため）
                    AxisMarks(values: .stride(by: .day, count: 7)) { value in
                        if let date = value.as(Date.self) {
                            AxisValueLabel {
                                Text(date, format: .dateTime.month(.abbreviated).day())
                                    .font(.caption2)
                            }
                        }
                        AxisGridLine()
                    }
                case .day:
                    // 日表示: 日付を月/日形式で表示
                    AxisMarks(values: .stride(by: .day)) { value in
                        if let date = value.as(Date.self) {
                            AxisValueLabel {
                                Text(date, format: .dateTime.month(.defaultDigits).day())
                                    .font(.caption2)
                            }
                        }
                        AxisGridLine()
                    }
                }
            }
            .chartYAxisLabel("分")
            .frame(height: 200)
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    // MARK: - サマリーカードグリッド
    private var summaryCardsSection: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
            ],
            spacing: 12
        ) {
            StatsSummaryCard(
                icon: "clock.fill",
                title: "合計時間",
                value: viewModel.totalTimeFormatted
            )

            // 「平均/日」アイコン: 時計 ÷ カレンダー で「合計時間÷日数」を視覚的に表現
            StatsSummaryCard(
                title: "平均/日",
                value: viewModel.averageTimeFormatted
            ) {
                HStack(spacing: 2) {
                    Image(systemName: "clock.fill")
                    Text("/")
                        .fontWeight(.bold)
                    Image(systemName: "calendar")
                }
            }

            StatsSummaryCard(
                icon: "number.circle.fill",
                title: "セッション数",
                value: "\(viewModel.sessionCount)回"
            )

            StatsSummaryCard(
                icon: "flame.fill",
                title: "連続日数",
                value: "\(viewModel.streakDays)日"
            )
        }
        .padding(.horizontal)
    }

    // MARK: - 円グラフセクション
    private var pieChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("科目別の割合")
                .font(.headline)
                .padding(.horizontal)

            if viewModel.pieChartData.isEmpty {
                // データがない場合の表示
                Text("データがありません")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
            } else {
                // 円グラフ
                Chart(viewModel.pieChartData) { item in
                    SectorMark(
                        angle: .value("時間", item.minutes),
                        innerRadius: .ratio(0.5),
                        angularInset: 2
                    )
                    .foregroundStyle(item.color)
                    .cornerRadius(4)
                }
                .frame(height: 200)
                .padding(.horizontal)

                // 凡例リスト
                legendList
            }
        }
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    // MARK: - 科目別凡例リスト
    private var legendList: some View {
        let totalMinutes = viewModel.pieChartData.reduce(0.0) { $0 + $1.minutes }

        return VStack(spacing: 8) {
            ForEach(viewModel.pieChartData) { item in
                HStack {
                    Circle()
                        .fill(item.color)
                        .frame(width: 10, height: 10)

                    Text(item.subjectName)
                        .font(.subheadline)

                    Spacer()

                    // 学習時間
                    let hours = Int(item.minutes) / 60
                    let mins = Int(item.minutes) % 60
                    if hours > 0 {
                        Text("\(hours)時間\(mins)分")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("\(mins)分")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    // 割合を表示
                    let percentage = totalMinutes > 0
                        ? Int(item.minutes / totalMinutes * 100)
                        : 0
                    Text("\(percentage)%")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color("AccentColor"))
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: - 曜日フォーマッター
    // 週表示のX軸ラベル用（日本語の曜日略称: 月, 火, 水…）
    private static let weekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "E"
        return formatter
    }()
}

// MARK: - プレビュー
#Preview("統計画面") {
    StatsView()
        .modelContainer(try! previewContainer())
}

// MARK: - 30日データプレビュー
#Preview("統計画面（30日データ）") {
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

    // 30日分のセッションデータを生成
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    let subjects = [subjectMath, subjectEnglish, subjectScience]

    for dayOffset in 0..<30 {
        let baseDate = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
        // 1日あたり1〜2セッションをランダムに生成
        let sessionCount = (dayOffset % 3 == 0) ? 2 : 1
        for sessionIndex in 0..<sessionCount {
            let subject = subjects[(dayOffset + sessionIndex) % subjects.count]
            let hour = 9 + sessionIndex * 3
            let startTime = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: baseDate)!
            let durationSeconds = (30 + (dayOffset * 7 + sessionIndex * 13) % 90) * 60
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

    return StatsView()
        .modelContainer(container)
}
