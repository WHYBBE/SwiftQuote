import AppKit
import SwiftUI
import Combine

/// 系统偏好设置风格窗口：NSTabViewController 的 toolbar 模式
final class SettingsWindowController: NSWindowController {

    private var items: [NSTabViewItem] = []
    private var cancellables = Set<AnyCancellable>()

    init() {
        let settings = AppSettings.shared
        let s = settings.strings

        func makeTab(_ view: some View,
                     label: String,
                     symbol: String) -> NSTabViewItem {
            let vc = NSHostingController(rootView: view.environmentObject(settings))
            vc.preferredContentSize = NSSize(width: 440, height: 600)
            let item = NSTabViewItem(viewController: vc)
            item.label = label
            item.image = NSImage(systemSymbolName: symbol, accessibilityDescription: label)
            return item
        }

        let generalItem = makeTab(GeneralSettingsView(), label: s.tabGeneral, symbol: "gearshape")
        let textItem    = makeTab(TextSettingsView(),    label: s.tabText,    symbol: "textformat")
        let colorsItem  = makeTab(ColorsSettingsView(),  label: s.tabColors,  symbol: "paintpalette")
        let historyItem = makeTab(HistorySettingsView(), label: s.tabHistory, symbol: "clock")
        items = [generalItem, textItem, colorsItem, historyItem]

        let tabController = NSTabViewController()
        tabController.tabStyle = .toolbar
        items.forEach { tabController.addTabViewItem($0) }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 440, height: 600),
            styleMask: [.titled, .closable],
            backing: .buffered, defer: false)
        window.title = s.tabGeneral
        window.contentViewController = tabController
        window.center()

        super.init(window: window)

        // Tab 切换时更新窗口标题（不能直接改 tabView.delegate，用 KVO 代替）
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
}
