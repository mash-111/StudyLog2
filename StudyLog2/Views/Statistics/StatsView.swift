import SwiftUI
import SwiftData
import Charts

// MARK: - 統計画面
// 学習データをグラフと数値で可視化するメイン画面
// タブごとに DayStatsView / WeekStatsView / MonthStatsView に分離

/// 統計画面: 期間タブを切り替えて各タブのビューを表示する
struct StatsView: View {

    // MARK: - データ取得
    @Query private var sessions: [StudySession]
    @Query private var subjects: [Subject]
    @Query private var dailyGoals: [DailyGoal]

    // MARK: - 選択中の期間タブ
    @State private var selectedPeriod: StatsPeriod = .week

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

                        // MARK: - タブごとのコンテンツ
                        switch selectedPeriod {
                        case .day:
                            DayStatsView(
                                sessions: sessions,
                                subjects: subjects,
                                dailyGoals: dailyGoals
                            )
                        case .week:
                            WeekStatsView(
                                sessions: sessions,
                                subjects: subjects
                            )
                        case .month:
                            MonthStatsView(
                                sessions: sessions,
                                subjects: subjects
                            )
                        }
                    }
                    .padding(.vertical)
                }
                .navigationTitle("統計")
            }
        }
    }

    // MARK: - セッション未記録時の空状態ビュー
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
        Picker("表示期間", selection: $selectedPeriod) {
            ForEach(StatsPeriod.allCases, id: \.self) { period in
                Text(period.rawValue).tag(period)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
    }
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
