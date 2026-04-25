import Foundation
import CoreMIDI

@Observable
final class MIDIManager {
    private var client: MIDIClientRef = 0
    private var virtualSource: MIDIEndpointRef = 0
    private var virtualDestination: MIDIEndpointRef = 0
    private var inputPort: MIDIPortRef = 0

    // Anti-feedback: track last sent CC with timestamp
    private var lastSent: [String: Date] = [:]
    private let feedbackSuppressionInterval: TimeInterval = 0.05 // 50ms

    var onCCReceived: ((UInt8, UInt8, UInt8) -> Void)? // (channel, cc, value)

    var isSetup: Bool = false
    var errorMessage: String?

    func setup() {
        let clientName = "VirtualMIDISlider" as CFString
        var status = MIDIClientCreate(clientName, { notification, _ in
            // Handle MIDI setup changes (devices added/removed)
        }, nil, &client)
        guard status == noErr else {
            errorMessage = "Failed to create MIDI client: \(status)"
            return
        }

        // Create virtual source — Logic Pro sees this as an input device
        status = MIDISourceCreate(client, "VirtualMIDISlider Out" as CFString, &virtualSource)
        guard status == noErr else {
            errorMessage = "Failed to create virtual MIDI source: \(status)"
            return
        }

        // Create virtual destination — receives MIDI sent directly to us
        status = MIDIDestinationCreateWithProtocol(
            client,
            "VirtualMIDISlider In" as CFString,
            ._1_0,
            &virtualDestination
        ) { [weak self] eventList, _ in
            self?.handleMIDIEventList(eventList)
        }
        guard status == noErr else {
            errorMessage = "Failed to create virtual MIDI destination: \(status)"
            return
        }

        // Also create an input port to listen to other MIDI sources
        status = MIDIInputPortCreateWithProtocol(
            client,
            "VirtualMIDISlider Listen" as CFString,
            ._1_0,
            &inputPort
        ) { [weak self] eventList, _ in
            self?.handleMIDIEventList(eventList)
        }
        if status == noErr {
            connectToAllSources()
        }

        isSetup = true
    }

    /// Connect input port to all existing MIDI sources (except our own)
    private func connectToAllSources() {
        let sourceCount = MIDIGetNumberOfSources()
        for i in 0..<sourceCount {
            let source = MIDIGetSource(i)
            // Skip our own virtual source to avoid feedback
            if source == virtualSource { continue }
            MIDIPortConnectSource(inputPort, source, nil)
        }
    }

    func sendCC(channel: UInt8, cc: UInt8, value: UInt8) {
        guard isSetup else { return }

        // Record for anti-feedback
        let key = "\(channel):\(cc)"
        lastSent[key] = Date()

        // Build MIDI 1.0 CC message bytes
        let statusByte = UInt8(0xB0) | (channel & 0x0F)

        var packetList = MIDIPacketList()
        let packet = MIDIPacketListInit(&packetList)
        let data: [UInt8] = [statusByte, cc & 0x7F, value & 0x7F]
        MIDIPacketListAdd(&packetList, 1024, packet, 0, 3, data)
        MIDIReceived(virtualSource, &packetList)
    }

    func teardown() {
        if inputPort != 0 {
            MIDIPortDispose(inputPort)
            inputPort = 0
        }
        if virtualSource != 0 {
            MIDIEndpointDispose(virtualSource)
            virtualSource = 0
        }
        if virtualDestination != 0 {
            MIDIEndpointDispose(virtualDestination)
            virtualDestination = 0
        }
        if client != 0 {
            MIDIClientDispose(client)
            client = 0
        }
        isSetup = false
    }

    private func handleMIDIEventList(_ eventListPtr: UnsafePointer<MIDIEventList>) {
        eventListPtr.unsafeSequence().forEach { event in
            let wordCount = Int(event.pointee.wordCount)
            guard wordCount > 0 else { return }
            withUnsafePointer(to: event.pointee.words) { wordsPtr in
                wordsPtr.withMemoryRebound(to: UInt32.self, capacity: wordCount) { buffer in
                    for i in 0..<wordCount {
                        parseWord(buffer[i])
                    }
                }
            }
        }
    }

    private func parseWord(_ word: UInt32) {
        let messageType = (word >> 28) & 0x0F

        // Type 2 = MIDI 1.0 channel voice (UMP format)
        if messageType == 0x02 {
            let statusByte = UInt8((word >> 16) & 0xFF)
            let data1 = UInt8((word >> 8) & 0xFF)
            let data2 = UInt8(word & 0xFF)

            if statusByte & 0xF0 == 0xB0 {
                let channel = statusByte & 0x0F
                let cc = data1 & 0x7F
                let value = data2 & 0x7F

                let key = "\(channel):\(cc)"
                if let sent = lastSent[key], Date().timeIntervalSince(sent) < feedbackSuppressionInterval {
                    return
                }

                Task { @MainActor in
                    self.onCCReceived?(channel, cc, value)
                }
            }
        }

        // Type 0 = Legacy byte stream
        if messageType == 0x00 {
            let byte1 = UInt8((word >> 16) & 0xFF)
            let byte2 = UInt8((word >> 8) & 0xFF)
            let byte3 = UInt8(word & 0xFF)

            if byte1 & 0xF0 == 0xB0 {
                let channel = byte1 & 0x0F
                let cc = byte2 & 0x7F
                let value = byte3 & 0x7F

                let key = "\(channel):\(cc)"
                if let sent = lastSent[key], Date().timeIntervalSince(sent) < feedbackSuppressionInterval {
                    return
                }

                Task { @MainActor in
                    self.onCCReceived?(channel, cc, value)
                }
            }
        }
    }

    deinit {
        teardown()
    }
}
