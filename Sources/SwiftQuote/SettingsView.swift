import SwiftUI

/// 通用页：主题 / 语言 / 开机自启（默认 Tab）
struct GeneralSettingsView: View {
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        let s = settings.strings
        Form {
            Section(s.groupAppearance) {
                Picker("", selection: $settings.appearance) {
                    Text(s.appearanceSystem).tag(AppAppearance.system)
                    Text(s.appearanceLight).tag(AppAppearance.light)
                    Text(s.appearanceDark).tag(AppAppearance.dark)
                }
                .labelsHidden()
                .pickerStyle(.segmented)
            }
            Section(s.groupLanguage) {
                Picker("", selection: $settings.language) {
                    Text(s.languageSystem).tag(AppLanguage.system)
                    Text("中文").tag(AppLanguage.chinese)
                    Text("English").tag(AppLanguage.english)
                }
                .labelsHidden()
                .pickerStyle(.segmented)
            }
            Section(s.groupStartup) {
                Toggle(s.launchAtLogin, isOn: Binding(
                    get: { settings.launchAtLogin },
                    set: { settings.launchAtLogin = $0 }))
                    .disabled(!settings.loginItemAvailable)
                if !settings.loginItemAvailable {
                    Text(s.launchAtLoginUnavailable)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .padding(.top, 12)
    }
}

/// 文字页：前缀/后缀/样式/预设/历史开关
struct TextSettingsView: View {
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        let s = settings.strings
        return ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                GroupBox(s.groupText) {
                    VStack(alignment: .leading, spacing: 8) {
                        labeledField(s.prefix, text: $settings.prefix)
                        labeledField(s.suffix, text: $settings.suffix)
                        Toggle(s.bold, isOn: $settings.bold)
                        HStack {
                            Text(s.fontSize)
                            Slider(value: $settings.fontSize, in: 9...24, step: 0.5)
                            Text("\(settings.fontSize, specifier: "%.1f")")
                                .monospacedDigit()
                                .frame(width: 34, alignment: .trailing)
                        }
                        HStack {
                            Text(s.maxWidth)
                            Slider(value: $settings.maxWidth, in: 40...400, step: 5)
                            Text("\(Int(settings.maxWidth))")
                                .monospacedDigit()
                                .frame(width: 34, alignment: .trailing)
                        }
                    }
                    .padding(8)
                }

                GroupBox(s.groupPresets) {
                    VStack(spacing: 4) {
                        ForEach(Preset.all) { preset in
                            HStack {
                                Text(preset.name)
                                Spacer()
                                Text(preset.prefix + preset.text + preset.suffix)
                                    .foregroundStyle(.secondary)
                                Button(s.apply) {
                                    settings.prefix = preset.prefix
                                    settings.suffix = preset.suffix
                                    if !preset.text.isEmpty {
                                        settings.text = preset.text
                                        settings.pushHistory(preset.text)
                                    }
                                }
                                .controlSize(.small)
                            }
                        }
                    }
                    .padding(8)
                }

                GroupBox(s.tabHistory) {
                    HStack {
                        Toggle(s.trackHistory, isOn: $settings.trackHistory)
                    }
                    .padding(8)
                }
            }
            .padding()
        }
    }

    private func labeledField(_ label: String, text: Binding<String>) -> some View {
        HStack {
            Text(label)
                .frame(width: 60, alignment: .trailing)
            TextField(label, text: text)
                .textFieldStyle(.roundedBorder)
        }
    }
}

/// 颜色页：依次循环应用到每个字符，可单独修改、拖动排序、删除
/// 开启「自适应菜单栏」后维护两套颜色，随菜单栏深浅自动切换
struct ColorsSettingsView: View {
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        let s = settings.strings
        VStack(alignment: .leading, spacing: 12) {
            Toggle(s.adaptiveColors, isOn: $settings.adaptiveColors)

            if settings.adaptiveColors {
                colorList(title: s.lightBarColors,
                          entries: $settings.lightBarColorEntries)
                colorList(title: s.darkBarColors,
                          entries: $settings.darkBarColorEntries)
            } else {
                colorList(title: nil, entries: $settings.colorEntries)
            }

            Text(s.colorsHint)
                .font(.caption)
                .foregroundStyle(.secondary)

            preview
        }
        .padding()
    }

    /// 一组颜色的编辑列表（添加 / 修改 / 排序 / 删除）
    private func colorList(title: String?, entries: Binding<[ColorEntry]>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if let title {
                Text(title)
                    .font(.headline)
            }
            ColorListEditor(entries: entries)
        }
    }

    private var preview: some View {
        HStack(spacing: 0) {
            let colors = settings.effectiveNSColors
            let full = settings.displayText
            ForEach(Array(full.enumerated()), id: \.offset) { i, ch in
                Text(String(ch))
                    .font(.system(size: settings.fontSize, weight: settings.bold ? .bold : .regular))
                    .foregroundStyle(colors.isEmpty ? Color.white : Color(nsColor: colors[i % colors.count]))
            }
        }
        .padding(.horizontal, 8)
        .frame(height: 28)
        .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 5))
    }
}

/// 可复用的颜色列表编辑器：添加 / 修改 / 拖动排序 / 删除
private struct ColorListEditor: View {
    @Binding var entries: [ColorEntry]
    @State private var newColor = Color.white

    var body: some View {
        HStack {
            ColorPicker("", selection: $newColor, supportsOpacity: false)
                .labelsHidden()
            Button(AppSettings.shared.strings.add) {
                entries.append(ColorEntry(hex: NSColor(newColor).hexString))
            }
            Spacer()
        }

        List {
            ForEach(entries) { entry in
                HStack {
                    ColorPicker("", selection: colorBinding(entry.id), supportsOpacity: false)
                        .labelsHidden()
                    Spacer()
                    Button {
                        entries.removeAll { $0.id == entry.id }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                    .disabled(entries.count <= 1)
                }
            }
            .onMove { offsets, destination in
                entries.move(fromOffsets: offsets, toOffset: destination)
            }
        }
        .frame(minHeight: 120)
    }

    private func colorBinding(_ id: UUID) -> Binding<Color> {
        Binding(
            get: {
                guard let i = entries.firstIndex(where: { $0.id == id }) else { return .white }
                return Color(nsColor: NSColor(hex: entries[i].hex) ?? .white)
            },
            set: { newValue in
                guard let i = entries.firstIndex(where: { $0.id == id }) else { return }
                entries[i].hex = NSColor(newValue).hexString
            }
        )
    }
}

/// 历史记录页：查看、应用、删除单条、清空
struct HistorySettingsView: View {
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        let s = settings.strings
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Toggle(s.trackHistory, isOn: $settings.trackHistory)
                Spacer()
                if !settings.history.isEmpty {
                    Button(role: .destructive) {
                        settings.history = []
                    } label: {
                        Label(s.clearAll, systemImage: "trash")
                    }
                }
            }

            if settings.history.isEmpty {
                Spacer()
                HStack {
                    Spacer()
                    Text(s.noHistory)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                Spacer()
            } else {
                List {
                    ForEach(settings.history, id: \.self) { item in
                        HStack {
                            Text(item)
                                .lineLimit(1)
                            Spacer()
                            if item == settings.text {
                                Text(s.current)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Button(s.apply) {
                                settings.text = item
                            }
                            .controlSize(.small)
                        }
                    }
                    .onDelete { offsets in
                        settings.history.remove(atOffsets: offsets)
                    }
                }
                .listStyle(.inset)
            }
        }
        .padding()
    }
}
