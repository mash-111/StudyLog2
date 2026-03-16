import SwiftUI
import SwiftData

/// 記録一覧画面
/// 過去の学習セッションを日付ごとにグループ化して表示する
struct SessionListView: View {

    // MARK: - データ

    @Environment(\.modelContext) private var modelContext

    /// 全セッションを新しい順に取得
    @Query(sort: \StudySession.startTime, order: .reverse) private var sessions: [StudySession]

    // スワイプ削除ボタンのリセット対策
    // 方法3を採用: List に .id() を付与し、タブ切り替え時（onDisappear）に
    // IDを再生成して強制リフレッシュする。
    // 理由: onChange(of: selectedTab) は親Viewの selectedTab を参照する必要があり
    // コンポーネントの独立性が下がる。.onDisappear + id 再生成が最もSwiftUIらしい。
    @State private var listId = UUID()

    // MARK: - ビュー本体

    var body: some View {
        NavigationStack {
            Group {
                if sessions.isEmpty {
                    // セッションがない場合のプレースホルダー
                    ContentUnavailableView(
                        "記録がありません",
                        systemImage: "book.closed",
                        description: Text("学習を開始すると、ここに記録が表示されます")
                    )
                } else {
                    List {
                        ForEach(groupedSessions, id: \.key) { dateString, daySessions in
                            Section(header: Text(dateString)) {
                                ForEach(daySessions, id: \.id) { session in
                                    SessionRow(session: session)
                                }
                                .onDelete { offsets in
                                    deleteSessions(at: offsets, from: daySessions)
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .id(listId)
                }
            }
            .navigationTitle("記録一覧")
            .onDisappear {
                listId = UUID()
            }
        }
    }

    // MARK: - 日付ごとにグループ化

    /// セッションを日付文字列でグループ化して返す
    private var groupedSessions: [(key: String, value: [StudySession])] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy年M月d日（E）"

        let grouped = Dictionary(grouping: sessions) { session in
            formatter.string(from: calendar.startOfDay(for: session.startTime))
        }

        // 日付の降順でソート（新しい日付が先）
        return grouped.sorted { pair1, pair2 in
            guard let date1 = pair1.value.first?.startTime,
                  let date2 = pair2.value.first?.startTime else { return false }
            return date1 > date2
        }
    }

    // MARK: - 削除

    /// 指定されたインデックスのセッションを削除する
    private func deleteSessions(at offsets: IndexSet, from daySessions: [StudySession]) {
        for index in offsets {
            modelContext.delete(daySessions[index])
        }
    }
}

// MARK: - セッション行コンポーネント

/// 学習セッションを1行で表示する
private struct SessionRow: View {

    let session: StudySession

    /// セッションの学習時間（フォーマット済み）
    private var formattedDuration: String {
        let minutes = session.durationSeconds / 60
        let seconds = session.durationSeconds % 60
        if minutes >= 60 {
            return "\(minutes / 60)時間\(minutes % 60)分"
        } else if minutes > 0 {
            return "\(minutes)分\(seconds)秒"
        } else {
            return "\(seconds)秒"
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
        HStack(spacing: 12) {
            // 科目アイコン
            Circle()
                .fill(subjectColor.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay {
                    Image(systemName: session.subject?.icon ?? "book.fill")
                        .foregroundStyle(subjectColor)
                }

            // 科目名と時間帯
            VStack(alignment: .leading, spacing: 2) {
                Text(session.subject?.name ?? "不明")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(formattedTimeRange)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // 学習時間
            Text(formattedDuration)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color("AccentColor"))
        }
        .padding(.vertical, 2)
    }
}

// MARK: - プレビュー

#Preview("記録一覧") {
    SessionListView()
        .modelContainer(try! previewContainer())
}
