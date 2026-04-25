import AudioToolbox
import AVFAudio
import CoreMIDI

@objc public class MIDISyncAudioUnit: AUAudioUnit {
    private var midiClient: MIDIClientRef = 0
    private var outputPort: MIDIPortRef = 0
    private var destinationEndpoint: MIDIEndpointRef = 0
    private var _outputBusArray: AUAudioUnitBusArray!
    private var midiReady = false

    public override init(
        componentDescription: AudioComponentDescription,
        options: AudioComponentInstantiationOptions = []
    ) throws {
        try super.init(componentDescription: componentDescription, options: options)

        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!
        let outputBus = try AUAudioUnitBus(format: format)
        _outputBusArray = AUAudioUnitBusArray(audioUnit: self, busType: .output, busses: [outputBus])
    }

    public override var outputBusses: AUAudioUnitBusArray {
        return _outputBusArray
    }

    public override func allocateRenderResources() throws {
        try super.allocateRenderResources()
        DispatchQueue.global(qos: .utility).async { [weak self] in
            self?.setupMIDI()
        }
    }

    public override func deallocateRenderResources() {
        super.deallocateRenderResources()
        teardownMIDI()
    }

    private func setupMIDI() {
        guard !midiReady else { return }
        let status = MIDIClientCreate("MIDISyncAU" as CFString, nil, nil, &midiClient)
        guard status == noErr else { return }
        let portStatus = MIDIOutputPortCreate(midiClient, "MIDISyncAU Out" as CFString, &outputPort)
        guard portStatus == noErr else { return }
        findDestination()
        midiReady = true
    }

    private func teardownMIDI() {
        if outputPort != 0 { MIDIPortDispose(outputPort); outputPort = 0 }
        if midiClient != 0 { MIDIClientDispose(midiClient); midiClient = 0 }
        midiReady = false
        destinationEndpoint = 0
    }

    private func findDestination() {
        let destCount = MIDIGetNumberOfDestinations()
        for i in 0..<destCount {
            let endpoint = MIDIGetDestination(i)
            var name: Unmanaged<CFString>?
            MIDIObjectGetStringProperty(endpoint, kMIDIPropertyName, &name)
            if let n = name?.takeRetainedValue() as String?, n == "VirtualMIDISlider In" {
                destinationEndpoint = endpoint
                return
            }
        }
    }

    public override var internalRenderBlock: AUInternalRenderBlock {
        return { [weak self] actionFlags, timestamp, frameCount, outputBusNumber, outputData, renderEvent, pullInputBlock in

            guard let self = self, self.midiReady, self.destinationEndpoint != 0 else {
                return noErr
            }

            let outputPort = self.outputPort
            let dest = self.destinationEndpoint

            var eventPtr: UnsafePointer<AURenderEvent>? = renderEvent
            while let event = eventPtr {
                if event.pointee.head.eventType == .MIDI {
                    let midiEvent = UnsafeRawPointer(event).assumingMemoryBound(to: AUMIDIEvent.self)
                    let length = Int(midiEvent.pointee.length)

                    if length >= 3 {
                        let data = midiEvent.pointee.data
                        let statusByte = data.0

                        if statusByte & 0xF0 == 0xB0 {
                            var packetList = MIDIPacketList()
                            let packet = MIDIPacketListInit(&packetList)
                            let bytes: [UInt8] = [data.0, data.1, data.2]
                            MIDIPacketListAdd(&packetList, 1024, packet, 0, 3, bytes)
                            MIDISend(outputPort, dest, &packetList)
                        }
                    }
                }

                eventPtr = UnsafePointer(event.pointee.head.next)
            }

            return noErr
        }
    }

    deinit {
        teardownMIDI()
    }
}
