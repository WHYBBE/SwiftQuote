import AppKit

/// 无边框输入面板：失去焦点自动隐藏（不提交），回车提交，Esc 取消
final class InputPanel: NSPanel, NSTextFieldDelegate {
    private let textField = NSTextField()
    private let settings = AppSettings.shared

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 260, height: 36),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered, defer: false)
        isFloatingPanel = true
        level = .popUpMenu
        backgroundColor = .clear
        isOpaque = false
        hasShadow = true

        let bg = NSVisualEffectView()
        bg.material = .menu
        bg.state = .active
        bg.wantsLayer = true
        bg.layer?.cornerRadius = 8
        contentView = bg

        textField.placeholderString = "输入内容，回车确认"
        textField.isBezeled = false
        textField.drawsBackground = false
        textField.focusRingType = .none
        textField.font = .systemFont(ofSize: 14)
        textField.delegate = self
        textField.translatesAutoresizingMaskIntoConstraints = false
        bg.addSubview(textField)
        NSLayoutConstraint.activate([
            textField.leadingAnchor.constraint(equalTo: bg.leadingAnchor, constant: 10),
            textField.trailingAnchor.constraint(equalTo: bg.trailingAnchor, constant: -10),
            textField.centerYAnchor.constraint(equalTo: bg.centerYAnchor),
        ])

        // 失焦自动隐藏（不提交）
        NotificationCenter.default.addObserver(
            self, selector: #selector(onResignKey),
            name: NSWindow.didResignKeyNotification, object: self)
    }

    override var canBecomeKey: Bool { true }

    func show(near button: NSStatusBarButton?) {
        textField.stringValue = settings.text
        if let button, let window = button.window {
            var origin = window.frame.origin
            origin.y = window.frame.minY - frame.height - 6
            setFrameOrigin(origin)
        } else {
            center()
        }
        NSApp.activate(ignoringOtherApps: true)
        makeKeyAndOrderFront(nil)
        makeFirstResponder(textField)
        textField.selectText(nil)
    }

    @objc private func onResignKey() {
        textField.abortEditing()
        orderOut(nil)
    }

    private func commit() {
        let value = textField.stringValue
        if !value.isEmpty, value != settings.text {
            settings.text = value
            settings.pushHistory(value)
        }
        orderOut(nil)
    }

    /// 拦截回车 / Esc
    func control(_ control: NSControl, textView: NSTextView,
                 doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(NSResponder.insertNewline(_:)) {
            commit()
            return true
        }
        if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
            orderOut(nil)   // Esc：不提交
            return true
        }
        return false
    }
}
