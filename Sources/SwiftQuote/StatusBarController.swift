import AppKit
import SwiftUI

final class StatusBarController: NSObject, ObservableObject {
    static let shared = StatusBarController()

    private var statusItem: NSStatusItem!
    private var inputPanel: InputPanel?
    private var settingsWindowController: SettingsWindowController?
    private var aboutWindowController: AboutWindowController?
    private let settings = AppSettings.shared

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
        // 紧凑布局：长度 = 文字实际宽度（cell 内部零补白；剩余间距是系统项间距）
        statusItem.length = min(ceil(str.size().width), settings.maxWidth)
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

        let s = settings.strings
        let input = NSMenuItem(title: s.menuInput, action: #selector(onInput), keyEquivalent: "")
        input.target = self
        input.image = NSImage(systemSymbolName: "pencil", accessibilityDescription: nil)
        menu.addItem(input)

        let settingsItem = NSMenuItem(title: s.menuSettings, action: #selector(onSettings), keyEquivalent: ",")
        settingsItem.target = self
        settingsItem.image = NSImage(systemSymbolName: "gearshape", accessibilityDescription: nil)
        menu.addItem(settingsItem)

        let historyToggle = NSMenuItem(title: s.trackHistory, action: #selector(onToggleHistory), keyEquivalent: "")
        historyToggle.target = self
        historyToggle.state = settings.trackHistory ? .on : .off
        menu.addItem(historyToggle)

        let loginToggle = NSMenuItem(title: s.launchAtLogin, action: #selector(onToggleLogin), keyEquivalent: "")
        loginToggle.target = self
        loginToggle.state = settings.launchAtLogin ? .on : .off
        loginToggle.isEnabled = settings.loginItemAvailable   // SPM 裸跑时禁用
        menu.addItem(loginToggle)

        if settings.trackHistory && !settings.history.isEmpty {
            menu.addItem(.separator())
            historyHeaderMenu(menu)
        }

        menu.addItem(.separator())
        let about = NSMenuItem(title: s.menuAbout, action: #selector(onAbout), keyEquivalent: "")
        about.target = self
        menu.addItem(about)

        let quit = NSMenuItem(title: s.menuQuit, action: #selector(onQuit), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)

        statusItem.menu = menu
        statusItem.button?.performClick(nil)   // 由系统弹出，定位最精确
        statusItem.menu = nil
    }

    private func historyHeaderMenu(_ menu: NSMenu) {
        let header = NSMenuItem(title: settings.strings.historyHeader, action: nil, keyEquivalent: "")
        header.isEnabled = false
        menu.addItem(header)
        for item in settings.history.prefix(5) {
            let mi = NSMenuItem(title: item, action: #selector(onHistoryItem(_:)), keyEquivalent: "")
            mi.target = self
            mi.representedObject = item
            menu.addItem(mi)
        }
        let clear = NSMenuItem(title: settings.strings.clearHistory, action: #selector(onClearHistory), keyEquivalent: "")
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

    @objc private func onToggleLogin() {
        settings.launchAtLogin.toggle()
    }

    @objc private func onInput() {
        showInputPanel()
    }

    @objc private func onAbout() {
        if aboutWindowController == nil {
            aboutWindowController = AboutWindowController()
        }
        aboutWindowController?.showWindow(nil)
        aboutWindowController?.window?.center()
        NSApp.activate(ignoringOtherApps: true)
        aboutWindowController?.window?.makeKeyAndOrderFront(nil)
        aboutWindowController?.window?.orderFrontRegardless()
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
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController()
        }
        settingsWindowController?.showWindow(nil)
        settingsWindowController?.window?.center()
        NSApp.activate(ignoringOtherApps: true)
        // orderFrontRegardless 保证窗口提到最前（普通 accessory 应用 showWindow 可能落在其他窗口下）
        settingsWindowController?.window?.makeKeyAndOrderFront(nil)
        settingsWindowController?.window?.orderFrontRegardless()
    }
}
