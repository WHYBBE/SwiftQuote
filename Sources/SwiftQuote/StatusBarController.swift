import AppKit
import SwiftUI

final class StatusBarController: NSObject, ObservableObject {
    static let shared = StatusBarController()

    private var statusItem: NSStatusItem!
    private var inputPanel: InputPanel?
    private var settingsWindow: NSWindow?
    private let settings = AppSettings.shared
    private var perCharColors = false

    func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        guard let button = statusItem.button else { return }
        button.action = #selector(onClick(_:))
        button.target = self
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        refreshTitle()

        NotificationCenter.default.addObserver(
            self, selector: #selector(refreshTitle),
            name: UserDefaults.didChangeNotification, object: nil)
    }

    @objc private func refreshTitle() {
        guard let button = statusItem?.button else { return }
        let str = NSMutableAttributedString()
        let colors = settings.nsColors
        let full = settings.displayText
        for (i, ch) in full.enumerated() {
            let color = colors.isEmpty ? .white : colors[i % colors.count]
            str.append(NSAttributedString(
                string: String(ch),
                attributes: [.font: settings.font, .foregroundColor: color]))
        }
        button.attributedTitle = str
        statusItem.length = min(button.attributedTitle.size().width + 12, settings.maxWidth)
    }

    @objc private func onClick(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }
        if event.type == .rightMouseUp {
            showInputPanel()
        } else {
            showMenu()
        }
    }

    // MARK: - 左键菜单
    private func showMenu() {
        let menu = NSMenu()

        let input = NSMenuItem(title: "输入…", action: #selector(onInput), keyEquivalent: "")
        input.target = self
        input.image = NSImage(systemSymbolName: "pencil", accessibilityDescription: nil)
        menu.addItem(input)

        let settingsItem = NSMenuItem(title: "设置…", action: #selector(onSettings), keyEquivalent: ",")
        settingsItem.target = self
        settingsItem.image = NSImage(systemSymbolName: "gearshape", accessibilityDescription: nil)
        menu.addItem(settingsItem)

        let historyToggle = NSMenuItem(title: "跟踪历史", action: #selector(onToggleHistory), keyEquivalent: "")
        historyToggle.target = self
        historyToggle.state = settings.trackHistory ? .on : .off
        menu.addItem(historyToggle)

        if settings.trackHistory && !settings.history.isEmpty {
            menu.addItem(.separator())
            historyHeaderMenu(menu)
        }

        menu.addItem(.separator())
        let quit = NSMenuItem(title: "退出", action: #selector(onQuit), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    private func historyHeaderMenu(_ menu: NSMenu) {
        let header = NSMenuItem(title: "历史", action: nil, keyEquivalent: "")
        header.isEnabled = false
        menu.addItem(header)
        for item in settings.history {
            let mi = NSMenuItem(title: item, action: #selector(onHistoryItem(_:)), keyEquivalent: "")
            mi.target = self
            mi.representedObject = item
            menu.addItem(mi)
        }
        let clear = NSMenuItem(title: "清除历史", action: #selector(onClearHistory), keyEquivalent: "")
        clear.target = self
        menu.addItem(clear)
    }

    @objc private func onHistoryItem(_ sender: NSMenuItem) {
        guard let value = sender.representedObject as? String else { return }
        settings.text = value
    }

    @objc private func onClearHistory() {
        settings.history = []
    }

    @objc private func onToggleHistory() {
        settings.trackHistory.toggle()
    }

    @objc private func onInput() {
        showInputPanel()
    }

    @objc private func onSettings() {
        showSettings()
    }

    @objc private func onQuit() {
        NSApp.terminate(nil)
    }

    // MARK: - 输入面板
    private func showInputPanel() {
        if inputPanel == nil {
            inputPanel = InputPanel()
        }
        inputPanel?.show(near: statusItem.button)
    }

    // MARK: - 设置窗口
    private func showSettings() {
        if settingsWindow == nil {
            let view = SettingsView()
                .environmentObject(AppSettings.shared)
            let hosting = NSHostingController(rootView: view)
            let win = NSWindow(contentViewController: hosting)
            win.title = "SwiftQuote 设置"
            win.styleMask = [.titled, .closable]
            win.setContentSize(NSSize(width: 420, height: 560))
            settingsWindow = win
        }
        settingsWindow?.center()
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
