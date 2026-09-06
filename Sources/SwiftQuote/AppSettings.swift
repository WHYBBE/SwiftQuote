import Foundation
import AppKit

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
    /// 每个字符一个颜色（hex 数组），不足时循环使用
    @Published var colors: [String] {
        didSet { UserDefaults.standard.set(colors, forKey: "colors") }
    }
    @Published var history: [String] {
        didSet { UserDefaults.standard.set(history, forKey: "history") }
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
        colors = d.stringArray(forKey: "colors") ?? ["#FFFFFF"]
        history = d.stringArray(forKey: "history") ?? []
    }

    var displayText: String { prefix + text + suffix }

    var font: NSFont {
        bold ? .boldSystemFont(ofSize: fontSize) : .systemFont(ofSize: fontSize)
    }

    var nsColors: [NSColor] {
        colors.compactMap { NSColor(hex: $0) }
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
