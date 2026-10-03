import AppKit

// 关键：必须在创建 NSApplication 之前注册。
//
// macOS 26 (Tahoe) 起，AppKit 的 AutoFill 启发式控制器会在每次文本输入时持续运行，
// 长时间使用后导致卡顿、CPU/内存增长（Ghostty、Electron、Chromium、Alacritty 等均受影响）。
// `NSAutoFillHeuristicControllerEnabled` 是 AppKit 的未公开 UserDefaults 开关，设为 false
// 可关闭该进程内的启发式控制器；Ghostty/Electron 就是这么做的。
//
// ⚠️ 边界：它只能关掉「进程内的启发式控制器」，**无法阻止**系统 launchd 为 App 单独拉起的
// 独立 AutoFill helper 进程（活动监视器里的 `AutoFill (SwiftQuote)`，实为
// SafariPlatformSupport.Helper / AutoFillPanelService）。要彻底不出现该进程，只能在
// 系统设置 → 通用 → 自动填充与密码 里关闭「自动填充密码和通行密钥」。
// 参见 kitty #9299 / #9463、ghostty PR #8625。
UserDefaults.standard.register(defaults: ["NSAutoFillHeuristicControllerEnabled": false])

// 纯菜单栏应用：不走 SwiftUI App 生命周期（其 Settings scene 会创建一个空白窗口）
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)   // 纯菜单栏应用，不显示 Dock 图标
        AppSettings.shared.applyAppearance()    // 应用保存的主题
        StatusBarController.shared.setup()
    }
}
