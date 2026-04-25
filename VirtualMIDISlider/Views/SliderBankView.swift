import SwiftUI

struct SliderBankView: View {
    @Bindable var viewModel: SliderBankViewModel

    var body: some View {
        Group {
            if viewModel.sliders.isEmpty {
                ContentUnavailableView(
                    "No Sliders",
                    systemImage: "slider.horizontal.3",
                    description: Text("Select a preset or add sliders to get started.")
                )
            } else {
                sliderGrid
            }
        }
        .toolbar { toolbarContent }
        .sheet(item: $viewModel.showingSliderSettings) { config in
            SliderSettingsView(
                config: config,
                onSave: { updated in
                    viewModel.updateSlider(updated)
                    viewModel.showingSliderSettings = nil
                },
                onCancel: {
                    viewModel.showingSliderSettings = nil
                }
            )
        }
        .sheet(isPresented: $viewModel.showingPresetManager) {
            PresetManagerView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showingSavePreset) {
            SavePresetView { name in
                viewModel.saveCurrentAsPreset(name: name)
                viewModel.showingSavePreset = false
            } onCancel: {
                viewModel.showingSavePreset = false
            }
        }
        .onAppear {
            viewModel.midi.setup()
        }
        .frame(minWidth: 300, minHeight: 300)
    }

    @ViewBuilder
    private var sliderGrid: some View {
        if viewModel.settings.layoutMode == .vertical {
            HStack(spacing: 12) {
                ForEach(viewModel.sliders) { slider in
                    MIDISliderView(
                        config: slider,
                        layoutMode: .vertical,
                        onValueChanged: { value in
                            viewModel.sliderValueChanged(id: slider.id, newValue: value)
                        },
                        onSettingsTapped: {
                            viewModel.showingSliderSettings = slider
                        },
                        onRemove: viewModel.sliders.count > 1 ? {
                            viewModel.removeSlider(id: slider.id)
                        } : nil
                    )
                    .frame(maxWidth: .infinity)
                }
            }
            .padding()
        } else {
            VStack(spacing: 12) {
                ForEach(viewModel.sliders) { slider in
                    MIDISliderView(
                        config: slider,
                        layoutMode: .horizontal,
                        onValueChanged: { value in
                            viewModel.sliderValueChanged(id: slider.id, newValue: value)
                        },
                        onSettingsTapped: {
                            viewModel.showingSliderSettings = slider
                        },
                        onRemove: viewModel.sliders.count > 1 ? {
                            viewModel.removeSlider(id: slider.id)
                        } : nil
                    )
                    .frame(maxHeight: .infinity)
                }
            }
            .padding()
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .principal) {
            // Preset picker
            Picker("Preset", selection: Binding(
                get: { viewModel.activePresetID },
                set: { newID in
                    if let id = newID, let preset = viewModel.presets.first(where: { $0.id == id }) {
                        viewModel.loadPreset(preset)
                    }
                }
            )) {
                ForEach(viewModel.presets) { preset in
                    Text(preset.name).tag(Optional(preset.id))
                }
            }
            .frame(width: 150)
        }

        ToolbarItemGroup {
            Button(action: { viewModel.showingSavePreset = true }) {
                Image(systemName: "square.and.arrow.down")
            }
            .help("Save as Preset")

            Button(action: { viewModel.showingPresetManager = true }) {
                Image(systemName: "list.bullet")
            }
            .help("Manage Presets")

            Divider()

            Button(action: { viewModel.toggleLayout() }) {
                Image(systemName: viewModel.settings.layoutMode == .vertical
                      ? "rectangle.split.1x2" : "rectangle.split.2x1")
            }
            .help("Toggle Layout")

            Divider()

            Button(action: { viewModel.addSlider() }) {
                Image(systemName: "plus")
            }
            .help("Add Slider")
            .disabled(viewModel.sliders.count >= 16)
        }
    }
}

// MARK: - Save Preset Sheet

struct SavePresetView: View {
    let onSave: (String) -> Void
    let onCancel: () -> Void

    @State private var name = ""

    var body: some View {
        VStack(spacing: 16) {
            Text("Save Preset")
                .font(.headline)

            TextField("Preset name", text: $name)
                .textFieldStyle(.roundedBorder)
                .frame(width: 250)
                .onSubmit { saveIfValid() }

            HStack {
                Button("Cancel", action: onCancel)
                    .keyboardShortcut(.cancelAction)
                Button("Save", action: saveIfValid)
                    .keyboardShortcut(.defaultAction)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(24)
    }

    private func saveIfValid() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        onSave(trimmed)
    }
}
