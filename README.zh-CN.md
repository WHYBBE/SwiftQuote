<p align="center">
  <img src="docs/logo.png" width="112" alt="SwiftQuote logo">
</p>

<h1 align="center">SwiftQuote</h1>

<p align="center">
  <img src="https://img.shields.io/badge/macOS-15%2B-blue" alt="macOS 15+">
  <img src="https://img.shields.io/badge/Swift-6.0%2B-orange" alt="Swift 6.0+">
  <img src="https://img.shields.io/badge/UI-AppKit-8A2BE2" alt="AppKit">
  <img src="https://img.shields.io/badge/License-MIT-green" alt="MIT License">
</p>

<p align="center"><a href="README.md">English</a></p>

<p align="center">一款轻量 macOS 菜单栏应用，在菜单栏显示自定义文字——格言、提醒、或任何你想展示的内容。</p>

## 截图

<p align="center">
  <img src="docs/preview-main.png" width="220" alt="菜单栏自定义文字">
</p>

<p align="center">
  <img src="docs/preview-left.png" width="210" alt="左键菜单">
  &nbsp;&nbsp;
  <img src="docs/preview-right.png" width="400" alt="右键编辑面板">
</p>

<p align="center">
  <img src="docs/preview-setting.png" width="420" alt="设置窗口">
</p>

## 功能

- **菜单栏自定义文字** — 左键打开菜单，右键即刻编辑
- **丰富样式** — 前后缀、字号、加粗、逐字符颜色（多颜色循环）、最大宽度限制
- **自适应颜色** — 浅色/深色菜单栏各一套配色，随菜单栏外观变化自动切换（附恢复默认按钮）
- **文字预设** — 一键套用模板（Aloha!、请勿打扰、Coffee 等）
- **历史记录** — 保留最近 10 条，可从菜单或设置中快速套用；当前文字不混在列表里，每条均可单独删除
- **外观** — 跟随系统 / 浅色 / 深色
- **多语言** — 跟随系统 / 中文 / English 界面
- **开机自启** — 基于 SMAppService（需以打包 App 形式运行）
- **轻量** — 常驻内存约 13 MB；窗口关闭即释放视图树，内置「重启」菜单项可回收长期运行残留内存

## 环境要求

- macOS 15+
- Swift 6.0+ / Xcode 16+（自行构建时）

## 构建与运行

使用 SwiftPM：

```sh
swift build
.build/debug/SwiftQuote
```

或在 Xcode 中打开 `SwiftQuote.xcodeproj` 运行（工程由 `project.yml` 通过 [XcodeGen](https://github.com/yonaskolb/XcodeGen) 生成：`xcodegen generate`）。

## 使用说明

- **右键** 点击菜单栏文字即可原地编辑（`⏎` 确认，`Esc` 取消）；输入框下方显示最近历史，点击某条即可应用，点 × 可单独删除
- **左键** 打开菜单：输入…、设置…、跟踪历史开关、开机自启开关、最近历史（最多 5 条）、关于（含版本号）、重启、退出
- 设置分为四个标签页：**通用**（主题、语言与启动）、**文字**（内容、前后缀、字体、预设）、**颜色**（逐字符颜色、自适应菜单栏配色）、**历史**（当前文字单独展示，可逐条删除）

## 开源许可

本项目基于 [MIT 许可证](LICENSE) 开源。
