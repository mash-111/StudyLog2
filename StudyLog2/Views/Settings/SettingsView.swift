import SwiftUI
import SwiftData
import Combine

/// 設定画面
/// 科目管理・目標設定・通知設定・アプリ情報を表示する。
struct SettingsView: View {

    // MARK: - 依存関係
    @State private var viewModel = SettingsViewModel()
    @Environment(\.modelContext) private var modelContext

    /// 通知が拒否されている場合に設定アプリへ誘導するアラートの表示状態
    @State private var showDeniedAlert = false

    /// SwiftDataから科目一覧を取得
    @Query(sort: \Subject.name) private var subjects: [Subject]
    /// SwiftDataから日次目標を取得（最初の1件を使用）
    @Query private var dailyGoals: [DailyGoal]

    // スワイプ削除ボタンのリセット対策
    // 方法3を採用: List に .id() を付与し、タブ切り替え時（onDisappear）に
    // IDを再生成して強制リフレッシュする。
    // 理由: onChange(of: selectedTab) は親Viewの selectedTab を参照する必要があり
    // コンポーネントの独立性が下がる。.onDisappear + id 再生成が最もSwiftUIらしい。
    @State private var listId = UUID()

    /// 現在の日次目標（なければデフォルト値で作成）
    private var currentGoal: DailyGoal? {
        dailyGoals.first
    }

