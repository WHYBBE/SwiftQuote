# SwiftQuote

[English](README.md)

一款轻量 macOS 菜单栏应用，在菜单栏显示自定义文字——格言、提醒、或任何你想展示的内容。

## 功能

- **菜单栏自定义文字** — 左键打开菜单，右键即刻编辑
- **丰富样式** — 前后缀、字号、加粗、逐字符颜色（多颜色循环）、最大宽度限制
- **颜色预设** — 一键套用配色（经典、彩虹、海洋、日落、森林、糖果）
- **历史记录** — 保留最近 10 条，可从菜单或设置中快速套用
- **外观** — 跟随系统 / 浅色 / 深色
- **多语言** — 跟随系统 / 中文 / English 界面

## 环境要求

- macOS 14+
- Swift 5.9+ / Xcode 15+（自行构建时）

## 构建与运行

使用 SwiftPM：

```sh
swift build
.build/debug/SwiftQuote
```

或在 Xcode 中打开 `SwiftQuote.xcodeproj` 运行（工程由 `project.yml` 通过 [XcodeGen](https://github.com/yonaskolb/XcodeGen) 生成：`xcodegen generate`）。

## 使用说明

- **右键** 点击菜单栏文字即可原地编辑（`⏎` 确认，`Esc` 取消）
- **左键** 打开菜单：编辑文字、打开设置、套用历史、退出
- 设置分为四个标签页：**通用**（主题与语言）、**文字**、**颜色**、**历史**

## 开源许可

本项目基于 [MIT 许可证](LICENSE) 开源。
