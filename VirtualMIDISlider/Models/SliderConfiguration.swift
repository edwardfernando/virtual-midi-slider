import Foundation

struct SliderConfiguration: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var ccNumber: UInt8 = 1
    var channel: UInt8 = 0       // 0-15, displayed as 1-16
    var value: UInt8 = 0         // 0-127
    var label: String = ""       // user-editable, defaults to CC name

    var displayLabel: String {
        if !label.isEmpty { return label }
        return MIDIConstants.ccName(for: ccNumber)
    }

    var displayChannel: String {
        "Ch \(channel + 1)"
    }
}
