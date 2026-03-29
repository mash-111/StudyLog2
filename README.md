# StudyLog2

学習時間をタイマーで計測・記録するiOSアプリ。科目ごとに分類し、グラフや統計で学習状況を振り返ることができる。

## 機能

- **タイマー計測** — 科目を選んでワンタップで学習時間を計測
- **記録一覧** — 過去の学習セッションを一覧表示
- **統計グラフ** — 日・週・月単位で学習時間をグラフで確認
- **目標設定** — 科目ごとに目標時間を設定し、達成時に通知
- **科目管理** — 科目の追加・編集・削除

## 技術スタック

| 項目 | 内容 |
|------|------|
| 言語 | Swift |
| UI | SwiftUI |
| データ永続化 | SwiftData |
| グラフ | Swift Charts |
| 通知 | UserNotifications |
| 対応OS | iOS 17以上 |

## プロジェクト構成

```
StudyLog2/
├── Models/           # SwiftDataモデル（Subject, StudySession, DailyGoal）
├── ViewModels/       # ビジネスロジック（MVVM）
├── Views/
│   ├── Home/         # ホーム画面・タイマー
│   ├── Sessions/     # 記録一覧
│   ├── Statistics/   # 統計グラフ
│   └── Settings/     # 設定・科目管理
├── Services/         # 通知管理
└── Extensions/       # Swift拡張
```

## セットアップ

1. リポジトリをクローン
2. `StudyLog2.xcodeproj` をXcodeで開く
3. ターゲットデバイスを選択してビルド・実行（iOS 17以上）
