import SwiftUI

// MARK: - サマリーカードコンポーネント
// 統計画面で使用する再利用可能なカード

/// 統計値を表示するカード
/// アイコン・タイトル・値をまとめて表示する
struct StatsSummaryCard: View {
    /// SFSymbolアイコン名
    let icon: String
    /// カードのタイトル（例：「合計時間」）
    let title: String
    /// 表示値（例：「2時間30分」）
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // アイコン
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color("AccentColor"))

            // 値
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            // タイトル
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - プレビュー
#Preview("サマリーカード") {
    LazyVGrid(
        columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12),
        ],
        spacing: 12
    ) {
        StatsSummaryCard(icon: "clock.fill", title: "合計時間", value: "14時間5分")
        StatsSummaryCard(icon: "divide.circle.fill", title: "平均/日", value: "2時間")
        StatsSummaryCard(icon: "number.circle.fill", title: "セッション数", value: "18回")
        StatsSummaryCard(icon: "flame.fill", title: "連続日数", value: "5日")
    }
    .padding()
}
