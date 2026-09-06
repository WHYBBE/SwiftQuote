import Foundation

enum AppAppearance: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
}

enum AppLanguage: String, CaseIterable, Identifiable {
    case system, chinese, english
    var id: String { rawValue }
}

/// 界面多语言文案（中文 / English）
struct L {
    let isChinese: Bool

    private func t(_ zh: String, _ en: String) -> String { isChinese ? zh : en }

    // MARK: 菜单栏菜单
    var menuInput: String   { t("输入…", "Input…") }
    var menuSettings: String { t("设置…", "Settings…") }
    var menuQuit: String    { t("退出", "Quit") }
    var trackHistory: String { t("跟踪历史", "Track History") }
    var historyHeader: String { t("历史", "History") }
    var clearHistory: String { t("清除历史", "Clear History") }

    // MARK: 输入面板
    var inputPlaceholder: String { t("输入内容，回车确认", "Type and press Return") }

    // MARK: 设置窗口 Tab
    var tabGeneral: String { t("通用", "General") }
    var tabText: String { t("文字", "Text") }
    var tabColors: String  { t("颜色", "Colors") }
    var tabHistory: String { t("历史记录", "History") }

    // MARK: 通用设置
    var groupText: String   { t("文字", "Text") }
    var prefix: String      { t("前缀", "Prefix") }
    var suffix: String      { t("后缀", "Suffix") }
    var bold: String        { t("加粗", "Bold") }
    var fontSize: String    { t("文字大小", "Font Size") }
    var maxWidth: String    { t("最大宽度", "Max Width") }
    var groupAppearance: String { t("主题", "Appearance") }
    var appearanceSystem: String { t("跟随系统", "System") }
    var appearanceLight: String  { t("浅色", "Light") }
    var appearanceDark: String   { t("深色", "Dark") }
    var groupLanguage: String { t("语言", "Language") }
    var languageSystem: String  { t("跟随系统", "System") }
    var groupStartup: String  { t("启动", "Startup") }
    var launchAtLogin: String { t("开机自启", "Launch at Login") }
    var launchAtLoginUnavailable: String { t("需以打包的 App 形式运行才可用", "Requires running as a bundled app") }
    var menuAbout: String     { t("关于", "About") }
    var aboutTitle: String    { t("关于 SwiftQuote", "About SwiftQuote") }
    var aboutDescription: String { t("轻量级 macOS 菜单栏自定义文字应用", "A lightweight macOS menu bar custom text app") }
    func aboutVersion(_ v: String, _ b: String) -> String {
        t("版本 \(v) (\(b))", "Version \(v) (\(b))")
    }
    let repositoryURL = "https://github.com/WHYBBE/SwiftQuote"
    var groupPresets: String { t("预设", "Presets") }
    var apply: String       { t("应用", "Apply") }

    // MARK: 颜色设置
    var addColor: String    { t("添加颜色", "Add Color") }
    var add: String         { t("添加", "Add") }
    var colorsHint: String {
        t("颜色依次循环应用到每个字符；拖动可排序", "Colors cycle through characters; drag to reorder")
    }

    // MARK: 历史记录
    var clearAll: String  { t("清空全部", "Clear All") }
    var noHistory: String { t("暂无历史记录", "No history yet") }
    var current: String   { t("当前", "Current") }
}
