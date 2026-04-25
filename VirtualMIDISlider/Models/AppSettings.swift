import Foundation

struct AppSettings: Codable {
    var layoutMode: LayoutMode = .vertical
    var activePresetID: UUID?
}
