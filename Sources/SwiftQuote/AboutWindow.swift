import AppKit
import SwiftUI

/// 关于窗口（仿系统关于页：图标 / 名称 / 版本 / 简介 / 许可 / 仓库链接）
final class AboutWindowController: NSWindowController, NSWindowDelegate {

    convenience init() {
        let s = AppSettings.shared.strings
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 320),
            styleMask: [.titled, .closable],
            backing: .buffered, defer: false)
        window.title = s.aboutTitle
        window.isReleasedWhenClosed = false
        self.init(window: window)
        window.delegate = self
        window.contentView = NSHostingView(rootView: AboutView())
    }

    func windowWillClose(_ notification: Notification) {
        // 关闭后由 StatusBarController 重新创建
    }
}

struct AboutView: View {
    private let settings = AppSettings.shared

    var body: some View {
        let s = settings.strings
        VStack(spacing: 10) {
            appIcon
                .frame(width: 96, height: 96)
                .padding(.top, 22)

            Text("SwiftQuote")
                .font(.title.bold())

            Text(s.aboutVersion(settings.versionString, settings.buildString))
                .font(.callout)
                .foregroundStyle(.secondary)

            Text(s.aboutDescription)
                .font(.body)
                .multilineTextAlignment(.center)

            Text("MIT License")
                .font(.callout)
                .foregroundStyle(.secondary)

            Link(s.repositoryURL, destination: URL(string: s.repositoryURL)!)
                .font(.callout)

            Spacer(minLength: 0)
        }
        .frame(width: 300, height: 320)
    }

    @ViewBuilder
    private var appIcon: some View {
        // 打包 App：从 asset catalog 读取；SPM 裸跑：用占位图标
        if let icon = NSImage(named: "AppIcon") ?? NSApp.applicationIconImage,
           icon.size.width > 1 {
            Image(nsImage: icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .shadow(radius: 3, y: 2)
        } else {
            Image(systemName: "quote.bubble.fill")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
        }
    }
}
