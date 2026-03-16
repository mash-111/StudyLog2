import SwiftUI
import SwiftData

/// ホーム画面
/// タイマー操作と今日の学習サマリーを表示するメイン画面
struct HomeView: View {

    // MARK: - データ

    @Environment(\.modelContext) private var modelContext

    /// 全科目を取得
    @Query(sort: \Subject.name) private var subjects: [Subject]

    /// 今日の学習セッションを取得
    @Query private var todaySessions: [StudySession]

    /// 日次目標を取得
    @Query private var dailyGoals: [DailyGoal]

    /// タイマーのViewModel
    @State private var timerVM = TimerViewModel()

    /// パルスアニメーション用の状態
    @State private var isPulsing: Bool = false
    /// ボタンタップアニメーション用の状態
    @State private var buttonScale: CGFloat = 1.0
    /// 前回の目標達成率（目標達成検知用）
    @State private var previousGoalProgress: Int = 0

    // MARK: - 初期化

    init() {
        // 今日の開始時刻でフィルタリング
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let predicate = #Predicate<StudySession> { session in
            session.startTime >= startOfDay
        }
        _todaySessions = Query(filter: predicate, sort: \StudySession.startTime, order: .reverse)
    }

    // MARK: - 計算プロパティ

    /// 今日の合計学習時間（秒）
    private var totalSecondsToday: Int {
        todaySessions.reduce(0) { $0 + $1.durationSeconds }
    }

    /// 今日の合計学習時間（フォーマット済み）
    private var formattedTotalTime: String {
        let hours = totalSecondsToday / 3600
        let minutes = (totalSecondsToday % 3600) / 60
        if hours > 0 {
            return "\(hours)時間\(minutes)分"
        } else {
            return "\(minutes)分"
        }
    }

    /// 今日のセッション数
    private var sessionCount: Int {
        todaySessions.count
    }

    /// 目標達成率（パーセント）
    private var goalProgress: Int {
        guard let goal = dailyGoals.first, goal.targetMinutes > 0 else {
            return 0
        }
        let totalMinutes = Double(totalSecondsToday) / 60.0
        let progress = totalMinutes / Double(goal.targetMinutes) * 100
        return min(Int(progress), 100)
    }

    /// 目標達成の進捗（0.0〜1.0）
    private var goalProgressRatio: CGFloat {
        guard let goal = dailyGoals.first, goal.targetMinutes > 0 else {
            return 0
        }
        let totalMinutes = Double(totalSecondsToday) / 60.0
        return min(CGFloat(totalMinutes / Double(goal.targetMinutes)), 1.0)
    }

    // MARK: - ビュー本体

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if subjects.isEmpty {
                        // 科目が未登録の場合の空状態表示
                        emptySubjectsView
                    } else {
                        // 科目選択セクション
                        VStack(spacing: 4) {
                            SubjectPickerView(
                                subjects: subjects,
                                selectedSubject: $timerVM.selectedSubject
                            )
                            // 計測中は科目変更を無効化
                            .disabled(timerVM.isRunning)
                            .opacity(timerVM.isRunning ? 0.4 : 1.0)
                            .animation(.easeInOut(duration: 0.2), value: timerVM.isRunning)

                            // 計測中の案内メッセージ
                            if timerVM.isRunning {
                                Text("計測中は変更できません")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        // タイマーセクション
                        timerSection

                        // 今日の学習サマリー
                        summarySection

                        // 直近のセッション
                        recentSessionsSection
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("StudyLog")
            .navigationBarTitleDisplayMode(.large)
            // 目標達成時の触覚フィードバック
            .onChange(of: goalProgress) { oldValue, newValue in
                if newValue >= 100 && oldValue < 100 {
                    timerVM.notifyGoalAchieved()
                }
            }
        }
    }

    // MARK: - 科目未登録時の空状態ビュー

    /// 科目がまだ登録されていないときに表示するビュー
    private var emptySubjectsView: some View {
        VStack(spacing: 16) {
            Spacer()
                .frame(height: 60)

            Image(systemName: "books.vertical.fill")
                .font(.system(size: 64))
                .foregroundStyle(Color("AccentColor"))

            Text("科目を追加しましょう")
                .font(.title2)
                .fontWeight(.bold)

            Text("「設定」タブから学習する科目を\n追加してタイマーを始めましょう")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Spacer()
                .frame(height: 20)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 32)
    }

    // MARK: - タイマーセクション

    private var timerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                // 背景リング
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 8)
                    .frame(width: 220, height: 220)

                // 進捗リング（目標達成率に基づく）
                Circle()
                    .trim(from: 0, to: goalProgressRatio)
                    .stroke(
                        Color("AccentColor"),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 220, height: 220)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: goalProgressRatio)

                // タイマー時間表示
                VStack(spacing: 4) {
                    Text(timerVM.formattedTime)
                        .font(.system(size: 48, weight: .light, design: .monospaced))
                        .foregroundStyle(.primary)
                        // タイマー動作中のパルスアニメーション
                        .scaleEffect(isPulsing ? 1.03 : 1.0)

                    if let subject = timerVM.selectedSubject {
                        Text(subject.name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("科目を選択してください")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            // タイマー開始・停止時のスケールアニメーション
            .scaleEffect(timerVM.isRunning ? 1.0 : 0.95)
            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: timerVM.isRunning)
            .padding(.vertical, 8)
            // パルスアニメーションの制御
            .onChange(of: timerVM.isRunning) { _, newValue in
                if newValue {
                    withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                        isPulsing = true
                    }
                } else {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isPulsing = false
                    }
                }
            }

            // タイマー操作ボタン
            timerButtons
        }
    }

    // MARK: - タイマー操作ボタン

    private var timerButtons: some View {
        HStack(spacing: 20) {
            if timerVM.isRunning {
                // 停止ボタン
                Button {
                    timerVM.stop(modelContext: modelContext)
                } label: {
                    Image(systemName: "stop.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                        .background(Color.red)
                        .clipShape(Circle())
                }
                .buttonStyle(ScaleButtonStyle())

                // 一時停止 / 再開ボタン
                Button {
                    if timerVM.isPaused {
                        timerVM.resume()
                    } else {
                        timerVM.pause()
                    }
                } label: {
                    Image(systemName: timerVM.isPaused ? "play.fill" : "pause.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                        .background(Color("AccentColor"))
                        .clipShape(Circle())
                }
                .buttonStyle(ScaleButtonStyle())
            } else {
                // 開始ボタン
                Button {
                    timerVM.start()
                } label: {
                    Image(systemName: "play.fill")
                        .font(.title)
                        .foregroundStyle(.white)
                        .frame(width: 72, height: 72)
                        .background(
                            timerVM.selectedSubject != nil
                                ? Color("AccentColor")
                                : Color(.systemGray3)
                        )
                        .clipShape(Circle())
                }
                .buttonStyle(ScaleButtonStyle())
                .disabled(timerVM.selectedSubject == nil)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: timerVM.isRunning)
    }

    // MARK: - 今日の学習サマリーセクション

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("今日の学習")
                .font(.headline)

            HStack(spacing: 12) {
                // 合計学習時間
                SummaryCardView(
                    icon: "clock.fill",
                    title: "合計時間",
                    value: formattedTotalTime
                )

                // セッション回数
                SummaryCardView(
                    icon: "number",
                    title: "セッション",
                    value: "\(sessionCount)回"
                )

                // 目標達成率
                SummaryCardView(
                    icon: "target",
                    title: "達成率",
                    value: "\(goalProgress)%"
                )
            }
        }
        .padding(.horizontal)
    }

    // MARK: - 直近のセッション一覧

    private var recentSessionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("直近のセッション")
                .font(.headline)

            if todaySessions.isEmpty {
                // セッションがない場合のプレースホルダー
                Text("今日の学習記録はまだありません")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                // 直近3件のセッションを表示
                ForEach(todaySessions.prefix(3), id: \.id) { session in
                    RecentSessionRow(session: session)
                }
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - サマリーカードコンポーネント

/// 今日の学習サマリーに使用するカード
struct SummaryCardView: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color("AccentColor"))

            Text(value)
                .font(.headline)
                .fontWeight(.bold)

            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - 直近セッション行コンポーネント

/// 直近の学習セッションを1行で表示する
private struct RecentSessionRow: View {

    let session: StudySession

    /// セッションの学習時間（フォーマット済み）
    private var formattedDuration: String {
        let minutes = session.durationSeconds / 60
        if minutes >= 60 {
            return "\(minutes / 60)時間\(minutes % 60)分"
        } else {
            return "\(minutes)分"
        }
    }

    /// セッションの時間帯（フォーマット済み）
    private var formattedTimeRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let start = formatter.string(from: session.startTime)
        let end = formatter.string(from: session.endTime)
        return "\(start)〜\(end)"
    }

    /// 科目のカラー
    private var subjectColor: Color {
        if let hex = session.subject?.color {
            return Color(hex: hex)
        }
        return Color("AccentColor")
    }

    var body: some View {
        HStack {
            // 科目アイコン
            Circle()
                .fill(subjectColor.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay {
                    Image(systemName: session.subject?.icon ?? "book.fill")
                        .foregroundStyle(subjectColor)
                }

            // 科目名と学習時間
            VStack(alignment: .leading) {
                Text(session.subject?.name ?? "不明")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(formattedDuration)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // 時間帯
            Text(formattedTimeRange)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - ボタンタップ時のスケールエフェクト

/// タップ時に縮小するボタンスタイル
private struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - プレビュー

#Preview("ホーム画面") {
    HomeView()
        .modelContainer(try! previewContainer())
        .tint(Color("AccentColor"))
}
