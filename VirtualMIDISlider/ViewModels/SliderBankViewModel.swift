import Foundation
import SwiftUI

@MainActor @Observable
final class SliderBankViewModel {
    var sliders: [SliderConfiguration] = []
    var presets: [Preset] = []
    var activePresetID: UUID?
    var settings: AppSettings = AppSettings()

    var showingPresetManager = false
    var showingSliderSettings: SliderConfiguration?
    var showingSavePreset = false

    let midi: MIDIManager
    private let persistence: PersistenceManager

    init(midi: MIDIManager, persistence: PersistenceManager) {
        self.midi = midi
        self.persistence = persistence

        let state = persistence.load()
        self.presets = state.presets
        self.settings = state.settings
        self.activePresetID = state.activePresetID

        if let presetID = activePresetID,
           let preset = presets.first(where: { $0.id == presetID }) {
            self.sliders = preset.sliders
        } else if let first = presets.first {
            self.sliders = first.sliders
            self.activePresetID = first.id
        }

        midi.onCCReceived = { [weak self] channel, cc, value in
            self?.handleIncomingCC(channel: channel, cc: cc, value: value)
        }
    }

    var activePreset: Preset? {
        presets.first(where: { $0.id == activePresetID })
    }

    // MARK: - Slider Actions

    func sliderValueChanged(id: UUID, newValue: UInt8) {
        guard let index = sliders.firstIndex(where: { $0.id == id }) else { return }
        sliders[index].value = newValue
        midi.sendCC(
            channel: sliders[index].channel,
            cc: sliders[index].ccNumber,
            value: newValue
        )
    }

    func handleIncomingCC(channel: UInt8, cc: UInt8, value: UInt8) {
        for i in sliders.indices {
            if sliders[i].channel == channel && sliders[i].ccNumber == cc {
                sliders[i].value = value
            }
        }
    }

    // MARK: - Slider Management

    func addSlider() {
        guard sliders.count < 16 else { return }
        let nextCC: UInt8 = [1, 11, 7, 2, 74, 71, 10, 64, 5, 12, 13, 91, 93, 80, 81, 82]
            .first(where: { cc in !sliders.contains(where: { $0.ccNumber == cc }) }) ?? 0
        sliders.append(SliderConfiguration(ccNumber: nextCC))
        saveConfig()
    }

    func removeSlider(id: UUID) {
        guard sliders.count > 1 else { return }
        sliders.removeAll(where: { $0.id == id })
        saveConfig()
    }

    func updateSlider(_ config: SliderConfiguration) {
        guard let index = sliders.firstIndex(where: { $0.id == config.id }) else { return }
        sliders[index] = config
        saveConfig()
    }

    // MARK: - Preset Management

    func loadPreset(_ preset: Preset) {
        activePresetID = preset.id
        sliders = preset.sliders.map { slider in
            var s = slider
            s.id = UUID() // fresh IDs
            s.value = 0
            return s
        }
        saveConfig()
    }

    func saveCurrentAsPreset(name: String) {
        let preset = Preset(name: name, sliders: sliders)
        presets.append(preset)
        activePresetID = preset.id
        saveConfig()
    }

    func deletePreset(_ preset: Preset) {
        guard !preset.isBuiltIn else { return }
        presets.removeAll(where: { $0.id == preset.id })
        saveConfig()
    }

    func renamePreset(_ preset: Preset, to name: String) {
        guard let index = presets.firstIndex(where: { $0.id == preset.id }) else { return }
        presets[index].name = name
        saveConfig()
    }

    // MARK: - Layout

    func toggleLayout() {
        settings.layoutMode = settings.layoutMode == .vertical ? .horizontal : .vertical
        saveConfig()
    }

    // MARK: - Persistence

    func saveConfig() {
        let state = PersistenceManager.StoredState(
            presets: presets,
            activePresetID: activePresetID,
            settings: settings
        )
        persistence.save(state)
    }
}
