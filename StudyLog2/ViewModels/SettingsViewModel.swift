import Foundation
import SwiftUI
import SwiftData
import UserNotifications

/// 設定画面のViewModel
/// 科目管理・目標設定・通知設定のロジックを担当する。
@Observable
final class SettingsViewModel {

    // MARK: - 科目管理

    /// 科目追加シートの表示状態
    var showAddSubjectSheet: Bool = false
    /// 科目編集シートの表示状態
    var showEditSubjectSheet: Bool = false
    /// 編集中の科目（nilなら新規追加モード）
    var editingSubject: Subject?

    // MARK: - 科目編集フォームの状態

    /// 科目名の入力値
    var subjectName: String = ""
    /// 選択中のカラーコード
    var subjectColor: String = "#4A90D9"
    /// 選択中のアイコン名
    var subjectIcon: String = "book"

    // MARK: - 目標設定

    /// 日次目標の分数（スライダー値）
    var targetMinutes: Double = 60

    // MARK: - 通知設定

    /// 通知の有効/無効
    var notificationEnabled: Bool = false
    /// 通知時刻
    var notificationTime: Date = Calendar.current.date(
        from: DateComponents(hour: 21, minute: 0)
    ) ?? Date()

    // MARK: - 通知マネージャー参照
    private let notificationManager = NotificationManager.shared

    // MARK: - プリセットカラー

    /// 科目に使用可能なプリセットカラー
    static let presetColors: [(name: String, hex: String)] = [
        ("ブルー", "#4A90D9"),
        ("オレンジ", "#E67E22"),
        ("グリーン", "#2ECC71"),
        ("パープル", "#9B59B6"),
        ("レッド", "#E74C3C"),
        ("ティール", "#1ABC9C"),
        ("イエロー", "#F1C40F"),
        ("ピンク", "#E91E8A"),
        ("インディゴ", "#3F51B5"),
        ("ブラウン", "#795548"),
        ("シアン", "#00BCD4"),
        ("ライム", "#8BC34A"),
    ]

    // MARK: - プリセットアイコン

    /// 科目に使用可能なSFSymbolアイコン
    static let presetIcons: [String] = [
        "book", "book.fill",
        "pencil", "pencil.line",
        "globe", "globe.asia.australia",
        "function", "sum",
        "atom", "bolt",
        "music.note", "paintbrush",
        "theatermasks", "sportscourt",
        "laptopcomputer", "chevron.left.forwardslash.chevron.right",
        "character.book.closed", "text.book.closed",
        "graduationcap", "brain.head.profile",
    ]

    // MARK: - 初期化

    /// DailyGoalの値でViewModelを初期化する
    func loadGoal(_ goal: DailyGoal?) {
        guard let goal else { return }
        targetMinutes = Double(goal.targetMinutes)
        notificationEnabled = goal.notificationEnabled
        notificationTime = goal.notificationTime
    }

    // MARK: - 科目の追加

    /// 新規科目追加用にフォームをリセットする
    func prepareNewSubject() {
        editingSubject = nil
        subjectName = ""
        subjectColor = "#4A90D9"
        subjectIcon = "book"
        showAddSubjectSheet = true
    }

    /// 既存科目の編集用にフォームを設定する
    func prepareEditSubject(_ subject: Subject) {
        editingSubject = subject
        subjectName = subject.name
        subjectColor = subject.color
        subjectIcon = subject.icon
        showAddSubjectSheet = true
    }

    /// フォームの入力値で科目を保存する（新規追加または更新）
    /// - Parameter context: SwiftDataのModelContext
    func saveSubject(context: ModelContext) {
        guard !subjectName.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        if let existing = editingSubject {
            // 既存科目の更新
            existing.name = subjectName.trimmingCharacters(in: .whitespaces)
            existing.color = subjectColor
            existing.icon = subjectIcon
        } else {
            // 新規科目の作成
            let newSubject = Subject(
                name: subjectName.trimmingCharacters(in: .whitespaces),
                color: subjectColor,
                icon: subjectIcon
            )
            context.insert(newSubject)
        }

        showAddSubjectSheet = false
        editingSubject = nil
    }

    /// 科目を削除する
    /// - Parameters:
    ///   - subject: 削除対象の科目
    ///   - context: SwiftDataのModelContext
    func deleteSubject(_ subject: Subject, context: ModelContext) {
        context.delete(subject)
    }

    /// IndexSetで指定された科目を削除する（スワイプ削除用）
    /// - Parameters:
    ///   - offsets: 削除対象のインデックス
    ///   - subjects: 科目配列
    ///   - context: SwiftDataのModelContext
    func deleteSubjects(at offsets: IndexSet, from subjects: [Subject], context: ModelContext) {
        for index in offsets {
            context.delete(subjects[index])
        }
    }

    // MARK: - 目標設定

    /// 目標分数を更新してDailyGoalに反映する
    /// - Parameter goal: 更新対象のDailyGoal
    func updateTargetMinutes(_ goal: DailyGoal) {
        goal.targetMinutes = Int(targetMinutes)
    }

    /// 目標時間を「◯時間◯分」形式で取得する
    var formattedTarget: String {
        let minutes = Int(targetMinutes)
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 && mins > 0 {
            return "\(hours)時間\(mins)分"
        } else if hours > 0 {
            return "\(hours)時間"
        } else {
            return "\(mins)分"
        }
    }

    // MARK: - 通知設定

    /// 通知許可をリクエストし、トグルの状態を更新する
    @MainActor
    func requestNotificationPermission() async {
        let granted = await notificationManager.requestPermission()
        if !granted {
            // 許可が得られなかった場合はトグルをオフに戻す
            notificationEnabled = false
        }
    }

    /// 目標達成通知をスケジュールする
    /// - Parameter goalMinutes: 目標分数
    func scheduleGoalNotification(goalMinutes: Int) {
        notificationManager.scheduleGoalAchievedNotification(goalMinutes: goalMinutes)
    }

    /// リマインダー通知のスケジュール/キャンセルを切り替える
    /// - Parameter goal: 対象のDailyGoal
    func updateNotificationSettings(_ goal: DailyGoal) {
        goal.notificationEnabled = notificationEnabled
        goal.notificationTime = notificationTime

        if notificationEnabled {
            notificationManager.scheduleDailyReminder(at: notificationTime)
        } else {
            notificationManager.cancelDailyReminder()
        }
    }

    /// すべての通知をキャンセルする
    func cancelNotifications() {
        notificationManager.cancelAll()
    }

    // MARK: - ヘルパー

    /// 16進カラーコードからColorを生成する
    static func color(from hex: String) -> Color {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let red = Double((rgb & 0xFF0000) >> 16) / 255.0
        let green = Double((rgb & 0x00FF00) >> 8) / 255.0
        let blue = Double(rgb & 0x0000FF) / 255.0

        return Color(red: red, green: green, blue: blue)
    }
}
