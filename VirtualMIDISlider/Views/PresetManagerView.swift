import SwiftUI

struct PresetManagerView: View {
    @Bindable var viewModel: SliderBankViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            Text("Presets")
                .font(.headline)
                .padding()

            List {
                Section("Built-in") {
                    ForEach(viewModel.presets.filter(\.isBuiltIn)) { preset in
                        presetRow(preset)
                    }
                }

                let userPresets = viewModel.presets.filter { !$0.isBuiltIn }
                if !userPresets.isEmpty {
                    Section("Custom") {
                        ForEach(userPresets) { preset in
                            presetRow(preset)
                                .contextMenu {
                                    Button("Delete", role: .destructive) {
                                        viewModel.deletePreset(preset)
                                    }
                                }
                        }
                    }
                }
            }
            .listStyle(.inset)
            .frame(minWidth: 300, minHeight: 300)

            Divider()

            HStack {
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
    }

    private func presetRow(_ preset: Preset) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(preset.name)
                    .fontWeight(preset.id == viewModel.activePresetID ? .bold : .regular)
                Text("\(preset.sliders.count) slider\(preset.sliders.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if preset.id == viewModel.activePresetID {
                Image(systemName: "checkmark")
                    .foregroundStyle(Color.accentColor)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.loadPreset(preset)
        }
    }
}
