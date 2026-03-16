import SwiftUI

// MARK: - ホーム画面スケッチ
// 学習タイマーと今日の学習サマリーを表示するメイン画面
//
// レイアウト構成（上から順に）:
// ┌─────────────────────────┐
// │ ナビゲーションバー       │
// │ 「StudyLog」タイトル     │
// ├─────────────────────────┤
// │ 科目選択セクション       │
// │ [数学] [英語] [理科] ... │
// ├─────────────────────────┤
// │                         │
// │    ⏱ 00:25:30          │
// │    タイマー表示          │
// │                         │
// │   [開始] / [停止]       │
// │                         │
// ├─────────────────────────┤
// │ 今日の学習サマリー       │
// │ ・合計: 2時間15分       │
// │ ・セッション数: 3回     │
// │ ・目標達成率: 75%       │
// └─────────────────────────┘

/// ホーム画面: タイマー操作と今日の学習状況を一目で確認できる画面
struct HomeSketch: View {

    // MARK: - 状態管理（プレビュー用のダミー状態）
    /// タイマーが動作中かどうか
    @State private var isTimerRunning = false
    /// 選択中の科目インデックス
    @State private var selectedSubjectIndex = 0

    /// プレビュー用のサンプル科目一覧
    private let sampleSubjects = ["数学", "英語", "物理", "国語", "化学"]

    // MARK: - ビュー本体
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {

                // MARK: - 科目選択セクション
                // 横スクロール可能なチップ形式で科目を選択
                // 選択中の科目はアクセントカラーでハイライト
                VStack(alignment: .leading, spacing: 8) {
                    Text("科目を選択")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(sampleSubjects.indices, id: \.self) { index in
                                Text(sampleSubjects[index])
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        index == selectedSubjectIndex
                                            ? Color("AccentColor")
                                            : Color(.systemGray5)
                                    )
                                    .foregroundStyle(
                                        index == selectedSubjectIndex
                                            ? .white
                                            : .primary
                                    )
                                    .clipShape(Capsule())
                                    .onTapGesture {
                                        selectedSubjectIndex = index
                                    }
                            }
                        }
                    }
                }
                .padding(.horizontal)

                // MARK: - タイマー表示セクション
                // 大きな円形デザインでタイマーを目立たせる
                // 集中を促すためシンプルなレイアウトにする
                VStack(spacing: 16) {
                    ZStack {
                        // 背景リング（進捗を示す円）
                        Circle()
                            .stroke(Color(.systemGray5), lineWidth: 8)
                            .frame(width: 220, height: 220)

                        // アクセントカラーの進捗リング（プレースホルダー）
                        Circle()
                            .trim(from: 0, to: 0.65)
                            .stroke(
                                Color("AccentColor"),
                                style: StrokeStyle(lineWidth: 8, lineCap: .round)
                            )
                            .frame(width: 220, height: 220)
                            .rotationEffect(.degrees(-90))

                        // タイマー時間表示
                        VStack(spacing: 4) {
                            Text("00:25:30")
                                .font(.system(size: 48, weight: .light, design: .monospaced))
                                .foregroundStyle(.primary)

                            Text(sampleSubjects[selectedSubjectIndex])
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)

                    // MARK: タイマー操作ボタン
                    // 開始/停止の状態に応じてボタンの色とラベルを切り替える
                    HStack(spacing: 20) {
                        // リセットボタン（タイマー動作中のみ表示）
                        if isTimerRunning {
                            Button {
                                // リセット処理（スケッチのため空実装）
                            } label: {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.title2)
                                    .frame(width: 56, height: 56)
                                    .background(Color(.systemGray5))
                                    .clipShape(Circle())
                            }
                        }

                        // メインの開始/停止ボタン
                        Button {
                            isTimerRunning.toggle()
                        } label: {
                            Image(systemName: isTimerRunning ? "stop.fill" : "play.fill")
                                .font(.title)
                                .foregroundStyle(.white)
                                .frame(width: 72, height: 72)
                                .background(
                                    isTimerRunning
                                        ? Color.red
                                        : Color("AccentColor")
                                )
                                .clipShape(Circle())
                        }
                    }
                }

                // MARK: - 今日の学習サマリーセクション
                // カード形式で今日の学習成果を3つの指標で表示
                VStack(alignment: .leading, spacing: 12) {
                    Text("今日の学習")
                        .font(.headline)

                    // 3列のグリッドで指標を並べる
                    HStack(spacing: 12) {
                        // 合計学習時間
                        SummaryCardSketch(
                            icon: "clock.fill",
                            title: "合計時間",
                            value: "2時間15分"
                        )

                        // セッション回数
                        SummaryCardSketch(
                            icon: "number",
                            title: "セッション",
                            value: "3回"
                        )

                        // 目標達成率
                        SummaryCardSketch(
                            icon: "target",
                            title: "達成率",
                            value: "75%"
                        )
                    }
                }
                .padding(.horizontal)

                // MARK: - 直近の学習セッション（簡易表示）
                // 今日の学習記録を直近3件だけ表示
                // 「もっと見る」で記録タブに遷移
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("直近のセッション")
                            .font(.headline)
                        Spacer()
                        // 記録タブへの導線
                        Button("すべて見る") {
                            // タブ切り替え処理（スケッチのため空実装）
                        }
                        .font(.subheadline)
                    }

                    // プレースホルダーのセッション行
                    ForEach(0..<3, id: \.self) { index in
                        HStack {
                            Circle()
                                .fill(Color("AccentColor").opacity(0.2))
                                .frame(width: 40, height: 40)
                                .overlay {
                                    Image(systemName: "book.fill")
                                        .foregroundStyle(Color("AccentColor"))
                                }

                            VStack(alignment: .leading) {
                                Text(["数学", "英語", "物理"][index])
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text(["45分", "30分", "1時間"][index])
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Text(["10:00〜10:45", "11:00〜11:30", "13:00〜14:00"][index])
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("StudyLog")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - サマリーカードコンポーネント
/// 今日の学習サマリーに使用する小さなカード
/// アイコン・タイトル・数値を縦に並べて表示する
struct SummaryCardSketch: View {
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

// MARK: - プレビュー
#Preview("ホーム画面") {
    NavigationStack {
        HomeSketch()
    }
    .tint(Color("AccentColor"))
}
