import AppKit
import SwiftUI
import Combine

/// 系统偏好设置风格窗口：NSTabViewController 的 toolbar 模式（液态玻璃工具栏）
final class SettingsWindowController: NSWindowController, NSWindowDelegate {

    private var items: [NSTabViewItem] = []
    private var cancellables = Set<AnyCancellable>()

    init() {
        let settings = AppSettings.shared
        let s = settings.strings

        func makeHosting(_ view: some View) -> NSViewController {
            let vc = NSHostingController(rootView: view.environmentObject(settings))
            vc.preferredContentSize = NSSize(width: 440, height: 600)
            return vc
        }

        let views: [() -> NSViewController] = [
            { makeHosting(GeneralSettingsView()) },
            { makeHosting(TextSettingsView()) },
            { makeHosting(ColorsSettingsView()) },
            { makeHosting(HistorySettingsView()) },
        ]
        let tabInfo: [(String, String)] = [
            (s.tabGeneral, "gearshape"),
            (s.tabText, "textformat"),
            (s.tabColors, "paintpalette"),
            (s.tabHistory, "clock"),
        ]

        let tabController = NSTabViewController()
        tabController.tabStyle = .toolbar
        items = zip(tabInfo, views).map { (info, build) in
            let (label, symbol) = info
            let item = NSTabViewItem(viewController: build())
            item.label = label
            item.image = NSImage(systemSymbolName: symbol, accessibilityDescription: label)
            tabController.addTabViewItem(item)
            return item
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 440, height: 600),
            styleMask: [.titled, .closable],
            backing: .buffered, defer: false)
        window.title = s.tabGeneral
        window.contentViewController = tabController
        window.center()
        // 关闭后释放整个窗口与视图树，回收内存
        window.isReleasedWhenClosed = true

        super.init(window: window)
        window.delegate = self

        // Tab 切换时更新窗口标题
        tabController.publisher(for: \.selectedTabViewItemIndex)
            .sink { [weak self] index in
                guard let self, self.items.indices.contains(index) else { return }
                self.window?.title = self.items[index].label
            }
            .store(in: &cancellables)

        // 语言切换时更新 Tab 标签与窗口标题
        settings.$language.sink { [weak self] _ in
            guard let self else { return }
            let labels = [
                settings.strings.tabGeneral,
                settings.strings.tabText,
                settings.strings.tabColors,
                settings.strings.tabHistory,
            ]
            for (item, label) in zip(self.items, labels) {
                item.label = label
            }
            self.window?.title = labels[tabController.selectedTabViewItemIndex]
        }
        .store(in: &cancellables)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) 未实现")
    }

    func windowWillClose(_ notification: Notification) {
        // 通知 StatusBarController 释放本控制器（异步避免在 delegate 回调中自释放）
        DispatchQueue.main.async {
            StatusBarController.shared.settingsWindowDidClose()
        }
    }
}
