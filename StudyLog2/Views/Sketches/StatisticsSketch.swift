import SwiftUI
import Charts

// MARK: - 統計画面スケッチ
// 学習データをグラフと集計値で可視化する画面
//
// レイアウト構成:
// ┌─────────────────────────┐
// │ ナビゲーションバー       │
// │ 「統計」                │
// ├─────────────────────────┤
// │ [週間] [月間] セグメント │
// ├─────────────────────────┤
// │ ┌───────────────────┐  │
// │ │ 棒グラフ           │  │
// │ │ 日別学習時間       │  │
// │ └───────────────────┘  │
// ├─────────────────────────┤
// │ サマリーカード（2列）   │
// │ [合計時間] [平均/日]   │
// │ [セッション] [最長]    │
// ├─────────────────────────┤
// │ ┌───────────────────┐  │
// │ │ 円グラフ           │  │
// │ │ 科目別割合         │  │
// │ └───────────────────┘  │
// ├─────────────────────────┤
// │ 科目別の内訳リスト     │
// └─────────────────────────┘
//
// 設計意図:
// - Chartsフレームワークを使ってネイティブなグラフを描画
// - 週間/月間の切り替えでデータ粒度を変更
// - サマリーカードで重要指標を一目で確認
// - 科目別の円グラフで学習バランスを可視化

/// 統計画面: 学習データをグラフと数値で可視化する
struct StatisticsSketch: View {

    // MARK: - 状態管理
    /// 週間/月間の表示期間切り替え
    @State private var selectedPeriod: Period = .weekly

    /// 表示期間の列挙型
    enum Period: String, CaseIterable {
        case weekly = "週間"
        case monthly = "月間"
    }

    // MARK: - サンプルデータ
    /// 棒グラフ用: 日別の学習時間（分）
    struct DailyStudy: Identifiable {
        let id = UUID()
        let day: String
        let minutes: Int
    }

    /// 円グラフ用: 科目別の学習時間
    struct SubjectBreakdown: Identifiable {
        let id = UUID()
        let subject: String
        let minutes: Int
        let color: Color
    }

    /// 週間の日別学習時間サンプル
    private let weeklyData: [DailyStudy] = [
        DailyStudy(day: "月", minutes: 120),
        DailyStudy(day: "火", minutes: 90),
        DailyStudy(day: "水", minutes: 150),
        DailyStudy(day: "木", minutes: 60),
        DailyStudy(day: "金", minutes: 180),
        DailyStudy(day: "土", minutes: 200),
        DailyStudy(day: "日", minutes: 45),
    ]

    /// 科目別内訳サンプル
    private let subjectData: [SubjectBreakdown] = [
        SubjectBreakdown(subject: "数学", minutes: 280, color: .blue),
        SubjectBreakdown(subject: "英語", minutes: 210, color: .green),
        SubjectBreakdown(subject: "物理", minutes: 150, color: .orange),
        SubjectBreakdown(subject: "国語", minutes: 100, color: .purple),
        SubjectBreakdown(subject: "化学", minutes: 105, color: .pink),
    ]

    // MARK: - ビュー本体
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {

                // MARK: - 期間切り替えセグメント
                // 週間と月間でデータの集計範囲を切り替える
                Picker("表示期間", selection: $selectedPeriod) {
                    ForEach(Period.allCases, id: \.self) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // MARK: - 日別学習時間グラフ（棒グラフ）
                // Chartsフレームワークを使用した棒グラフ
                // X軸: 曜日、Y軸: 学習時間（分）
                VStack(alignment: .leading, spacing: 12) {
                    Text("学習時間の推移")
                        .font(.headline)
                        .padding(.horizontal)

                    Chart(weeklyData) { item in
                        BarMark(
                            x: .value("曜日", item.day),
                            y: .value("時間（分）", item.minutes)
                        )
                        .foregroundStyle(Color("AccentColor").gradient)
                        .cornerRadius(4)
                    }
                    .chartYAxisLabel("分")
                    .frame(height: 200)
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)

                // MARK: - サマリー指標カード（2x2グリッド）
                // 重要な統計値を4つのカードに分けて一目で確認できるようにする
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12),
                    ],
                    spacing: 12
                ) {
                    // 今週の合計学習時間
                    StatCardSketch(
                        title: "合計時間",
                        value: "14時間5分",
                        icon: "clock.fill",
                        trend: "+12%"
                    )

                    // 1日あたりの平均学習時間
                    StatCardSketch(
                        title: "平均/日",
                        value: "2時間",
                        icon: "divide.circle.fill",
                        trend: "+5%"
                    )

                    // 総セッション数
                    StatCardSketch(
                        title: "セッション数",
                        value: "18回",
                        icon: "number.circle.fill",
                        trend: "+3回"
                    )

                    // 最長セッション
                    StatCardSketch(
                        title: "最長セッション",
                        value: "1時間45分",
                        icon: "trophy.fill",
                        trend: ""
                    )
                }
                .padding(.horizontal)

                // MARK: - 科目別割合グラフ（円グラフ）
                // 各科目がどれだけの割合を占めるかを円グラフで表示
                VStack(alignment: .leading, spacing: 12) {
                    Text("科目別の割合")
                        .font(.headline)
                        .padding(.horizontal)

                    Chart(subjectData) { item in
                        SectorMark(
                            angle: .value("時間", item.minutes),
                            innerRadius: .ratio(0.5),
                            angularInset: 2
                        )
                        .foregroundStyle(item.color)
                        .cornerRadius(4)
                    }
                    .frame(height: 200)
                    .padding(.horizontal)

                    // MARK: 科目別凡例リスト
                    // グラフの色と科目名・時間を対応付けて表示
                    VStack(spacing: 8) {
                        ForEach(subjectData) { item in
                            HStack {
                                Circle()
                                    .fill(item.color)
                                    .frame(width: 10, height: 10)

                                Text(item.subject)
                                    .font(.subheadline)

                                Spacer()

                                let hours = item.minutes / 60
                                let mins = item.minutes % 60
                                Text("\(hours)時間\(mins)分")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)

                                // 全体に対する割合を計算して表示
                                let total = subjectData.reduce(0) { $0 + $1.minutes }
                                let percentage = Int(Double(item.minutes) / Double(total) * 100)
                                Text("\(percentage)%")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(Color("AccentColor"))
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("統計")
    }
}

// MARK: - 統計カードコンポーネント
/// 統計値を表示する小さなカード
/// アイコン・タイトル・値・前期比トレンドを表示する
struct StatCardSketch: View {
    let title: String
    let value: String
    let icon: String
    /// 前期比のトレンド表示（例: "+12%"）。空文字なら非表示
    let trend: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(Color("AccentColor"))
                Spacer()
                // トレンドがある場合のみ表示（前期比）
                if !trend.isEmpty {
                    Text(trend)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.green)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.1))
                        .clipShape(Capsule())
                }
            }

            Text(value)
                .font(.title3)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - プレビュー
#Preview("統計画面") {
    NavigationStack {
        StatisticsSketch()
    }
    .tint(Color("AccentColor"))
}
