import SwiftUI

@main
struct SwiftQuoteApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings { EmptyView() }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)   // 纯菜单栏应用，不显示 Dock 图标
        AppSettings.shared.applyAppearance()    // 应用保存的主题
        StatusBarController.shared.setup()
    }
}