    // MARK: - ビュー本体
    var body: some View {
        NavigationStack {
            List {
                subjectManagementSection
                goalSettingsSection
                notificationSettingsSection
                aboutSection
            }
            .id(listId)
            .navigationTitle("設定")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    EditButton()
                }
            }
            // 科目追加・編集シート
            .sheet(isPresented: $viewModel.showAddSubjectSheet) {
                SubjectEditView(viewModel: viewModel)
            }
            // 通知が拒否されている場合に設定アプリへの誘導アラート
            .alert("通知が許可されていません", isPresented: $showDeniedAlert) {
                Button("設定を開く") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("キャンセル", role: .cancel) {}
            } message: {
                Text("設定アプリ → StudyLog2 → 通知 からONにしてください")
            }
            .onAppear {
                // DailyGoalがなければ作成
                if dailyGoals.isEmpty {
                    let goal = DailyGoal()
                    modelContext.insert(goal)
                }
                // ViewModelにDailyGoalの値を反映
                viewModel.loadGoal(currentGoal)

                // 通知許可状態を確認し、トグルを実際の状態に同期
                Task {
                    await viewModel.checkNotificationStatus()
                    // .authorized でなければトグルをOFFに同期
                    if viewModel.notificationAuthStatus != .authorized {
                        viewModel.notificationEnabled = false
                    }
                }
            }
            // 設定アプリから戻った際の通知許可状態の再同期
            // .onAppear はバックグラウンド→フォアグラウンド復帰時に発火しないケースがあるため、
            // didBecomeActiveNotification を監視してアプリ復帰のたびに許可状態を再チェックする。
            // 動作の流れ:
            // 1. ユーザーが設定アプリで通知を許可する
            // 2. アプリに戻ると didBecomeActiveNotification が発火
            // 3. checkNotificationStatus() で最新の許可状態を取得
            // 4. .authorized ならトグルをONに同期、.denied ならOFFに同期
            .onReceive(
                NotificationCenter.default.publisher(
                    for: UIApplication.didBecomeActiveNotification
                )
            ) { _ in
                Task {
                    await viewModel.checkNotificationStatus()
                    viewModel.notificationEnabled = viewModel.notificationAuthStatus == .authorized
                        && (currentGoal?.notificationEnabled ?? false)
                }
            }
            .onDisappear {
                listId = UUID()
            }
        }
    }

    // MARK: - 科目管理セクション

    /// 科目の一覧表示と追加・削除機能
    private var subjectManagementSection: some View {
        Section {
            ForEach(subjects) { subject in
                subjectRow(subject)
            }
            .onDelete { offsets in
                viewModel.deleteSubjects(at: offsets, from: subjects, context: modelContext)
            }

            // 科目追加ボタン
            Button {
                viewModel.prepareNewSubject()
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(Color("AccentColor"))
                    Text("科目を追加")
                }
            }
        } header: {
            Text("科目管理")
        } footer: {
            Text("スワイプで削除、タップで編集できます")
        }
    }

    /// 科目行の表示
    private func subjectRow(_ subject: Subject) -> some View {
        Button {
            viewModel.prepareEditSubject(subject)
        } label: {
            HStack(spacing: 12) {
                // 科目カラーアイコン
                ZStack {
                    Circle()
                        .fill(SettingsViewModel.color(from: subject.color))
                        .frame(width: 32, height: 32)

                    Image(systemName: subject.icon)
                        .font(.system(size: 14))
                        .foregroundStyle(.white)
                }

                Text(subject.name)
                    .font(.body)
                    .foregroundStyle(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - 目標設定セクション

    /// 日次目標時間をスライダーで設定する
    private var goalSettingsSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("1日の目標")
                        .font(.body)
                    Spacer()
                    Text(viewModel.formattedTarget)
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color("AccentColor"))
                }

                // 0〜480分（8時間）のスライダー、15分刻み
                Slider(
                    value: $viewModel.targetMinutes,
                    in: 0...480,
                    step: 15
                )
                .tint(Color("AccentColor"))
                .onChange(of: viewModel.targetMinutes) {
                    // DailyGoalに反映
                    if let goal = currentGoal {
                        viewModel.updateTargetMinutes(goal)
                    }
                }
            }
            .padding(.vertical, 4)
        } header: {
            Text("目標設定")
        } footer: {
            Text("目標を設定すると、統計画面で達成率が確認できます")
        }
    }

    // MARK: - 通知設定セクション

    /// 通知のON/OFFと通知時刻を設定する
    private var notificationSettingsSection: some View {
        Section {
            // 通知トグル
            Toggle(isOn: $viewModel.notificationEnabled) {
                HStack {
                    Image(systemName: "bell.fill")
                        .foregroundStyle(Color("AccentColor"))
                        .frame(width: 24)
                    VStack(alignment: .leading) {
                        Text("学習リマインダー")
                        Text("毎日指定時刻にリマインド")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .tint(Color("AccentColor"))
            .onChange(of: viewModel.notificationEnabled) { _, newValue in
                if newValue {
                    // 通知ON時：許可状態に応じて処理を分岐
                    switch viewModel.notificationAuthStatus {
                    case .denied:
                        // 拒否済み：アラートを表示してトグルを戻す
                        viewModel.notificationEnabled = false
                        showDeniedAlert = true
                    case .notDetermined:
                        // 未決定：通常の許可リクエスト
                        Task {
                            await viewModel.requestNotificationPermission()
                            if let goal = currentGoal {
                                viewModel.updateNotificationSettings(goal)
                            }
                        }
                    case .authorized, .provisional, .ephemeral:
                        // 許可済み：通知設定を更新
                        if let goal = currentGoal {
                            viewModel.updateNotificationSettings(goal)
                        }
                    @unknown default:
                        break
                    }
                } else {
                    // 通知OFF時にキャンセル
                    if let goal = currentGoal {
                        viewModel.updateNotificationSettings(goal)
                    }
                }
            }

            // 通知時刻ピッカー（通知が有効な場合のみ表示）
            if viewModel.notificationEnabled {
                DatePicker(
                    "通知時刻",
                    selection: $viewModel.notificationTime,
                    displayedComponents: .hourAndMinute
                )
                .onChange(of: viewModel.notificationTime) {
                    // 時刻変更時にリマインダーを再スケジュール
                    if let goal = currentGoal {
                        viewModel.updateNotificationSettings(goal)
                    }
                }
            }
        } header: {
            Text("通知設定")
        }
    }

    // MARK: - アプリについてセクション

    /// バージョン情報などを表示する
    private var aboutSection: some View {
        Section {
            HStack {
                Text("バージョン")
                Spacer()
                Text(appVersion)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("アプリについて")
        }
    }

    // MARK: - ヘルパー

    /// アプリのバージョン文字列を取得する
    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}

// MARK: - プレビュー
#Preview("設定画面") {
    SettingsView()
        .modelContainer(try! previewContainer())
        .tint(Color("AccentColor"))
}
