import SwiftUI

// MARK: - 設定画面スケッチ
// 科目管理・目標設定・アプリ設定を行う画面
//
// レイアウト構成:
// ┌─────────────────────────┐
// │ ナビゲーションバー       │
// │ 「設定」                │
// ├─────────────────────────┤
// │ セクション: 科目管理     │
// │ ├ 数学                  │
// │ ├ 英語                  │
// │ ├ 物理                  │
// │ └ [+ 科目を追加]        │
// ├─────────────────────────┤
// │ セクション: 学習目標     │
// │ ├ 1日の目標時間: 3時間  │
// │ └ 週間目標: 15時間      │
// ├─────────────────────────┤
// │ セクション: 通知         │
// │ ├ リマインダー: ON      │
// │ └ 目標達成通知: ON      │
// ├─────────────────────────┤
// │ セクション: その他       │
// │ ├ ダークモード          │
// │ ├ データエクスポート     │
// │ └ バージョン情報        │
// └─────────────────────────┘
//
// 設計意図:
// - List + Section でiOS標準の設定画面パターンに合わせる
// - 科目管理では追加・削除・並び替えが可能（将来実装）
// - 目標設定はスライダーやステッパーで直感的に操作
// - UserNotificationsと連携してリマインダー機能を提供（将来実装）

/// 設定画面: 科目管理、目標設定、通知設定、その他の設定
struct SettingsSketch: View {

    // MARK: - 状態管理
    /// 科目一覧（編集可能）
    @State private var subjects = ["数学", "英語", "物理", "国語", "化学"]
    /// 1日の目標学習時間（時間単位）
    @State private var dailyGoalHours: Double = 3.0
    /// 週間の目標学習時間（時間単位）
    @State private var weeklyGoalHours: Double = 15.0
    /// リマインダー通知のON/OFF
    @State private var isReminderEnabled = true
    /// 目標達成通知のON/OFF
    @State private var isGoalNotificationEnabled = true
    /// 科目追加シートの表示状態
    @State private var showAddSubjectSheet = false
    /// 新しい科目名の入力テキスト
    @State private var newSubjectName = ""

    // MARK: - ビュー本体
    var body: some View {
        List {

            // MARK: - 科目管理セクション
            // 学習に使用する科目の追加・削除・並び替え
            // NavigationLinkで科目の詳細設定画面に遷移可能（将来実装）
            Section {
                ForEach(subjects, id: \.self) { subject in
                    HStack {
                        // 科目カラーインジケーター
                        Circle()
                            .fill(Color("AccentColor"))
                            .frame(width: 10, height: 10)

                        Text(subject)
                            .font(.body)

                        Spacer()

                        // 詳細遷移アイコン（将来NavigationLinkに変更）
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                // スワイプで科目を削除（将来実装のためダミー）
                .onDelete { indexSet in
                    subjects.remove(atOffsets: indexSet)
                }
                // ドラッグで並び替え（将来実装のためダミー）
                .onMove { from, to in
                    subjects.move(fromOffsets: from, toOffset: to)
                }

                // 科目追加ボタン
                Button {
                    showAddSubjectSheet = true
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
                Text("スワイプで削除、長押しで並び替えができます")
            }

            // MARK: - 学習目標セクション
            // 1日の目標と週間の目標をスライダーで設定
            // 目標値は通知や統計画面での達成率計算に使用する
            Section {
                // 1日の目標学習時間
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("1日の目標")
                            .font(.body)
                        Spacer()
                        Text("\(Int(dailyGoalHours))時間")
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color("AccentColor"))
                    }

                    // スライダーで0.5時間〜8時間の範囲で設定
                    Slider(
                        value: $dailyGoalHours,
                        in: 0.5...8.0,
                        step: 0.5
                    )
                    .tint(Color("AccentColor"))
                }
                .padding(.vertical, 4)

                // 週間の目標学習時間
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("週間の目標")
                            .font(.body)
                        Spacer()
                        Text("\(Int(weeklyGoalHours))時間")
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color("AccentColor"))
                    }

                    // スライダーで1時間〜40時間の範囲で設定
                    Slider(
                        value: $weeklyGoalHours,
                        in: 1...40,
                        step: 1
                    )
                    .tint(Color("AccentColor"))
                }
                .padding(.vertical, 4)
            } header: {
                Text("学習目標")
            } footer: {
                Text("目標を設定すると、統計画面で達成率が確認できます")
            }

            // MARK: - 通知設定セクション
            // UserNotificationsを使ったリマインダーと目標達成通知
            // トグルでON/OFFを切り替え
            Section {
                // 学習リマインダー（毎日指定時刻に通知）
                Toggle(isOn: $isReminderEnabled) {
                    HStack {
                        Image(systemName: "bell.fill")
                            .foregroundStyle(Color("AccentColor"))
                            .frame(width: 24)
                        VStack(alignment: .leading) {
                            Text("学習リマインダー")
                            Text("毎日の学習開始をリマインド")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .tint(Color("AccentColor"))

                // 目標達成通知（1日の目標を達成したら通知）
                Toggle(isOn: $isGoalNotificationEnabled) {
                    HStack {
                        Image(systemName: "trophy.fill")
                            .foregroundStyle(Color("AccentColor"))
                            .frame(width: 24)
                        VStack(alignment: .leading) {
                            Text("目標達成通知")
                            Text("1日の目標を達成したらお知らせ")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .tint(Color("AccentColor"))
            } header: {
                Text("通知")
            }

            // MARK: - その他セクション
            // データ管理やアプリ情報
            Section {
                // データエクスポート（将来実装）
                // CSV形式で学習データを書き出す機能を想定
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(Color("AccentColor"))
                        .frame(width: 24)
                    Text("データをエクスポート")
                }

                // すべてのデータをリセット（確認ダイアログ付き）
                HStack {
                    Image(systemName: "trash")
                        .foregroundStyle(.red)
                        .frame(width: 24)
                    Text("すべてのデータをリセット")
                        .foregroundStyle(.red)
                }
            } header: {
                Text("データ管理")
            }

            // MARK: - アプリ情報セクション
            Section {
                HStack {
                    Text("バージョン")
                    Spacer()
                    Text("1.0.0")
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("アプリ情報")
            }
        }
        .navigationTitle("設定")
        // 科目管理の編集モードを有効にする
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                EditButton()
            }
        }
        // MARK: - 科目追加シート
        // 新しい科目名を入力して追加するモーダルシート
        .sheet(isPresented: $showAddSubjectSheet) {
            NavigationStack {
                Form {
                    TextField("科目名を入力", text: $newSubjectName)
                }
                .navigationTitle("科目を追加")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("キャンセル") {
                            newSubjectName = ""
                            showAddSubjectSheet = false
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("追加") {
                            if !newSubjectName.isEmpty {
                                subjects.append(newSubjectName)
                                newSubjectName = ""
                            }
                            showAddSubjectSheet = false
                        }
                        .disabled(newSubjectName.isEmpty)
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }
}

// MARK: - プレビュー
#Preview("設定画面") {
    NavigationStack {
        SettingsSketch()
    }
    .tint(Color("AccentColor"))
}
