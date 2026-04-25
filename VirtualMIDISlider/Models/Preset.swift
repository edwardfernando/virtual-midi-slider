import Foundation

struct Preset: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var sliders: [SliderConfiguration]
    var isBuiltIn: Bool = false

    static let builtInPresets: [Preset] = [
        Preset(
            name: "Orchestral",
            sliders: [
                SliderConfiguration(ccNumber: 1, label: "Mod Wheel"),
                SliderConfiguration(ccNumber: 11, label: "Expression"),
                SliderConfiguration(ccNumber: 7, label: "Volume"),
                SliderConfiguration(ccNumber: 2, label: "Breath"),
            ],
            isBuiltIn: true
        ),
        Preset(
            name: "Synth",
            sliders: [
                SliderConfiguration(ccNumber: 1, label: "Mod Wheel"),
                SliderConfiguration(ccNumber: 74, label: "Cutoff"),
                SliderConfiguration(ccNumber: 71, label: "Resonance"),
                SliderConfiguration(ccNumber: 7, label: "Volume"),
            ],
            isBuiltIn: true
        ),
        Preset(
            name: "DJ",
            sliders: [
                SliderConfiguration(ccNumber: 7, channel: 0, label: "Vol Ch1"),
                SliderConfiguration(ccNumber: 7, channel: 1, label: "Vol Ch2"),
                SliderConfiguration(ccNumber: 7, channel: 2, label: "Vol Ch3"),
                SliderConfiguration(ccNumber: 7, channel: 3, label: "Vol Ch4"),
            ],
            isBuiltIn: true
        ),
        Preset(
            name: "Minimal",
            sliders: [
                SliderConfiguration(ccNumber: 1, label: "Mod Wheel"),
            ],
            isBuiltIn: true
        ),
    ]
}
