import AppKit
import SwiftUI

/// 系统偏好设置风格窗口：NSTabViewController 的 toolbar 模式
final class SettingsWindowController: NSWindowController {

    init() {
        let settings = AppSettings.shared

        let generalVC = NSHostingController(
            rootView: GeneralSettingsView().environmentObject(settings))
        generalVC.preferredContentSize = NSSize(width: 440, height: 600)
        let generalItem = NSTabViewItem(viewController: generalVC)
        generalItem.label = "设置"
        generalItem.image = NSImage(systemSymbolName: "gearshape", accessibilityDescription: "设置")

        let colorsVC = NSHostingController(
            rootView: ColorsSettingsView().environmentObject(settings))
        colorsVC.preferredContentSize = NSSize(width: 440, height: 600)
        let colorsItem = NSTabViewItem(viewController: colorsVC)
        colorsItem.label = "颜色"
        colorsItem.image = NSImage(systemSymbolName: "paintpalette", accessibilityDescription: "颜色")

        let historyVC = NSHostingController(
            rootView: HistorySettingsView().environmentObject(settings))
        historyVC.preferredContentSize = NSSize(width: 440, height: 600)
        let historyItem = NSTabViewItem(viewController: historyVC)
        historyItem.label = "历史记录"
        historyItem.image = NSImage(systemSymbolName: "clock", accessibilityDescription: "历史记录")

        let tabController = NSTabViewController()
        tabController.tabStyle = .toolbar
        tabController.addTabViewItem(generalItem)
        tabController.addTabViewItem(colorsItem)
        tabController.addTabViewItem(historyItem)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 440, height: 600),
            styleMask: [.titled, .closable],
            backing: .buffered, defer: false)
        window.title = generalItem.label
        window.contentViewController = tabController
        window.center()

        super.init(window: window)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) 未实现")
    }
}
