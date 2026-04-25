import CoreAudioKit
import AudioToolbox

/// The principal class for the AU extension.
/// AUViewController handles beginRequest(with:) internally — this is required.
/// It also conforms to AUAudioUnitFactory to create the audio unit.
public class MIDISyncViewController: AUViewController, AUAudioUnitFactory {

    var audioUnit: MIDISyncAudioUnit?

    public func createAudioUnit(with componentDescription: AudioComponentDescription) throws -> AUAudioUnit {
        let au = try MIDISyncAudioUnit(componentDescription: componentDescription, options: [])
        audioUnit = au
        return au
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        // Minimal view — Logic shows a generic placeholder for AU without custom UI
        view = NSView(frame: NSRect(x: 0, y: 0, width: 200, height: 40))
    }
}
