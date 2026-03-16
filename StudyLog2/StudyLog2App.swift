import SwiftUI
import SwiftData

/// アプリのエントリポイント
/// SwiftDataのModelContainerとTabView構成を設定する
@main
struct StudyLog2App: App {

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Subject.self, StudySession.self, DailyGoal.self])
    }
}

/// メインのタブ切り替えビュー
struct ContentView: View {

    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("ホーム", systemImage: "house.fill")
                }

            SessionListView()
                .tabItem {
                    Label("記録一覧", systemImage: "list.bullet.rectangle")
                }

            StatsView()
                .tabItem {
                    Label("統計", systemImage: "chart.bar.fill")
                }

            SettingsView()
                .tabItem {
                    Label("設定", systemImage: "gearshape.fill")
                }
        }
        .tint(Color("AccentColor"))
    }
}

#Preview {
    ContentView()
        .modelContainer(try! previewContainer())
}
