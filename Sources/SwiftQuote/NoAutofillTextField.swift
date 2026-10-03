import AppKit

/// 不触发系统「AutoFill」的文本输入框。
///
/// ## 背景
/// macOS（Sequoia/Tahoe 之后更明显）会对聚焦的文本框自动挂上
/// Apple 密码 / iCloud 钥匙串的「AutoFill（应用名）」建议（钥匙图标）。
/// 这属于系统级行为，App 侧并没有开启它，也没有公开的关闭开关：
/// `NSTextContentType` 里根本不存在 `.none` 之类的「关闭」取值。
///
/// ## 原理
/// AppKit 内部用 Objective-C 消息 `-_isPasswordAutofillEnabled` 询问一个
/// 文本框「是否允许密码自动填充」。这是**未公开的私有方法**，头文件里没有声明，
/// 所以 Swift 无法用 `override`，只能由子类提供一个同名的 `@objc` 方法。
/// 运行时是动态派发（`objc_msgSend`）：系统在自己的类上找不到实现时，
/// 会命中的我们这个子类实现，从而返回 `false`、不再弹出 AutoFill。
///
/// ## 适用范围（重要，别误解）
/// 本类只负责**去掉输入框上方那个 AutoFill 提示 UI**（钥匙图标 / 建议列表）。
/// 它 **不能阻止** 活动监视器里的独立进程 `AutoFill (应用名)`：那个进程是系统
/// launchd 按需拉起的 `AutoFillPanelService` / `SafariPlatformSupport.Helper`，
/// 父进程是 launchd 而非本 App，字段级开关管不到它。要让它不再出现，只能在
/// 系统设置 → 通用 → 自动填充与密码 里关闭「自动填充密码和通行密钥」
/// （参见 kitty #9299：`NSAutoFillHeuristicControllerEnabled=NO` 也挡不住该进程）。
/// 进程内的启发式控制器则由 `main.swift` 里的 `NSAutoFillHeuristicControllerEnabled` 处理。
///
/// ## 代价 / 注意
/// - 使用私有 API，**无法上架 Mac App Store**；本仓库为 MIT + GitHub 分发，可以接受。
/// - 该做法在社区里是针对 `NSSecureTextField` 验证的；这里是普通的 `NSTextField`，
///   若在个别系统版本上仍失效，可回退为 `textField.contentType = .oneTimeCode`
///   （声明成验证码字段，密码管理器通常会跳过），或参考 StackOverflow 65907104
///   里的「隐藏假 NSSecureTextField」方案。
/// - Apple 未保证该 selector 永远存在；若未来系统改名，此方法会静默失效（不会崩溃）。
@MainActor
final class NoAutofillTextField: NSTextField {

    /// 私有 selector：AppKit 用它决定是否为该字段提供密码 AutoFill 建议。
    /// 覆写为 `false` 即关闭**本字段**的自动填充提示 UI（不涉及 launchd 的 helper 进程）。
    @objc func _isPasswordAutofillEnabled() -> Bool { false }
}
