import SwiftUI

struct SliderSettingsView: View {
    @State var config: SliderConfiguration
    let onSave: (SliderConfiguration) -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Slider Settings")
                .font(.headline)

            Form {
                TextField("Label", text: $config.label)
                    .textFieldStyle(.roundedBorder)

                Picker("CC Number", selection: $config.ccNumber) {
                    ForEach(0..<128, id: \.self) { cc in
                        let num = UInt8(cc)
                        Text("\(cc) - \(MIDIConstants.ccName(for: num))")
                            .tag(num)
                    }
                }

                Picker("MIDI Channel", selection: $config.channel) {
                    ForEach(0..<16, id: \.self) { ch in
                        Text("Channel \(ch + 1)").tag(UInt8(ch))
                    }
                }
            }
            .formStyle(.grouped)
            .frame(width: 350, height: 200)

            HStack {
                Button("Cancel", action: onCancel)
                    .keyboardShortcut(.cancelAction)
                Button("Save") { onSave(config) }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
    }
}
