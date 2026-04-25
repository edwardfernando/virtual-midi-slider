import SwiftUI

@main
struct VirtualMIDISliderApp: App {
    @State private var viewModel: SliderBankViewModel

    init() {
        let midi = MIDIManager()
        let persistence = PersistenceManager()
        _viewModel = State(initialValue: SliderBankViewModel(midi: midi, persistence: persistence))
    }

    var body: some Scene {
        WindowGroup {
            SliderBankView(viewModel: viewModel)
        }
        .defaultSize(width: 700, height: 500)
    }
}
