import SwiftUI

struct GeneralSettingsView: View {
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                GroupBox("文字") {
                    VStack(alignment: .leading, spacing: 8) {
                        labeledField("前缀", text: $settings.prefix)
                        labeledField("后缀", text: $settings.suffix)
                        Toggle("加粗", isOn: $settings.bold)
                        HStack {
                            Text("文字大小")
                            Slider(value: $settings.fontSize, in: 9...24, step: 0.5)
                            Text("\(settings.fontSize, specifier: "%.1f")")
                                .monospacedDigit()
                                .frame(width: 34, alignment: .trailing)
                        }
                        HStack {
                            Text("最大宽度")
                            Slider(value: $settings.maxWidth, in: 40...400, step: 5)
                            Text("\(Int(settings.maxWidth))")
                                .monospacedDigit()
                                .frame(width: 34, alignment: .trailing)
                        }
                    }
                    .padding(8)
                }

                GroupBox("预设") {
                    VStack(spacing: 4) {
                        ForEach(Preset.all) { preset in
                            HStack {
                                Text(preset.name)
                                Spacer()
                                Text(preset.prefix + preset.text + preset.suffix)
                                    .foregroundStyle(.secondary)
                                Button("应用") {
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

                GroupBox("历史") {
                    HStack {
                        Toggle("跟踪历史", isOn: $settings.trackHistory)
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
struct ColorsSettingsView: View {
    @EnvironmentObject var settings: AppSettings
    @State private var newColor = Color.white

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ColorPicker("添加颜色", selection: $newColor, supportsOpacity: false)
                Button("添加") {
                    settings.colorEntries.append(ColorEntry(hex: NSColor(newColor).hexString))
                }
                Spacer()
            }

            List {
                ForEach(settings.colorEntries) { entry in
                    HStack {
                        ColorPicker("", selection: colorBinding(entry.id), supportsOpacity: false)
                            .labelsHidden()
                        Spacer()
                        Button {
                            settings.colorEntries.removeAll { $0.id == entry.id }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.plain)
                        .disabled(settings.colorEntries.count <= 1)
                    }
                }
                .onMove { offsets, destination in
                    settings.colorEntries.move(fromOffsets: offsets, toOffset: destination)
                }
            }

            Text("颜色依次循环应用到每个字符；拖动可排序")
                .font(.caption)
                .foregroundStyle(.secondary)

            preview
        }
        .padding()
    }

    private func colorBinding(_ id: UUID) -> Binding<Color> {
        Binding(
            get: {
                guard let i = settings.colorEntries.firstIndex(where: { $0.id == id }) else {
                    return .white
                }
                return Color(nsColor: NSColor(hex: settings.colorEntries[i].hex) ?? .white)
            },
            set: { newValue in
                guard let i = settings.colorEntries.firstIndex(where: { $0.id == id }) else { return }
                settings.colorEntries[i].hex = NSColor(newValue).hexString
            }
        )
    }

    private var preview: some View {
        HStack(spacing: 0) {
            let colors = settings.nsColors
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

/// 历史记录页：查看、应用、删除单条、清空
struct HistorySettingsView: View {
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Toggle("跟踪历史", isOn: $settings.trackHistory)
                Spacer()
                if !settings.history.isEmpty {
                    Button(role: .destructive) {
                        settings.history = []
                    } label: {
                        Label("清空全部", systemImage: "trash")
                    }
                }
            }

            if settings.history.isEmpty {
                Spacer()
                HStack {
                    Spacer()
                    Text("暂无历史记录")
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
                                Text("当前")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Button("应用") {
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
