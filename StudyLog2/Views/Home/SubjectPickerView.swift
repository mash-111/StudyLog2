import SwiftUI
import SwiftData

/// 科目選択コンポーネント
/// 横スクロール可能なチップ形式で科目を選択する再利用可能なビュー
struct SubjectPickerView: View {

    /// 選択可能な科目一覧
    let subjects: [Subject]
    /// 選択中の科目（バインディング）
    @Binding var selectedSubject: Subject?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("科目を選択")
                .font(.headline)
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(subjects, id: \.id) { subject in
                        SubjectChipView(
                            subject: subject,
                            isSelected: selectedSubject?.id == subject.id
                        )
                        .onTapGesture {
                            // 科目選択時の触覚フィードバック
                            let impact = UIImpactFeedbackGenerator(style: .light)
                            impact.impactOccurred()
                            selectedSubject = subject
                        }
                    }
                }
                .padding(.horizontal, 1) // チップの影が切れないようにする
            }
        }
        .padding(.horizontal)
    }
}

/// 個別の科目チップ
/// アイコンと科目名を表示し、選択状態に応じてスタイルを変更する
private struct SubjectChipView: View {

    let subject: Subject
    let isSelected: Bool

    /// 16進カラーコードからColorを生成
    private var subjectColor: Color {
        Color(hex: subject.color)
    }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: subject.icon)
                .font(.caption)
            Text(subject.name)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(isSelected ? subjectColor : Color(.systemGray5))
        .foregroundStyle(isSelected ? .white : .primary)
        .clipShape(Capsule())
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// Color(hex:) は Extensions/Color+Hex.swift で定義済み

// MARK: - プレビュー

#Preview("科目選択") {
    @Previewable @State var selected: Subject? = nil

    SubjectPickerView(
        subjects: [],
        selectedSubject: $selected
    )
    .modelContainer(try! previewContainer())
}
