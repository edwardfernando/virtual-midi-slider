# Virtual MIDI Slider

A native macOS app that acts as a virtual MIDI CC controller with touch support, designed for use with Logic Pro and external touch monitors.

![macOS](https://img.shields.io/badge/macOS-14.0%2B-blue) ![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange) ![License](https://img.shields.io/badge/license-MIT-green)

## What is this?

Virtual MIDI Slider replaces physical MIDI fader controllers with an on-screen touch interface. It creates virtual MIDI ports that your DAW sees as a real MIDI controller — move the sliders to send MIDI CC (Modulation, Expression, Volume, etc.) to Logic Pro or any DAW that supports CoreMIDI.

It also includes a companion **AU MIDI FX plugin** that enables bidirectional sync — your sliders follow the CC data during playback.

## Features

- **Touch-friendly sliders** — large hit areas, zero-distance drag gesture, designed for external touch monitors
- **Virtual MIDI ports** — appears as "VirtualMIDISlider Out/In" in any DAW
- **Bidirectional sync** — companion MIDI FX plugin forwards CC from Logic back to the app
- **Configurable** — 1-16 sliders, each with custom CC number, MIDI channel, and label
- **Presets** — built-in presets (Orchestral, Synth, DJ, Minimal) + save your own
- **Layout options** — vertical or horizontal slider arrangement
- **Persistent settings** — configuration saved between sessions
- **Lightweight** — native SwiftUI, zero dependencies, ~1100 lines of Swift

## Requirements

- macOS 14.0 (Sonoma) or later
- Xcode 15+ (to build)
- Apple Developer account (free Personal Team is fine — needed for code signing the AU plugin)

## Building

1. Open `VirtualMIDISlider.xcodeproj` in Xcode
2. Select your development team in **Signing & Capabilities** for both targets:
   - `VirtualMIDISlider` (the app)
   - `MIDISyncAU` (the AU plugin extension)
3. Select the **VirtualMIDISlider** scheme
4. Build and Run (Cmd+R)

For the AU plugin to be recognized by Logic Pro, install the app to ~/Applications:

```bash
cp -R ~/Library/Developer/Xcode/DerivedData/VirtualMIDISlider-*/Build/Products/Debug/VirtualMIDISlider.app ~/Applications/
```

## Usage

### Sending CC to Logic Pro

1. Launch VirtualMIDISlider
2. Open Logic Pro — the app appears as a MIDI input device
3. Select or record-enable a Software Instrument track
4. Move sliders in the app — Logic receives MIDI CC

Logic listens to all MIDI inputs by default. Verify in **Logic Pro > Settings > MIDI > Inputs** that "VirtualMIDISlider Out" is enabled.

### Bidirectional sync (sliders follow playback)

The companion AU MIDI FX plugin forwards CC data from Logic back to the app during playback:

1. Make sure the VirtualMIDISlider app is running
2. In Logic, select a Software Instrument track
3. On the channel strip, click the **MIDI FX** slot (above the instrument)
4. Select **VirtualMIDISlider: Sync**
5. Record CC using the app's sliders — the data is stored in the MIDI region
6. Play back — the sliders follow the recorded CC values

> **Note:** The MIDI FX plugin syncs CC data that lives in **MIDI regions** (visible in the Piano Roll). Track automation (drawn in the automation lane) is handled internally by Logic and does not flow through MIDI FX plugins.

### Customizing sliders

- Click the **gear icon** below a slider to change its CC number, MIDI channel, or label
- Use the **+** button in the toolbar to add sliders (up to 16)
- Click the **minus icon** on a slider to remove it
- Toggle between vertical/horizontal layout with the layout button
- Save your configuration as a preset with the save button

### Built-in presets

| Preset | Sliders |
|--------|---------|
| Orchestral | CC1 (Mod Wheel), CC11 (Expression), CC7 (Volume), CC2 (Breath) |
| Synth | CC1 (Mod Wheel), CC74 (Cutoff), CC71 (Resonance), CC7 (Volume) |
| DJ | CC7 (Volume) on Channels 1-4 |
| Minimal | CC1 (Mod Wheel) |

## Architecture

```
VirtualMIDISlider/
├── App/                    # SwiftUI app entry point
├── Models/                 # SliderConfiguration, Preset, LayoutMode, AppSettings
├── MIDI/                   # MIDIManager (CoreMIDI), MIDIConstants
├── ViewModels/             # SliderBankViewModel (central state)
├── Views/                  # SwiftUI views (sliders, settings, presets)
├── Persistence/            # JSON config to ~/Library/Application Support/
└── Assets.xcassets/

MIDISyncAU/                 # AU MIDI FX plugin (app extension)
├── MIDISyncViewController  # AUViewController + AUAudioUnitFactory
├── MIDISyncAudioUnit       # AUAudioUnit subclass, forwards CC via CoreMIDI
└── Info.plist              # Audio component registration
```

- **SwiftUI + @Observable** for reactive UI
- **CoreMIDI** for virtual MIDI ports (no third-party dependencies)
- **AUv3 MIDI FX plugin** as an app extension for bidirectional sync
- **JSON persistence** to `~/Library/Application Support/VirtualMIDISlider/`

## Troubleshooting

**AU plugin doesn't appear in Logic:**
- Make sure you've built and run the app at least once from Xcode
- Copy the app to ~/Applications and launch it from there
- In Logic, go to **Logic Pro > Settings > Plug-in Manager** and rescan
- Clear AU cache: `rm -rf ~/Library/Caches/AudioUnitCache`

**Sliders don't move during playback:**
- Ensure the MIDI FX plugin "VirtualMIDISlider: Sync" is inserted on the track
- CC data must be in a **MIDI region** (Piano Roll), not track automation
- The VirtualMIDISlider app must be running

**Logic hangs on "scanning audio units":**
- Force quit Logic, clear AU cache: `rm -rf ~/Library/Caches/AudioUnitCache`
- Rebuild the app in Xcode and reinstall to ~/Applications

**Validate the AU plugin:**
```bash
auval -v aumi sync VmSl
```

## License

MIT
