import Foundation

final class PersistenceManager {
    struct StoredState: Codable {
        var presets: [Preset]
        var activePresetID: UUID?
        var settings: AppSettings
    }

    private let fileURL: URL

    init() {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("VirtualMIDISlider", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        fileURL = dir.appendingPathComponent("config.json")
    }

    func load() -> StoredState {
        guard let data = try? Data(contentsOf: fileURL),
              var state = try? JSONDecoder().decode(StoredState.self, from: data) else {
            return defaultState()
        }
        // Ensure built-in presets are always present
        for builtIn in Preset.builtInPresets {
            if !state.presets.contains(where: { $0.name == builtIn.name && $0.isBuiltIn }) {
                state.presets.insert(builtIn, at: 0)
            }
        }
        return state
    }

    func save(_ state: StoredState) {
        guard let data = try? JSONEncoder().encode(state) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    private func defaultState() -> StoredState {
        let presets = Preset.builtInPresets
        return StoredState(
            presets: presets,
            activePresetID: presets.first?.id,
            settings: AppSettings()
        )
    }
}
