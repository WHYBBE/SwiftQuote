import AppKit

// 纯菜单栏应用：不走 SwiftUI App 生命周期（其 Settings scene 会创建一个空白窗口）
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)   // 纯菜单栏应用，不显示 Dock 图标
        AppSettings.shared.applyAppearance()    // 应用保存的主题
        StatusBarController.shared.setup()
    }
}
