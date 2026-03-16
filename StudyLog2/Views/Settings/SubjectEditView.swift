import SwiftUI
import SwiftData

/// 科目追加・編集シート
/// 科目名、カラー、アイコンを設定して保存する。
struct SubjectEditView: View {

    // MARK: - 依存関係
    @Bindable var viewModel: SettingsViewModel
    @Environment(\.modelContext) private var modelContext

    /// 編集モードかどうか（既存科目の編集の場合true）
    var isEditing: Bool {
        viewModel.editingSubject != nil
    }

    // MARK: - ビュー本体
    var body: some View {
        NavigationStack {
            Form {
                // MARK: - プレビューセクション
                Section {
                    HStack {
                        Spacer()
                        subjectPreview
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }

                // MARK: - 科目名入力
                Section {
                    TextField("科目名を入力", text: $viewModel.subjectName)
                        .font(.body)
                } header: {
                    Text("科目名")
                }

                // MARK: - カラー選択
                Section {
                    colorPickerGrid
                } header: {
                    Text("カラー")
                }

                // MARK: - アイコン選択
                Section {
                    iconPickerGrid
                } header: {
                    Text("アイコン")
                }
            }
            .navigationTitle(isEditing ? "科目を編集" : "科目を追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        viewModel.showAddSubjectSheet = false
                        viewModel.editingSubject = nil
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "保存" : "追加") {
                        viewModel.saveSubject(context: modelContext)
                    }
                    .disabled(viewModel.subjectName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.large])
    }

    // MARK: - 科目プレビュー

    /// 選択中のカラーとアイコンで科目のプレビューを表示する
    private var subjectPreview: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(SettingsViewModel.color(from: viewModel.subjectColor))
                    .frame(width: 72, height: 72)

                Image(systemName: viewModel.subjectIcon)
                    .font(.system(size: 32))
                    .foregroundStyle(.white)
            }

            Text(viewModel.subjectName.isEmpty ? "科目名" : viewModel.subjectName)
                .font(.headline)
                .foregroundStyle(
                    viewModel.subjectName.isEmpty ? .secondary : .primary
                )
        }
        .padding(.vertical, 8)
    }

    // MARK: - カラーピッカーグリッド

    /// プリセットカラーをグリッド表示する
    private var colorPickerGrid: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 6),
            spacing: 12
        ) {
            ForEach(SettingsViewModel.presetColors, id: \.hex) { preset in
                colorCircle(hex: preset.hex)
            }
        }
        .padding(.vertical, 4)
    }

    /// 個別のカラー選択サークル
    private func colorCircle(hex: String) -> some View {
        ZStack {
            Circle()
                .fill(SettingsViewModel.color(from: hex))
                .frame(width: 40, height: 40)

            // 選択中のカラーにはチェックマークを表示
            if viewModel.subjectColor == hex {
                Circle()
                    .strokeBorder(.white, lineWidth: 3)
                    .frame(width: 40, height: 40)

                Image(systemName: "checkmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .onTapGesture {
            // カラー選択時の触覚フィードバック
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            viewModel.subjectColor = hex
        }
        .accessibilityLabel("カラー \(hex)")
    }

    // MARK: - アイコンピッカーグリッド

    /// プリセットアイコンをグリッド表示する
    private var iconPickerGrid: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 5),
            spacing: 12
        ) {
            ForEach(SettingsViewModel.presetIcons, id: \.self) { icon in
                iconCell(name: icon)
            }
        }
        .padding(.vertical, 4)
    }

    /// 個別のアイコン選択セル
    private func iconCell(name: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(
                    viewModel.subjectIcon == name
                        ? SettingsViewModel.color(from: viewModel.subjectColor)
                        : Color(.systemGray5)
                )
                .frame(width: 48, height: 48)

            Image(systemName: name)
                .font(.system(size: 22))
                .foregroundStyle(
                    viewModel.subjectIcon == name ? .white : .primary
                )
        }
        .onTapGesture {
            // アイコン選択時の触覚フィードバック
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            viewModel.subjectIcon = name
        }
        .accessibilityLabel("アイコン \(name)")
    }
}

// MARK: - プレビュー
#Preview("科目追加") {
    SubjectEditView(viewModel: {
        let vm = SettingsViewModel()
        vm.subjectName = ""
        vm.subjectColor = "#4A90D9"
        vm.subjectIcon = "book"
        return vm
    }())
    .modelContainer(try! previewContainer())
}

#Preview("科目編集") {
    SubjectEditView(viewModel: {
        let vm = SettingsViewModel()
        vm.editingSubject = Subject.sampleMath
        vm.subjectName = "数学"
        vm.subjectColor = "#4A90D9"
        vm.subjectIcon = "function"
        return vm
    }())
    .modelContainer(try! previewContainer())
}
