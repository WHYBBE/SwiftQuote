import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: AppSettings
    @State private var newColor = Color.white

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

                GroupBox("颜色（按字符依次循环，使整个文字每个字可以不同颜色）") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            ColorPicker("添加颜色", selection: $newColor, supportsOpacity: false)
                            Button("添加") {
                                settings.colors.append(NSColor(newColor).hexString)
                            }
                            if settings.colors.count > 1 {
                                Button("移除最后一个") {
                                    settings.colors.removeLast()
                                }
                            }
                        }
                        HStack(spacing: 4) {
                            ForEach(Array(settings.colors.enumerated()), id: \.offset) { idx, hex in
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(nsColor: NSColor(hex: hex) ?? .white))
                                    .frame(width: 22, height: 22)
                                    .overlay(Text("\(idx + 1)").font(.caption2))
                            }
                        }
                        preview
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
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("跟踪历史", isOn: $settings.trackHistory)
                        if !settings.history.isEmpty {
                            Button("清除历史记录") {
                                settings.history = []
                            }
                        }
                    }
                    .padding(8)
                }
            }
            .padding()
        }
        .frame(minWidth: 420, minHeight: 560)
    }

    private func labeledField(_ label: String, text: Binding<String>) -> some View {
        HStack {
            Text(label)
                .frame(width: 60, alignment: .trailing)
            TextField(label, text: text)
                .textFieldStyle(.roundedBorder)
        }
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

#Preview {
    SettingsView().environmentObject(AppSettings.shared)
}
