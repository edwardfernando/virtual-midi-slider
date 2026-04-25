import SwiftUI

struct MIDISliderView: View {
    let config: SliderConfiguration
    let layoutMode: LayoutMode
    let onValueChanged: (UInt8) -> Void
    let onSettingsTapped: () -> Void
    let onRemove: (() -> Void)?

    @State private var isDragging = false

    private var normalizedValue: Double {
        Double(config.value) / 127.0
    }

    var body: some View {
        VStack(spacing: 6) {
            // Value display
            Text("\(config.value)")
                .font(.system(.title3, design: .monospaced, weight: .medium))
                .foregroundStyle(isDragging ? .primary : .secondary)

            // Slider track
            sliderTrack
                .frame(
                    minWidth: layoutMode == .vertical ? 60 : 200,
                    minHeight: layoutMode == .vertical ? 200 : 50
                )

            // Label
            VStack(spacing: 2) {
                Text(config.displayLabel)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                Text(config.displayChannel)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            // Controls
            HStack(spacing: 8) {
                Button(action: onSettingsTapped) {
                    Image(systemName: "gearshape")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)

                if let onRemove {
                    Button(action: onRemove) {
                        Image(systemName: "minus.circle")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
    }

    private var sliderTrack: some View {
        GeometryReader { geo in
            ZStack(alignment: layoutMode == .vertical ? .bottom : .leading) {
                // Track background
                RoundedRectangle(cornerRadius: 8)
                    .fill(.quaternary)

                // Fill
                RoundedRectangle(cornerRadius: 8)
                    .fill(sliderColor)
                    .frame(
                        width: layoutMode == .vertical ? nil : fillLength(in: geo),
                        height: layoutMode == .vertical ? fillLength(in: geo) : nil
                    )

                // Thumb line
                thumbIndicator(in: geo)
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .local)
                    .onChanged { drag in
                        isDragging = true
                        let normalized = normalizedFromLocation(drag.location, in: geo)
                        let clamped = UInt8(max(0, min(127, Int(round(normalized * 127)))))
                        onValueChanged(clamped)
                    }
                    .onEnded { _ in
                        isDragging = false
                    }
            )
        }
    }

    private var sliderColor: Color {
        if isDragging {
            return .accentColor
        }
        return .accentColor.opacity(0.7)
    }

    private func fillLength(in geo: GeometryProxy) -> CGFloat {
        let total = layoutMode == .vertical ? geo.size.height : geo.size.width
        return total * normalizedValue
    }

    private func normalizedFromLocation(_ location: CGPoint, in geo: GeometryProxy) -> Double {
        if layoutMode == .vertical {
            let clamped = max(0, min(geo.size.height, location.y))
            return 1.0 - (clamped / geo.size.height)
        } else {
            let clamped = max(0, min(geo.size.width, location.x))
            return clamped / geo.size.width
        }
    }

    private func thumbIndicator(in geo: GeometryProxy) -> some View {
        let position: CGFloat
        if layoutMode == .vertical {
            position = geo.size.height * (1.0 - normalizedValue)
        } else {
            position = geo.size.width * normalizedValue
        }

        return Group {
            if layoutMode == .vertical {
                Rectangle()
                    .fill(.white.opacity(0.9))
                    .frame(height: 3)
                    .shadow(color: .black.opacity(0.3), radius: 1, y: 1)
                    .offset(y: position - geo.size.height / 2)
            } else {
                Rectangle()
                    .fill(.white.opacity(0.9))
                    .frame(width: 3)
                    .shadow(color: .black.opacity(0.3), radius: 1, x: 1)
                    .offset(x: position - geo.size.width / 2)
            }
        }
    }
}
