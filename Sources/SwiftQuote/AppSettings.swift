import Foundation
import AppKit
import ServiceManagement

/// 一个颜色条目：稳定 id（用于 SwiftUI 列表身份）+ 颜色 hex
struct ColorEntry: Identifiable, Codable, Equatable {
    var id = UUID()
    var hex: String
}

final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @Published var text: String {
        didSet { UserDefaults.standard.set(text, forKey: "text"); onDisplayChange?() }
    }
    @Published var prefix: String {
        didSet { UserDefaults.standard.set(prefix, forKey: "prefix"); onDisplayChange?() }
    }
    @Published var suffix: String {
        didSet { UserDefaults.standard.set(suffix, forKey: "suffix"); onDisplayChange?() }
    }
    @Published var trackHistory: Bool {
        didSet { UserDefaults.standard.set(trackHistory, forKey: "trackHistory") }
    }
    @Published var maxWidth: Double {
        didSet { UserDefaults.standard.set(maxWidth, forKey: "maxWidth"); onDisplayChange?() }
    }
    @Published var fontSize: Double {
        didSet { UserDefaults.standard.set(fontSize, forKey: "fontSize"); onDisplayChange?() }
    }
    @Published var bold: Bool {
        didSet { UserDefaults.standard.set(bold, forKey: "bold"); onDisplayChange?() }
    }
    /// 每个字符一个颜色，不足时循环使用
    @Published var colorEntries: [ColorEntry] {
        didSet {
            if let data = try? JSONEncoder().encode(colorEntries) {
                UserDefaults.standard.set(data, forKey: "colorEntries")
            }
            onDisplayChange?()
        }
    }
    /// 自适应菜单栏：开启后按菜单栏深浅自动切换两套颜色
    @Published var adaptiveColors: Bool {
        didSet { UserDefaults.standard.set(adaptiveColors, forKey: "adaptiveColors"); onDisplayChange?() }
    }
    /// 浅色菜单栏（深色壁纸）下使用的颜色
    @Published var lightBarColorEntries: [ColorEntry] {
        didSet {
            if let data = try? JSONEncoder().encode(lightBarColorEntries) {
                UserDefaults.standard.set(data, forKey: "lightBarColorEntries")
            }
            onDisplayChange?()
        }
    }
    /// 深色菜单栏（浅色壁纸）下使用的颜色
    @Published var darkBarColorEntries: [ColorEntry] {
        didSet {
            if let data = try? JSONEncoder().encode(darkBarColorEntries) {
                UserDefaults.standard.set(data, forKey: "darkBarColorEntries")
            }
            onDisplayChange?()
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
        adaptiveColors = d.object(forKey: "adaptiveColors") as? Bool ?? false
        func loadEntries(_ key: String, fallback: [ColorEntry]) -> [ColorEntry] {
            guard let data = d.data(forKey: key),
                  let decoded = try? JSONDecoder().decode([ColorEntry].self, from: data),
                  !decoded.isEmpty else { return fallback }
            return decoded
        }
        lightBarColorEntries = loadEntries("lightBarColorEntries", fallback: [ColorEntry(hex: "#000000")])
        darkBarColorEntries = loadEntries("darkBarColorEntries", fallback: [ColorEntry(hex: "#FFFFFF")])
        appearance = AppAppearance(rawValue: d.string(forKey: "appearance") ?? "") ?? .system
        language = AppLanguage(rawValue: d.string(forKey: "appLanguage") ?? "") ?? .system
    }

    // MARK: - 开机自启（SMAppService；裸跑 SwiftPM 可执行文件时不可用）

    /// 无 Bundle ID（非打包 App）时无法注册登录项
    var loginItemAvailable: Bool { Bundle.main.bundleIdentifier != nil }

    var launchAtLogin: Bool {
        get { SMAppService.mainApp.status == .enabled }
        set {
            guard loginItemAvailable else { return }
            do {
                if newValue { try SMAppService.mainApp.register() }
                else { try SMAppService.mainApp.unregister() }
            } catch {
                NSLog("登录项切换失败: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - 版本信息（SPM 裸跑无 Info.plist 时回退到开发版本 1.0）

    var versionString: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var buildString: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "dev"
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

    /// 菜单栏当前是否为深色（浅色壁纸下系统会把菜单栏压暗）
    var menuBarIsDark = false

    /// 显示内容变化时的回调（由 StatusBarController 设置）
    var onDisplayChange: (() -> Void)?

    /// 当前实际生效的颜色（自适应开启时按菜单栏深浅选一套）
    var effectiveColorEntries: [ColorEntry] {
        guard adaptiveColors else { return colorEntries }
        return menuBarIsDark ? darkBarColorEntries : lightBarColorEntries
    }

    var effectiveNSColors: [NSColor] {
        effectiveColorEntries.compactMap { NSColor(hex: $0.hex) }
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
