import SwiftUI
import SwiftData
import Charts

// MARK: - 日タブ
// 今日の学習進捗をリングとカードで表示する

/// 日タブ: 進捗リング＋サマリーカード＋ドーナツグラフ
struct DayStatsView: View {

    // MARK: - 外部からの入力
    let sessions: [StudySession]
    let subjects: [Subject]
    let dailyGoals: [DailyGoal]

    // MARK: - ViewModel
    @State private var viewModel = StatsViewModel()

    // MARK: - アニメーション用
    @State private var animatedProgress: Double = 0

    // MARK: - 算出プロパティ

    /// 今日のセッションだけをフィルタリング
    private var todaySessions: [StudySession] {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        let tomorrowStart = calendar.date(byAdding: .day, value: 1, to: todayStart)!
        return sessions.filter { $0.startTime >= todayStart && $0.startTime < tomorrowStart }
    }

    /// 今日の合計学習時間（分）
    private var todayMinutes: Double {
        todaySessions.reduce(0.0) { $0 + $1.durationMinutes }
    }

    /// 目標時間（分）
    private var goalMinutes: Int {
        dailyGoals.first?.targetMinutes ?? 0
    }

    /// 目標が設定されているか
    private var hasGoal: Bool {
        goalMinutes > 0
    }

    /// 達成率（0.0〜）
    private var progress: Double {
        guard hasGoal else { return 0 }
        return todayMinutes / Double(goalMinutes)
    }

    /// リングの色（100%以上で緑に変化）
    private var ringColor: Color {
        if !hasGoal { return .gray }
        return progress >= 1.0 ? .green : Color("AccentColor")
    }

    /// 今日の合計時間フォーマット
    private var todayTimeFormatted: String {
        let totalMins = Int(todayMinutes)
        let hours = totalMins / 60
        let mins = totalMins % 60
        if hours > 0 {
            return "\(hours)時間\(mins)分"
        } else {
            return "\(mins)分"
        }
    }

    /// 達成率のパーセント表示
    private var percentText: String {
        guard hasGoal else { return "—" }
        return "\(Int(progress * 100))%"
    }

    var body: some View {
        VStack(spacing: 24) {
            // MARK: 進捗リング
            progressRingSection

            // MARK: サマリーカード（4カード）
            summaryCardsSection

            // MARK: 科目別ドーナツグラフ
            pieChartSection
        }
        .onAppear {
            viewModel.sessions = sessions
            viewModel.subjects = subjects
            viewModel.selectedPeriod = .day

            // アニメーション: 0%から実際の値へ
            animatedProgress = 0
            withAnimation(.easeOut(duration: 0.8)) {
                animatedProgress = hasGoal ? progress : 0
            }
        }
    }

    // MARK: - 進捗リングセクション

    private var progressRingSection: some View {
        VStack(spacing: 12) {
            GeometryReader { geometry in
                let ringSize = geometry.size.width * 0.6
                let lineWidth: CGFloat = 20

                ZStack {
                    // 背景リング
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: lineWidth)

                    // 進捗リング
                    Circle()
                        .trim(from: 0, to: min(animatedProgress, 1.0))
                        .stroke(
                            ringColor,
                            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.easeOut(duration: 0.8), value: animatedProgress)

                    // 中央テキスト
                    VStack(spacing: 4) {
                        Text(todayTimeFormatted)
                            .font(.title)
                            .fontWeight(.bold)
                        Text(percentText)
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: ringSize, height: ringSize)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(height: UIScreen.main.bounds.width * 0.6)

            // 目標テキスト
            if hasGoal {
                Text("今日の目標：\(goalMinutes)分")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("目標未設定")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
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

    // MARK: - 科目別ドーナツグラフセクション

    private var pieChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("今日の科目別割合")
                .font(.headline)

            if viewModel.pieChartData.isEmpty {
                Text("データなし")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 150)
            } else {
                // ドーナツチャート
                Chart(viewModel.pieChartData) { item in
                    SectorMark(
                        angle: .value("学習時間", item.minutes),
                        innerRadius: .ratio(0.5),
                        angularInset: 1
                    )
                    .foregroundStyle(item.color)
                    .cornerRadius(4)
                }
                .frame(height: 200)

                // 凡例リスト
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(viewModel.pieChartData) { item in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(item.color)
                                .frame(width: 10, height: 10)
                            Text(item.subjectName)
                                .font(.caption)
                            Spacer()
                            Text("\(Int(item.minutes))分")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - プレビュー

/// プレビュー用のヘルパー: サンプルデータ付きDayStatsViewを生成
private struct DayStatsPreview: View {
    let goalMinutes: Int?
    let todayStudyMinutes: Int

    var body: some View {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())

        // 科目を作成
        let math = Subject(name: "数学", color: "#FF5733", icon: "function")
        let english = Subject(name: "英語", color: "#3498DB", icon: "book")

        // 今日のセッションを作成
        let sessions: [StudySession] = {
            guard todayStudyMinutes > 0 else { return [] }
            let halfMinutes = todayStudyMinutes / 2
            let rest = todayStudyMinutes - halfMinutes
            var result: [StudySession] = []
            if halfMinutes > 0 {
                result.append(StudySession(
                    subject: math,
                    startTime: todayStart.addingTimeInterval(3600),
                    endTime: todayStart.addingTimeInterval(3600 + Double(halfMinutes * 60)),
                    durationSeconds: halfMinutes * 60
                ))
            }
            if rest > 0 {
                result.append(StudySession(
                    subject: english,
                    startTime: todayStart.addingTimeInterval(7200),
                    endTime: todayStart.addingTimeInterval(7200 + Double(rest * 60)),
                    durationSeconds: rest * 60
                ))
            }
            return result
        }()

        // 目標を作成
        let goals: [DailyGoal] = {
            guard let mins = goalMinutes else { return [] }
            return [DailyGoal(targetMinutes: mins)]
        }()

        ScrollView {
            DayStatsView(
                sessions: sessions,
                subjects: [math, english],
                dailyGoals: goals
            )
            .padding()
        }
    }
}

#Preview("日タブ（未達成）") {
    DayStatsPreview(goalMinutes: 15, todayStudyMinutes: 3)
}

#Preview("日タブ（達成）") {
    DayStatsPreview(goalMinutes: 15, todayStudyMinutes: 20)
}

#Preview("日タブ（目標未設定）") {
    DayStatsPreview(goalMinutes: nil, todayStudyMinutes: 0)
}
