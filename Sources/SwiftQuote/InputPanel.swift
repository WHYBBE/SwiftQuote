import AppKit

/// 无边框输入面板：失去焦点自动隐藏（不提交），回车提交，Esc 取消。
/// 输入框下方显示历史记录（不含当前值），每行可点击应用或单独删除。
final class InputPanel: NSPanel, NSTextFieldDelegate {
    // 用 NoAutofillTextField 替代 NSTextField，关闭系统 AutoFill 建议（详见该文件注释）
    private let textField = NoAutofillTextField()
    private let settings = AppSettings.shared
    private let bg = NSVisualEffectView()
    private var historySection: NSView?

    /// 隐藏后的回调：外部据此释放本面板（连同 NSTextField），回收视图树。
    var onDismiss: (() -> Void)?

    /// 用于取消尚未执行的 onDismiss（例如关闭后立刻又重新打开面板）。
    private var dismissID = 0

    /// 面板显示期间的鼠标监视器：点击面板外即关闭。
    private var mouseMonitors: [Any] = []

    /// 面板顶部（贴近菜单栏）的位置，用于增减高度时保持顶端不动。
    private var anchorTopY: CGFloat = 0

    private static let panelWidth: CGFloat = 260
    private static let fieldHeight: CGFloat = 36
    private static let headerHeight: CGFloat = 18
    private static let rowHeight: CGFloat = 24
    private static let historyLimit = 5
    private static let cornerRadius: CGFloat = 8

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: Self.panelWidth, height: Self.fieldHeight),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered, defer: false)
        isFloatingPanel = true
        level = .popUpMenu
        backgroundColor = .clear
        isOpaque = false
        hasShadow = true
        animationBehavior = .none

        bg.material = .menu
        bg.state = .active
        bg.wantsLayer = true
        bg.layer?.cornerRadius = Self.cornerRadius
        bg.layer?.cornerCurve = .continuous
        bg.layer?.masksToBounds = true          // 裁剪子视图，避免内容从圆角处漏出
        bg.maskImage = Self.roundedMask(radius: Self.cornerRadius)   // 毛玻璃本体也裁成圆角
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

        rebuildHistory()

        // 失焦自动隐藏（不提交）
        NotificationCenter.default.addObserver(
            self, selector: #selector(onResignKey),
            name: NSWindow.didResignKeyNotification, object: self)
    }

    deinit {
        // 面板会被释放（见 StatusBarController.showInputPanel），需移除观察者，
        // 否则通知中心对已释放对象的引用会导致崩溃。
        stopMouseMonitors()
        NotificationCenter.default.removeObserver(self)
    }

    override var canBecomeKey: Bool { true }

    // MARK: - 历史记录区

    /// 按当前历史（排除当前值）重建历史区，并调整面板高度。
    private func rebuildHistory() {
        historySection?.removeFromSuperview()
        historySection = nil

        let items = settings.trackHistory ? Array(settings.displayHistory.prefix(Self.historyLimit)) : []
        guard !items.isEmpty else {
            setPanelHeight(Self.fieldHeight)
            return
        }

        let section = NSView()
        section.translatesAutoresizingMaskIntoConstraints = false
        bg.addSubview(section)

        let separator = NSBox()
        separator.boxType = .separator
        separator.translatesAutoresizingMaskIntoConstraints = false
        section.addSubview(separator)

        let header = NSTextField(labelWithString: settings.strings.historyHeader)
        header.font = .systemFont(ofSize: 11, weight: .semibold)
        header.textColor = .secondaryLabelColor
        header.translatesAutoresizingMaskIntoConstraints = false
        section.addSubview(header)

        let rows = NSStackView()
        rows.orientation = .vertical
        rows.spacing = 0
        rows.alignment = .leading
        rows.translatesAutoresizingMaskIntoConstraints = false
        section.addSubview(rows)

        for item in items {
            let row = HistoryRowView(
                value: item,
                onPick: { [weak self] value in self?.pick(value) },
                onDelete: { [weak self] value in self?.delete(value) })
            row.translatesAutoresizingMaskIntoConstraints = false
            rows.addArrangedSubview(row)
            NSLayoutConstraint.activate([
                row.heightAnchor.constraint(equalToConstant: Self.rowHeight),
                row.widthAnchor.constraint(equalTo: rows.widthAnchor),
            ])
        }

        NSLayoutConstraint.activate([
            section.leadingAnchor.constraint(equalTo: bg.leadingAnchor),
            section.trailingAnchor.constraint(equalTo: bg.trailingAnchor),
            section.topAnchor.constraint(equalTo: bg.topAnchor, constant: Self.fieldHeight),
            section.bottomAnchor.constraint(equalTo: bg.bottomAnchor),

            separator.leadingAnchor.constraint(equalTo: section.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: section.trailingAnchor),
            separator.topAnchor.constraint(equalTo: section.topAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1),

            header.leadingAnchor.constraint(equalTo: section.leadingAnchor, constant: 12),
            header.trailingAnchor.constraint(lessThanOrEqualTo: section.trailingAnchor, constant: -12),
            header.topAnchor.constraint(equalTo: separator.bottomAnchor),
            header.heightAnchor.constraint(equalToConstant: Self.headerHeight),

            rows.leadingAnchor.constraint(equalTo: section.leadingAnchor),
            rows.trailingAnchor.constraint(equalTo: section.trailingAnchor),
            rows.topAnchor.constraint(equalTo: header.bottomAnchor),
            rows.bottomAnchor.constraint(equalTo: section.bottomAnchor),
        ])
        historySection = section

        let historyHeight = 1 + Self.headerHeight + CGFloat(items.count) * Self.rowHeight
        setPanelHeight(Self.fieldHeight + historyHeight)
    }

    private func pick(_ value: String) {
        settings.text = value   // didSet 会把旧的当前值记入历史，并把该值移出历史
        dismiss()
    }

    private func delete(_ value: String) {
        settings.removeHistory(value)
        rebuildHistory()
    }

    /// 改变面板高度，并保持顶端（贴菜单栏那一侧）不动。
    private func setPanelHeight(_ height: CGFloat) {
        var f = frame
        f.size.height = height
        f.origin.y = anchorTopY - height
        setFrame(f, display: true)
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
            var f = frame
            f.origin.x = window.frame.origin.x
            // 收敛到屏幕可视范围内，避免超出左右边缘
            if let screen = window.screen ?? NSScreen.main {
                let visible = screen.visibleFrame
                f.origin.x = min(max(f.origin.x, visible.minX), visible.maxX - f.width)
            }
            anchorTopY = window.frame.minY - 6
            f.origin.y = anchorTopY - f.height
            setFrame(f, display: true)
        } else {
            center()
        }
        NSApp.activate(ignoringOtherApps: true)
        makeKeyAndOrderFront(nil)
        makeFirstResponder(textField)
        textField.selectText(nil)
        startMouseMonitors()
    }

    @objc private func onResignKey() {
        textField.abortEditing()
        dismiss()
    }

    private func commit() {
        let value = textField.stringValue
        if !value.isEmpty, value != settings.text {
            settings.text = value   // didSet 处理历史
        }
        dismiss()
    }

    /// 隐藏输入框，并异步通知外部释放本面板。若在此之前又调用了 `show`，
    /// 回调会被取消（避免释放正在显示的面板）。
    private func dismiss() {
        stopMouseMonitors()
        orderOut(nil)
        dismissID += 1
        let id = dismissID
        DispatchQueue.main.async { [weak self] in
            guard let self, self.dismissID == id else { return }
            self.onDismiss?()
        }
    }

    // MARK: - 面板外点击即关闭

    private func startMouseMonitors() {
        stopMouseMonitors()
        let mask: NSEvent.EventTypeMask = [.leftMouseDown, .rightMouseDown, .otherMouseDown]
        // 本 App 内的点击：落在面板外就关闭
        if let local = NSEvent.addLocalMonitorForEvents(matching: mask, handler: { [weak self] event in
            guard let self else { return event }
            if event.window !== self { self.dismiss() }
            return event
        }) {
            mouseMonitors.append(local)
        }
        // 其他 App / 桌面上的点击：直接关闭
        if let global = NSEvent.addGlobalMonitorForEvents(matching: mask, handler: { [weak self] _ in
            self?.dismiss()
        }) {
            mouseMonitors.append(global)
        }
    }

    private func stopMouseMonitors() {
        for monitor in mouseMonitors { NSEvent.removeMonitor(monitor) }
        mouseMonitors.removeAll()
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

/// 不接收鼠标事件的标签（让整行接收点击）。
private final class PassthroughLabel: NSTextField {
    override func hitTest(_ point: NSPoint) -> NSView? { nil }
}

/// 历史记录中的一行：悬停高亮；点击应用；右侧按钮单独删除。
private final class HistoryRowView: NSView {
    private let value: String
    private let onPick: (String) -> Void
    private let onDelete: (String) -> Void
    private var trackingArea: NSTrackingArea?

    init(value: String, onPick: @escaping (String) -> Void, onDelete: @escaping (String) -> Void) {
        self.value = value
        self.onPick = onPick
        self.onDelete = onDelete
        super.init(frame: .zero)
        wantsLayer = true

        let label = PassthroughLabel(labelWithString: value)
        label.font = .systemFont(ofSize: 13)
        label.textColor = .labelColor
        label.lineBreakMode = .byTruncatingTail
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)

        let symbol = NSImage(systemSymbolName: "xmark", accessibilityDescription: nil)
        let delete = NSButton(image: symbol ?? NSImage(), target: self, action: #selector(deleteTapped))
        delete.isBordered = false
        delete.imagePosition = .imageOnly
        delete.imageScaling = .scaleProportionallyDown
        delete.contentTintColor = .secondaryLabelColor
        delete.refusesFirstResponder = true
        delete.toolTip = AppSettings.shared.strings.deleteHistoryItem
        delete.translatesAutoresizingMaskIntoConstraints = false
        addSubview(delete)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            label.trailingAnchor.constraint(equalTo: delete.leadingAnchor, constant: -8),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),

            delete.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            delete.centerYAnchor.constraint(equalTo: centerYAnchor),
            delete.widthAnchor.constraint(equalToConstant: 16),
            delete.heightAnchor.constraint(equalToConstant: 16),
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) 未实现") }

    @objc private func deleteTapped() {
        onDelete(value)
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
