import Foundation
import SwiftUI
import SwiftData
import Combine
import UIKit

/// タイマーのViewModel
/// 学習タイマーの状態管理とセッション保存を担当する
@MainActor
@Observable
final class TimerViewModel {

    // MARK: - タイマー状態

    /// 選択中の科目
    var selectedSubject: Subject?
    /// タイマーが動作中かどうか
    var isRunning: Bool = false
    /// タイマーが一時停止中かどうか
    var isPaused: Bool = false
    /// 経過秒数
    var elapsedSeconds: Int = 0

    /// タイマー開始時刻（セッション保存用）
    private var startTime: Date?
    /// バックグラウンド移行時刻（バックグラウンド経過時間の補正用）
    private var backgroundEnteredTime: Date?
    /// Timer.publishのキャンセル用
    @ObservationIgnored
    private var timerCancellable: AnyCancellable?
    /// バックグラウンド通知のオブザーバー保持用
    @ObservationIgnored
    private var backgroundObservers: [NSObjectProtocol] = []

    // MARK: - 初期化・解放

    init() {
        setupBackgroundObservers()
    }

    deinit {
        backgroundObservers.forEach { NotificationCenter.default.removeObserver($0) }
    }

    // MARK: - フォーマット済み時間文字列

    /// 経過時間を HH:MM:SS 形式で返す
    var formattedTime: String {
        let hours = elapsedSeconds / 3600
        let minutes = (elapsedSeconds % 3600) / 60
        let seconds = elapsedSeconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    // MARK: - タイマー操作

    /// タイマーを開始する
    /// - 科目が未選択の場合は何もしない
    func start() {
        guard selectedSubject != nil else { return }
        guard !isRunning else { return }

        isRunning = true
        isPaused = false
        elapsedSeconds = 0
        startTime = Date()

        // 開始時の触覚フィードバック
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        // 画面スリープを防止
        UIApplication.shared.isIdleTimerDisabled = true

        startTimer()
    }

    /// タイマーを一時停止する
    func pause() {
        guard isRunning, !isPaused else { return }

        isPaused = true
        stopTimer()

        // 一時停止時の触覚フィードバック
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }

    /// タイマーを再開する
    func resume() {
        guard isRunning, isPaused else { return }

        isPaused = false
        startTimer()

        // 再開時の触覚フィードバック
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }

    /// タイマーを停止し、学習セッションを保存する
    /// - Parameter modelContext: SwiftDataのモデルコンテキスト
    func stop(modelContext: ModelContext) {
        guard isRunning else { return }
        guard let subject = selectedSubject, let startTime = startTime else { return }

        let endTime = Date()
        let duration = elapsedSeconds

        // 学習セッションを作成・保存（1秒以上の場合のみ）
        if duration > 0 {
            let session = StudySession(
                subject: subject,
                startTime: startTime,
                endTime: endTime,
                durationSeconds: duration
            )
            modelContext.insert(session)

            // 目標達成通知のチェック
            checkGoalAchievement(
                addedDuration: duration,
                modelContext: modelContext
            )
        }

        // 停止時の触覚フィードバック（重め）
        let impact = UIImpactFeedbackGenerator(style: .heavy)
        impact.impactOccurred()

        // 状態をリセット
        isRunning = false
        isPaused = false
        elapsedSeconds = 0
        self.startTime = nil
        stopTimer()

        // 画面スリープ防止を解除
        UIApplication.shared.isIdleTimerDisabled = false
    }

    // MARK: - 触覚フィードバック

    /// 目標達成時の成功フィードバック
    func notifyGoalAchieved() {
        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(.success)
    }

    // MARK: - 目標達成チェック

    /// 今日の学習時間が目標を超えたかチェックし、通知を送る
    private func checkGoalAchievement(addedDuration: Int, modelContext: ModelContext) {
        // DailyGoalを取得
        let goalDescriptor = FetchDescriptor<DailyGoal>()
        guard let goals = try? modelContext.fetch(goalDescriptor),
              let goal = goals.first,
              goal.targetMinutes > 0 else { return }

        // 今日のセッションを取得
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let sessionDescriptor = FetchDescriptor<StudySession>(
            predicate: #Predicate<StudySession> { session in
                session.startTime >= startOfDay
            }
        )
        guard let todaySessions = try? modelContext.fetch(sessionDescriptor) else { return }

        let totalSecondsToday = todaySessions.reduce(0) { $0 + $1.durationSeconds }
        let totalMinutesToday = Double(totalSecondsToday) / 60.0
        let previousMinutes = Double(totalSecondsToday - addedDuration) / 60.0
        let targetMinutes = Double(goal.targetMinutes)

        // 今回のセッションで目標を達成した場合のみ通知（以前から達成済みなら通知しない）
        if totalMinutesToday >= targetMinutes && previousMinutes < targetMinutes {
            NotificationManager.shared.scheduleGoalAchievedNotification(goalMinutes: goal.targetMinutes)
            notifyGoalAchieved()
        }
    }

    // MARK: - バックグラウンド対応

    /// バックグラウンド／フォアグラウンド移行の通知を登録する
    private func setupBackgroundObservers() {
        let resignObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.handleEnterBackground()
            }
        }

        let activeObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.handleEnterForeground()
            }
        }

        backgroundObservers = [resignObserver, activeObserver]
    }

    /// バックグラウンド移行時：移行時刻を記録してタイマーを停止する
    private func handleEnterBackground() {
        guard isRunning, !isPaused else { return }
        backgroundEnteredTime = Date()
        stopTimer()
    }

    /// フォアグラウンド復帰時：バックグラウンドにいた時間を経過秒数に加算してタイマーを再開する
    private func handleEnterForeground() {
        guard isRunning, !isPaused, let backgroundTime = backgroundEnteredTime else { return }
        let elapsed = Int(Date().timeIntervalSince(backgroundTime))
        elapsedSeconds += elapsed
        backgroundEnteredTime = nil
        startTimer()
    }

    // MARK: - プレビュー用ヘルパー

    /// プレビュー用に計測中状態のViewModelを生成する
    /// - Parameter subject: 選択する科目
    /// - Returns: isRunning=trueの状態のTimerViewModel
    static func previewRunning(subject: Subject) -> TimerViewModel {
        let vm = TimerViewModel()
        vm.selectedSubject = subject
        vm.isRunning = true
        vm.elapsedSeconds = 125  // 2分5秒経過のサンプル表示
        return vm
    }

    // MARK: - プライベートヘルパー

    /// 1秒ごとに経過秒数をインクリメントするタイマーを開始
    private func startTimer() {
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.elapsedSeconds += 1
            }
    }

    /// タイマーを停止
    private func stopTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }
}
