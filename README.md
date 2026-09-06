# SwiftQuote

[中文](README.zh-CN.md)

A lightweight macOS menu bar app that displays custom text in the menu bar — slogans, reminders, or anything you like.

## Features

- **Custom text in the menu bar** — left-click for the menu, right-click to edit instantly
- **Rich styling** — prefix/suffix, font size, bold, per-character colors (multiple colors cycle through characters), max width limit
- **Color presets** — one-click palettes (Classic, Rainbow, Ocean, Sunset, Forest, Candy)
- **History** — keeps the last 10 entries, quick-apply from the menu or settings
- **Appearance** — System / Light / Dark mode
- **Localization** — System / 中文 / English UI

## Requirements

- macOS 14+
- Swift 5.9+ / Xcode 15+ (for building)

## Build & Run

With SwiftPM:

```sh
swift build
.build/debug/SwiftQuote
```

Or open `SwiftQuote.xcodeproj` in Xcode and run (the project is generated from `project.yml` via [XcodeGen](https://github.com/yonaskolb/XcodeGen): `xcodegen generate`).

## Usage

- **Right-click** the menu bar text to edit it in place (`⏎` to apply, `Esc` to cancel)
- **Left-click** for the menu: edit text, open settings, apply history, or quit
- Settings has four tabs: **General** (theme & language), **Text**, **Colors**, **History**

## License

This project is licensed under the terms of the [MIT License](LICENSE).
