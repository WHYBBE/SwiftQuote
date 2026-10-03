import AppKit

/// 无边框输入面板：失去焦点自动隐藏（不提交），回车提交，Esc 取消
final class InputPanel: NSPanel, NSTextFieldDelegate {
    // 用 NoAutofillTextField 替代 NSTextField，关闭系统 AutoFill 建议（详见该文件注释）
    private let textField = NoAutofillTextField()
    private let settings = AppSettings.shared

    /// 隐藏后的回调：外部据此释放本面板（连同 NSTextField），回收视图树。
    var onDismiss: (() -> Void)?

    /// 用于取消尚未执行的 onDismiss（例如关闭后立刻又重新打开面板）。
    private var dismissID = 0

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

        textField.placeholderString = settings.strings.inputPlaceholder
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

    deinit {
        // 面板现在会被释放（见 StatusBarController.showInputPanel），需移除观察者，
        // 否则通知中心对已释放对象的引用会导致崩溃。
        NotificationCenter.default.removeObserver(self)
    }

    override var canBecomeKey: Bool { true }

    func show(near button: NSStatusBarButton?) {
        dismissID += 1   // 取消可能待执行的 onDismiss
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
        dismiss()
    }

    private func commit() {
        let value = textField.stringValue
        if !value.isEmpty, value != settings.text {
            settings.text = value
            settings.pushHistory(value)
        }
        dismiss()
    }

    /// 隐藏输入框，并异步通知外部释放本面板。若在此之前又调用了 `show`，
    /// 回调会被取消（避免释放正在显示的面板）。
    private func dismiss() {
        orderOut(nil)
        dismissID += 1
        let id = dismissID
        DispatchQueue.main.async { [weak self] in
            guard let self, self.dismissID == id else { return }
            self.onDismiss?()
        }
    }

    /// 拦截回车 / Esc
    func control(_ control: NSControl, textView: NSTextView,
                 doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(NSResponder.insertNewline(_:)) {
            commit()
            return true
        }
        if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
            dismiss()   // Esc：不提交
            return true
        }
        return false
    }
}
