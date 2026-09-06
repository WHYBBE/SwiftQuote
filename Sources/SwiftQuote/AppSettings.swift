import Foundation
import AppKit

/// 一个颜色条目：稳定 id（用于 SwiftUI 列表身份）+ 颜色 hex
struct ColorEntry: Identifiable, Codable, Equatable {
    var id = UUID()
    var hex: String
}

final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @Published var text: String {
        didSet { UserDefaults.standard.set(text, forKey: "text") }
    }
    @Published var prefix: String {
        didSet { UserDefaults.standard.set(prefix, forKey: "prefix") }
    }
    @Published var suffix: String {
        didSet { UserDefaults.standard.set(suffix, forKey: "suffix") }
    }
    @Published var trackHistory: Bool {
        didSet { UserDefaults.standard.set(trackHistory, forKey: "trackHistory") }
    }
    @Published var maxWidth: Double {
        didSet { UserDefaults.standard.set(maxWidth, forKey: "maxWidth") }
    }
    @Published var fontSize: Double {
        didSet { UserDefaults.standard.set(fontSize, forKey: "fontSize") }
    }
    @Published var bold: Bool {
        didSet { UserDefaults.standard.set(bold, forKey: "bold") }
    }
    /// 每个字符一个颜色，不足时循环使用
    @Published var colorEntries: [ColorEntry] {
        didSet {
            if let data = try? JSONEncoder().encode(colorEntries) {
                UserDefaults.standard.set(data, forKey: "colorEntries")
            }
        }
    }
    @Published var history: [String] {
        didSet { UserDefaults.standard.set(history, forKey: "history") }
    }
    @Published var appearance: AppAppearance {
        didSet {
            UserDefaults.standard.set(appearance.rawValue, forKey: "appearance")
            applyAppearance()
        }
    }
    @Published var language: AppLanguage {
        didSet { UserDefaults.standard.set(language.rawValue, forKey: "appLanguage") }
    }

    private init() {
        let d = UserDefaults.standard
        text = d.string(forKey: "text") ?? "Aloha!"
        prefix = d.string(forKey: "prefix") ?? "["
        suffix = d.string(forKey: "suffix") ?? "]"
        trackHistory = d.object(forKey: "trackHistory") as? Bool ?? true
        maxWidth = d.object(forKey: "maxWidth") as? Double ?? 200
        fontSize = d.object(forKey: "fontSize") as? Double ?? 13
        bold = d.object(forKey: "bold") as? Bool ?? true
        if let data = d.data(forKey: "colorEntries"),
           let decoded = try? JSONDecoder().decode([ColorEntry].self, from: data),
           !decoded.isEmpty {
            colorEntries = decoded
        } else {
            // 兼容旧版本存的 [String]
            let legacy = d.stringArray(forKey: "colors") ?? ["#FFFFFF"]
            colorEntries = legacy.map { ColorEntry(hex: $0) }
        }
        history = d.stringArray(forKey: "history") ?? []
        appearance = AppAppearance(rawValue: d.string(forKey: "appearance") ?? "") ?? .system
        language = AppLanguage(rawValue: d.string(forKey: "appLanguage") ?? "") ?? .system
    }

    func applyAppearance() {
        switch appearance {
        case .system: NSApp.appearance = nil
        case .light:  NSApp.appearance = NSAppearance(named: .aqua)
        case .dark:   NSApp.appearance = NSAppearance(named: .darkAqua)
        }
    }

    var isChinese: Bool {
        switch language {
        case .chinese: return true
        case .english: return false
        case .system:
            return (Locale.preferredLanguages.first ?? "").hasPrefix("zh")
        }
    }

    /// 当前语言下的文案
    var strings: L { L(isChinese: isChinese) }

    var displayText: String { prefix + text + suffix }

    var font: NSFont {
        bold ? .boldSystemFont(ofSize: fontSize) : .systemFont(ofSize: fontSize)
    }

    var nsColors: [NSColor] {
        colorEntries.compactMap { NSColor(hex: $0.hex) }
    }

    func pushHistory(_ value: String) {
        guard trackHistory, !value.isEmpty else { return }
        history.removeAll { $0 == value }
        history.insert(value, at: 0)
        if history.count > 10 { history = Array(history.prefix(10)) }
    }
}

struct Preset: Identifiable {
    let id = UUID()
    let name: String
    let text: String
    let prefix: String
    let suffix: String

    static let all: [Preset] = [
        .init(name: "Aloha!", text: "Aloha!", prefix: "[", suffix: "]"),
        .init(name: "时间占位", text: "♥", prefix: "", suffix: ""),
        .init(name: "工作中…", text: "工作中…", prefix: "⦿ ", suffix: ""),
        .init(name: "免打扰", text: "请勿打扰", prefix: "🔕 ", suffix: ""),
        .init(name: "Coffee", text: "Coffee", prefix: "☕️ ", suffix: ""),
        .init(name: "日期", text: "", prefix: "「", suffix: "」"),
    ]
}

extension NSColor {
    convenience init?(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespaces)
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let v = UInt64(s, radix: 16) else { return nil }
        self.init(
            red: CGFloat((v >> 16) & 0xFF) / 255,
            green: CGFloat((v >> 8) & 0xFF) / 255,
            blue: CGFloat(v & 0xFF) / 255,
            alpha: 1
        )
    }

    var hexString: String {
        guard let c = usingColorSpace(.sRGB) else { return "#FFFFFF" }
        let r = Int((c.redComponent * 255).rounded())
        let g = Int((c.greenComponent * 255).rounded())
        let b = Int((c.blueComponent * 255).rounded())
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
