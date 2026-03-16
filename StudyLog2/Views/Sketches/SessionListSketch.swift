import SwiftUI

// MARK: - 記録一覧画面スケッチ
// 過去の学習セッションをリスト形式で表示する画面
//
// レイアウト構成:
// ┌─────────────────────────┐
// │ ナビゲーションバー       │
// │ 「学習記録」+ フィルター │
// ├─────────────────────────┤
// │ 検索バー                │
// ├─────────────────────────┤
// │ 日付セクションヘッダー   │
// │ 「今日 - 3月16日」      │
// ├─────────────────────────┤
// │ [●] 数学  45分  10:00  │
// │ [●] 英語  30分  11:00  │
// ├─────────────────────────┤
// │ 「昨日 - 3月15日」      │
// ├─────────────────────────┤
// │ [●] 物理  1h   09:00   │
// │ [●] 国語  25分  14:00  │
// └─────────────────────────┘
//
// 設計意図:
// - 日付ごとにセクション分けして時系列を把握しやすくする
// - 科目のカラーインジケーターで視覚的に区別
// - スワイプで削除・編集が可能（将来実装）
// - 検索バーで科目名やメモでの絞り込みが可能

/// 学習記録一覧画面: 過去のセッションを日付ごとにグループ化して表示
struct SessionListSketch: View {

    // MARK: - 状態管理
    /// 検索テキスト
    @State private var searchText = ""
    /// フィルターに使用する科目（nilは全科目表示）
    @State private var selectedFilter: String? = nil

    /// プレビュー用のサンプル科目フィルター
    private let filterOptions = ["すべて", "数学", "英語", "物理", "国語", "化学"]

    // MARK: - サンプルデータ構造
    /// プレビュー用の学習セッションデータ
    struct SampleSession: Identifiable {
        let id = UUID()
        let subject: String
        let duration: String
        let startTime: String
        let memo: String
    }

    /// 日付ごとにグループ化されたサンプルデータ
    private let sampleSections: [(date: String, sessions: [SampleSession])] = [
        ("今日 - 3月16日", [
            SampleSession(subject: "数学", duration: "45分", startTime: "10:00", memo: "微分積分の復習"),
            SampleSession(subject: "英語", duration: "30分", startTime: "11:00", memo: "リーディング演習"),
            SampleSession(subject: "物理", duration: "1時間", startTime: "13:00", memo: "力学の問題集"),
        ]),
        ("昨日 - 3月15日", [
            SampleSession(subject: "国語", duration: "25分", startTime: "09:00", memo: "古文読解"),
            SampleSession(subject: "数学", duration: "50分", startTime: "14:00", memo: "確率の演習"),
        ]),
        ("3月14日（土）", [
            SampleSession(subject: "化学", duration: "40分", startTime: "10:30", memo: "有機化学の暗記"),
            SampleSession(subject: "英語", duration: "1時間15分", startTime: "15:00", memo: "長文読解"),
        ]),
    ]

    // MARK: - ビュー本体
    var body: some View {
        List {
            // MARK: - 科目フィルターセクション
            // 横スクロールのチップで科目を絞り込める
            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(filterOptions, id: \.self) { option in
                            let isSelected = (option == "すべて" && selectedFilter == nil)
                                || option == selectedFilter

                            Text(option)
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    isSelected
                                        ? Color("AccentColor")
                                        : Color(.systemGray5)
                                )
                                .foregroundStyle(isSelected ? .white : .primary)
                                .clipShape(Capsule())
                                .onTapGesture {
                                    selectedFilter = (option == "すべて") ? nil : option
                                }
                        }
                    }
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }

            // MARK: - セッション一覧（日付セクション別）
            // 日付ごとにセクションヘッダーを付けてグループ表示
            // 各行は科目カラー・科目名・所要時間・開始時刻を表示
            ForEach(sampleSections, id: \.date) { section in
                Section {
                    ForEach(section.sessions) { session in
                        // MARK: セッション行
                        // NavigationLinkで詳細画面に遷移可能（将来実装）
                        SessionRowSketch(session: session)
                    }
                    // スワイプアクション: 削除（将来実装）
                    // .onDelete で実装予定
                } header: {
                    Text(section.date)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            }
        }
        .listStyle(.insetGrouped)
        .searchable(text: $searchText, prompt: "科目名やメモで検索")
        .navigationTitle("学習記録")
        .toolbar {
            // MARK: ツールバー
            // 並び替えオプション（将来実装）
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("新しい順", action: {})
                    Button("古い順", action: {})
                    Button("科目別", action: {})
                } label: {
                    Image(systemName: "arrow.up.arrow.down.circle")
                }
            }
        }
    }
}

// MARK: - セッション行コンポーネント
/// 一覧の各行に表示するセッション情報
/// 科目のカラーインジケーター、科目名、メモ、所要時間を表示する
struct SessionRowSketch: View {
    let session: SessionListSketch.SampleSession

    var body: some View {
        HStack(spacing: 12) {
            // 科目カラーインジケーター（丸いアイコン）
            Circle()
                .fill(Color("AccentColor").opacity(0.15))
                .frame(width: 44, height: 44)
                .overlay {
                    Image(systemName: "book.fill")
                        .font(.body)
                        .foregroundStyle(Color("AccentColor"))
                }

            // 科目名とメモ
            VStack(alignment: .leading, spacing: 2) {
                Text(session.subject)
                    .font(.body)
                    .fontWeight(.medium)

                Text(session.memo)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // 所要時間と開始時刻
            VStack(alignment: .trailing, spacing: 2) {
                Text(session.duration)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color("AccentColor"))

                Text(session.startTime)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - プレビュー
#Preview("記録一覧") {
    NavigationStack {
        SessionListSketch()
    }
    .tint(Color("AccentColor"))
}
