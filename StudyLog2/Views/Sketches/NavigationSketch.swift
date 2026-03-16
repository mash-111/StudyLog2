import SwiftUI

// MARK: - メインナビゲーション構造
// TabViewベースの4画面構成
// 各タブは独立したNavigationStackを持ち、画面内遷移をサポートする
// タブ: ホーム / 記録 / 統計 / 設定

/// アプリ全体のタブナビゲーションを定義するルートビュー
/// iOS 17+のNavigationStackを各タブ内で使用し、
/// タブ間の状態は独立して保持される
struct NavigationSketch: View {

    // MARK: - 状態管理
    /// 現在選択中のタブを管理（デフォルトはホーム画面）
    @State private var selectedTab: Tab = .home

    // MARK: - タブ定義
    /// アプリ内の4つのタブを列挙型で定義
    /// rawValueはタブの識別子として使用
    enum Tab: String, CaseIterable {
        case home = "home"
        case sessions = "sessions"
        case statistics = "statistics"
        case settings = "settings"

        /// タブに表示するラベルテキスト（日本語）
        var label: String {
            switch self {
            case .home: return "ホーム"
            case .sessions: return "記録"
            case .statistics: return "統計"
            case .settings: return "設定"
            }
        }

        /// タブに表示するSF Symbolsアイコン名
        var icon: String {
            switch self {
            case .home: return "timer"
            case .sessions: return "list.bullet.rectangle"
            case .statistics: return "chart.bar.fill"
            case .settings: return "gearshape.fill"
            }
        }
    }

    // MARK: - ビュー本体
    var body: some View {
        TabView(selection: $selectedTab) {

            // MARK: ホームタブ
            // タイマーと今日の学習サマリーを表示するメイン画面
            NavigationStack {
                HomeSketch()
            }
            .tabItem {
                Label(Tab.home.label, systemImage: Tab.home.icon)
            }
            .tag(Tab.home)

            // MARK: 記録タブ
            // 過去の学習ログを一覧表示する画面
            // 各セッションをタップすると詳細に遷移（NavigationStack内）
            NavigationStack {
                SessionListSketch()
            }
            .tabItem {
                Label(Tab.sessions.label, systemImage: Tab.sessions.icon)
            }
            .tag(Tab.sessions)

            // MARK: 統計タブ
            // グラフや集計データを表示する画面
            // 週/月の切り替えはセグメントコントロールで行う
            NavigationStack {
                StatisticsSketch()
            }
            .tabItem {
                Label(Tab.statistics.label, systemImage: Tab.statistics.icon)
            }
            .tag(Tab.statistics)

            // MARK: 設定タブ
            // 科目管理・目標設定などの設定画面
            NavigationStack {
                SettingsSketch()
            }
            .tabItem {
                Label(Tab.settings.label, systemImage: Tab.settings.icon)
            }
            .tag(Tab.settings)
        }
        // アクセントカラーをアセットカタログから適用
        .tint(Color("AccentColor"))
    }
}

// MARK: - プレビュー
#Preview("メインナビゲーション") {
    NavigationSketch()
}
