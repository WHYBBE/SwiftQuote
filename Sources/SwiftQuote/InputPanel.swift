import AppKit

/// 无边框输入面板：失去焦点自动隐藏（不提交），回车提交，Esc 取消。
/// 输入框下方显示最近的历史记录，点击某条即可直接应用。
final class InputPanel: NSPanel, NSTextFieldDelegate {
    // 用 NoAutofillTextField 替代 NSTextField，关闭系统 AutoFill 建议（详见该文件注释）
    private let textField = NoAutofillTextField()
    private let settings = AppSettings.shared

    /// 隐藏后的回调：外部据此释放本面板（连同 NSTextField），回收视图树。
    var onDismiss: (() -> Void)?

    /// 用于取消尚未执行的 onDismiss（例如关闭后立刻又重新打开面板）。
    private var dismissID = 0

    private static let panelWidth: CGFloat = 260
    private static let fieldHeight: CGFloat = 36
    private static let headerHeight: CGFloat = 18
    private static let rowHeight: CGFloat = 24
    private static let historyLimit = 5

    init() {
        // 历史记录（受“跟踪历史”开关控制，最多显示 5 条）
        let historyItems = (settings.trackHistory ? Array(settings.history.prefix(Self.historyLimit)) : [])
        let historyHeight = historyItems.isEmpty
            ? 0
            : 1 + Self.headerHeight + CGFloat(historyItems.count) * Self.rowHeight

        super.init(
            contentRect: NSRect(x: 0, y: 0, width: Self.panelWidth, height: Self.fieldHeight + historyHeight),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered, defer: false)
        isFloatingPanel = true
        level = .popUpMenu
        backgroundColor = .clear
        isOpaque = false
        hasShadow = true
        animationBehavior = .none

        let bg = NSVisualEffectView()
        bg.material = .menu
        bg.state = .active
        bg.wantsLayer = true
        bg.layer?.cornerRadius = 8
        bg.layer?.cornerCurve = .continuous
        bg.layer?.masksToBounds = true   // 裁剪子视图，避免内容从圆角处漏出
        bg.maskImage = Self.roundedMask(radius: 8)   // 毛玻璃本体也裁成圆角
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
            textField.topAnchor.constraint(equalTo: bg.topAnchor, constant: 8),
            textField.heightAnchor.constraint(equalToConstant: 20),
        ])

        if !historyItems.isEmpty {
            addHistorySection(to: bg, items: historyItems)
        }

        // 失焦自动隐藏（不提交）
        NotificationCenter.default.addObserver(
            self, selector: #selector(onResignKey),
            name: NSWindow.didResignKeyNotification, object: self)
    }

    deinit {
        // 面板会被释放（见 StatusBarController.showInputPanel），需移除观察者，
        // 否则通知中心对已释放对象的引用会导致崩溃。
        NotificationCenter.default.removeObserver(self)
    }

    override var canBecomeKey: Bool { true }

    // MARK: - 历史记录区

    private func addHistorySection(to bg: NSView, items: [String]) {
        let separator = NSBox()
        separator.boxType = .separator
        separator.translatesAutoresizingMaskIntoConstraints = false
        bg.addSubview(separator)

        let header = NSTextField(labelWithString: settings.strings.historyHeader)
        header.font = .systemFont(ofSize: 11, weight: .semibold)
        header.textColor = .secondaryLabelColor
        header.translatesAutoresizingMaskIntoConstraints = false
        bg.addSubview(header)

        let rows = NSStackView()
        rows.orientation = .vertical
        rows.spacing = 0
        rows.alignment = .leading
        rows.translatesAutoresizingMaskIntoConstraints = false
        bg.addSubview(rows)

        for item in items {
            let row = HistoryRowView(value: item) { [weak self] value in
                self?.pick(value)
            }
            row.translatesAutoresizingMaskIntoConstraints = false
            rows.addArrangedSubview(row)
            NSLayoutConstraint.activate([
                row.heightAnchor.constraint(equalToConstant: Self.rowHeight),
                row.widthAnchor.constraint(equalTo: rows.widthAnchor),
            ])
        }

        NSLayoutConstraint.activate([
            separator.leadingAnchor.constraint(equalTo: bg.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: bg.trailingAnchor),
            separator.topAnchor.constraint(equalTo: bg.topAnchor, constant: Self.fieldHeight),
            separator.heightAnchor.constraint(equalToConstant: 1),

            header.leadingAnchor.constraint(equalTo: bg.leadingAnchor, constant: 12),
            header.trailingAnchor.constraint(lessThanOrEqualTo: bg.trailingAnchor, constant: -12),
            header.topAnchor.constraint(equalTo: separator.bottomAnchor),
            header.heightAnchor.constraint(equalToConstant: Self.headerHeight),

            rows.leadingAnchor.constraint(equalTo: bg.leadingAnchor),
            rows.trailingAnchor.constraint(equalTo: bg.trailingAnchor),
            rows.topAnchor.constraint(equalTo: header.bottomAnchor),
            rows.bottomAnchor.constraint(equalTo: bg.bottomAnchor),
        ])
    }

    private func pick(_ value: String) {
        settings.text = value
        settings.pushHistory(value)
        dismiss()
    }

    /// 生成圆角遮罩（用 capInsets 拉伸出中间区域），让 NSVisualEffectView 本体也呈圆角。
    private static func roundedMask(radius: CGFloat) -> NSImage {
        let edge = radius * 2 + 1
        let image = NSImage(size: NSSize(width: edge, height: edge), flipped: false) { rect in
            NSColor.black.setFill()
            NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).fill()
            return true
        }
        image.capInsets = NSEdgeInsets(top: radius, left: radius, bottom: radius, right: radius)
        image.resizingMode = .stretch
        return image
    }

    // MARK: - 显示 / 提交

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

/// 历史记录中的一行：悬停高亮，点击回调其文本。
private final class HistoryRowView: NSView {
    private let value: String
    private let onPick: (String) -> Void
    private var trackingArea: NSTrackingArea?

    init(value: String, onPick: @escaping (String) -> Void) {
        self.value = value
        self.onPick = onPick
        super.init(frame: .zero)
        wantsLayer = true

        let label = NSTextField(labelWithString: value)
        label.font = .systemFont(ofSize: 13)
        label.textColor = .labelColor
        label.lineBreakMode = .byTruncatingTail
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) 未实现") }

    /// 让整行接收鼠标事件（避免子标签截获）。
    override func hitTest(_ point: NSPoint) -> NSView? {
        let local = convert(point, from: superview)
        return bounds.contains(local) ? self : nil
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let trackingArea { removeTrackingArea(trackingArea) }
        let area = NSTrackingArea(rect: bounds,
                                  options: [.mouseEnteredAndExited, .activeAlways],
                                  owner: self, userInfo: nil)
        addTrackingArea(area)
        trackingArea = area
    }

    override func mouseEntered(with event: NSEvent) {
        layer?.backgroundColor = NSColor.selectedContentBackgroundColor.withAlphaComponent(0.25).cgColor
    }

    override func mouseExited(with event: NSEvent) {
        layer?.backgroundColor = nil
    }

    override func mouseDown(with event: NSEvent) {
        onPick(value)
    }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .pointingHand)
    }
}
