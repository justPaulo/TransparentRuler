import SwiftUI
import AppKit

enum UnitSystem: String, CaseIterable {
    case pt = "pt"
    case mm = "mm"
    case cm = "cm"
    case inches = "in"

    // Number of screen points for one logical unit in this system
    func pointsPerUnit() -> CGFloat {
        switch self {
        case .pt:
            return 1.0
        case .mm:
            return 72.0 / 25.4
        case .cm:
            return 72.0 / 2.54
        case .inches:
            return 72.0
        }
    }

    func majorUnitStep() -> CGFloat {
        switch self {
        case .pt:
            return 100
        case .mm:
            return 10
        case .cm:
            return 1
        case .inches:
            return 1
        }
    }

    func pointsPerMajorTick() -> CGFloat {
        pointsPerUnit() * majorUnitStep()
    }
}

private class DraggableNSView: NSView {
    init() {
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var mouseDownCanMoveWindow: Bool { true }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()

        guard let window = window else {
            return
        }

        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .floating
        window.styleMask = [.titled, .resizable, .closable, .fullSizeContentView]
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
    }
}

struct DraggableWindowView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = DraggableNSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.clear.cgColor
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

struct TransparencyPanelView: View {
    @ObservedObject var state: AppState
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Text("Transparency")
                .font(.headline)

            Slider(value: $state.transparency, in: 0...1)
                .padding(.horizontal)

            Text("\(Int(state.transparency * 100))%")
                .font(.subheadline)

            Button("Done") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 10)
        }
        .padding()
        .frame(width: 320, height: 140)
    }
}

struct AboutView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Text("Transparent Ruler")
                .font(.title)
                .fontWeight(.bold)
            Text("Version 1.0")
                .font(.subheadline)
            Text("© 2026 Paulo Morais Nascimento")
                .font(.subheadline)
            Text("A transparent, always-on-top ruler for precise measurements on screen.")
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button("OK") {
                dismiss()
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .frame(width: 350, height: 230)
    }
}

class AppState: ObservableObject {
    @Published var transparency: Double = 0.5
    @Published var nsColor: NSColor = .blue
    @Published var unit: UnitSystem = .pt

    var color: Color {
        Color(nsColor)
    }
}

private struct ColorPreset: Identifiable, Hashable {
    let id: String
    let color: Color
    let nsColor: NSColor
}

struct CompactColorPickerView: View {
    @ObservedObject var state: AppState
    @Binding var isPresented: Bool
    @State private var hue: Double
    @State private var saturation: Double
    @State private var brightness: Double
    @State private var selectedPresetID: String?

    init(state: AppState, isPresented: Binding<Bool>) {
        self.state = state
        self._isPresented = isPresented
        let color = state.nsColor.usingColorSpace(.deviceRGB) ?? state.nsColor
        var hueValue: CGFloat = 0
        var saturationValue: CGFloat = 0
        var brightnessValue: CGFloat = 0
        var alphaValue: CGFloat = 0
        color.getHue(&hueValue, saturation: &saturationValue, brightness: &brightnessValue, alpha: &alphaValue)
        self._hue = State(initialValue: Double(hueValue))
        self._saturation = State(initialValue: Double(saturationValue))
        self._brightness = State(initialValue: Double(brightnessValue))
        self._selectedPresetID = State(initialValue: Self.presetID(for: state.nsColor))
    }

    var currentColor: Color {
        Color(NSColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 1))
    }

    private static let presets: [ColorPreset] = [
        ColorPreset(id: "red", color: .red, nsColor: .red),
        ColorPreset(id: "green", color: .green, nsColor: .green),
        ColorPreset(id: "blue", color: .blue, nsColor: .blue),
        ColorPreset(id: "yellow", color: .yellow, nsColor: .yellow),
        ColorPreset(id: "black", color: .black, nsColor: .black)
    ]

    var body: some View {
        VStack(spacing: 12) {
            Text("Choose Color")
                .font(.headline)

            HStack(spacing: 8) {
                ForEach(Self.presets) { preset in
                    Button(action: {
                        state.nsColor = preset.nsColor
                        updatePickerValues(from: state.nsColor)
                        selectedPresetID = preset.id
                    }) {
                        ZStack {
                            Circle()
                                .fill(preset.color)
                                .frame(width: 30, height: 30)
                            if selectedPresetID == preset.id {
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                                    .frame(width: 34, height: 34)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            if selectedPresetID == nil {
                HStack(spacing: 6) {
                    Circle()
                        .stroke(Color.primary, lineWidth: 1)
                        .frame(width: 10, height: 10)
                    Text("Custom color selected")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 4)
            }

            VStack(alignment: .leading, spacing: 8) {
                ColorPreview(color: currentColor)
                    .frame(height: 36)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.5), lineWidth: 1))

                Slider(value: $hue, in: 0...1) {
                    Text("Hue")
                }
                .onChange(of: hue) { updateStateColor() }

                Slider(value: $saturation, in: 0...1) {
                    Text("Saturation")
                }
                .onChange(of: saturation) { updateStateColor() }

                Slider(value: $brightness, in: 0...1) {
                    Text("Brightness")
                }
                .onChange(of: brightness) { updateStateColor() }
            }

            Button("Done") {
                isPresented = false
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
        }
        .padding()
        .frame(width: 320)
    }

    private func updateStateColor() {
        let newColor = NSColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 1)
        state.nsColor = newColor
        selectedPresetID = Self.presetID(for: newColor)
    }

    private func updatePickerValues(from color: NSColor) {
        let normalized = color.usingColorSpace(.deviceRGB) ?? color
        var hueValue: CGFloat = 0
        var saturationValue: CGFloat = 0
        var brightnessValue: CGFloat = 0
        var alphaValue: CGFloat = 0
        normalized.getHue(&hueValue, saturation: &saturationValue, brightness: &brightnessValue, alpha: &alphaValue)
        hue = Double(hueValue)
        saturation = Double(saturationValue)
        brightness = Double(brightnessValue)
        selectedPresetID = Self.presetID(for: color)
    }

    private static func presetID(for color: NSColor) -> String? {
        let selected = (color.usingColorSpace(.deviceRGB) ?? color)
        let tolerance: CGFloat = 0.01
        return presets.first { preset in
            let presetColor = (preset.nsColor.usingColorSpace(.deviceRGB) ?? preset.nsColor)
            return abs(selected.redComponent - presetColor.redComponent) < tolerance
                && abs(selected.greenComponent - presetColor.greenComponent) < tolerance
                && abs(selected.blueComponent - presetColor.blueComponent) < tolerance
        }?.id
    }
}

private struct ColorPreview: View {
    let color: Color

    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(color)
    }
}

struct RulerView: View {
    @ObservedObject var state: AppState
    @Binding var showAbout: Bool
    @State private var showColorPopover = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openWindow) private var openWindow

    private let majorTickHeight: CGFloat = 30
    private let halfTickHeight: CGFloat = 20
    private let smallTickHeight: CGFloat = 15
    private let epsilon: CGFloat = 0.5
    private let unitTextOffset = CGPoint(x: 18, y: 30)
    private let brandTextOffset = CGPoint(x: 40, y: 30)
    private let labelOffsetY: CGFloat = 35
    private let labelOffsetX: CGFloat = 8

    private func drawTicks(in context: GraphicsContext, width: CGFloat, majorSpacing: CGFloat, halfSpacing: CGFloat, smallSpacing: CGFloat) {
        let tickCount = Int(width / smallSpacing) + 2
        for i in 0..<tickCount {
            let x = CGFloat(i) * smallSpacing
            if x > width { break }

            let height: CGFloat
            let opacity: Double
            if abs(x.truncatingRemainder(dividingBy: majorSpacing)) < epsilon {
                height = majorTickHeight
                opacity = 1.0
            } else if abs(x.truncatingRemainder(dividingBy: halfSpacing)) < epsilon {
                height = halfTickHeight
                opacity = 0.8
            } else {
                height = smallTickHeight
                opacity = 0.6
            }
            let path = Path(CGRect(x: x, y: 0, width: 1, height: height))
            context.fill(path, with: .color(state.color.opacity(state.transparency * opacity)))
        }
    }

    private func drawLabels(in context: GraphicsContext, width: CGFloat, majorSpacing: CGFloat, majorUnitStep: CGFloat) {
        let labelCount = Int(width / majorSpacing) + 2
        for i in 0..<labelCount {
            let x = CGFloat(i) * majorSpacing
            if x > width { break }
            let value = Int(round(CGFloat(i) * majorUnitStep))
            let text = Text("\(value)")
                .font(.system(size: 10))
                .foregroundColor(state.color.opacity(state.transparency))
            context.draw(text, at: CGPoint(x: x + labelOffsetX, y: labelOffsetY))
        }
    }

    var body: some View {
        Canvas { context, size in
            let width = size.width
            let majorUnitStep = state.unit.majorUnitStep()
            let majorSpacing = state.unit.pointsPerMajorTick()
            let halfSpacing = majorSpacing / 2.0
            let smallSpacing = max(1.0, majorSpacing / 10.0)

            let unitText = Text(state.unit.rawValue)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(state.color.opacity(state.transparency))
            context.draw(unitText, at: unitTextOffset, anchor: .leading)

            let brandText = Text("noOrg")
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(state.color.opacity(state.transparency))
            context.draw(brandText, at: brandTextOffset, anchor: .leading)

            drawTicks(in: context, width: width, majorSpacing: majorSpacing, halfSpacing: halfSpacing, smallSpacing: smallSpacing)
            drawLabels(in: context, width: width, majorSpacing: majorSpacing, majorUnitStep: majorUnitStep)
        }
        .frame(height: 50)
        .background(Color.clear)
        .overlay(DraggableWindowView())
        .contentShape(Rectangle())
        .border(state.color.opacity(state.transparency * 0.3), width: 1)
        .popover(isPresented: $showColorPopover) {
            CompactColorPickerView(state: state, isPresented: $showColorPopover)
        }
        .contextMenu {
            Button("New Ruler") {
                openWindow(id: "main")
            }
            Button("Close Ruler") {
                dismiss()
            }
            Divider()
            Button("Change Color...") {
                showColorPopover = true
            }
        }
        .sheet(isPresented: $showAbout) {
            AboutView()
        }
    }
}

@main
struct TransparentRulerApp: App {
    @StateObject var state = AppState()
    @State private var showAbout = false
    @State private var showTransparencyPanel = false
    @Environment(\.openWindow) private var openWindow

    var body: some Scene {
        WindowGroup(id: "main") {
            RulerView(state: state, showAbout: $showAbout)
                .sheet(isPresented: $showTransparencyPanel) {
                    TransparencyPanelView(state: state)
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 400, height: 50)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Ruler") {
                    openWindow(id: "main")
                }
                .keyboardShortcut("n", modifiers: .command)
            }
/*             CommandGroup(after: .newItem) {
                Button("Close Ruler") {
                    if let keyWindow = NSApp.keyWindow {
                        keyWindow.close()
                    } else if let window = NSApp.windows.first(where: { $0.isVisible && $0.level == .floating }) {
                        window.close()
                    }
                }
                .keyboardShortcut("w", modifiers: .command)
            } */
        }

        MenuBarExtra("Ruler", systemImage: "ruler") {
            Button("New Ruler") {
                openWindow(id: "main")
            }
            Button("Close Ruler") {
                if let keyWindow = NSApp.keyWindow {
                    keyWindow.close()
                } else if let window = NSApp.windows.first(where: { $0.isVisible && $0.className.contains("Window") }) {
                    window.close()
                }
            }
            Divider()
            Button("About Transparent Ruler") {
                NSApp.activate(ignoringOtherApps: true)
                showAbout = true
            }
            Divider()
            Menu("Units") {
                ForEach(UnitSystem.allCases, id: \.self) { unit in
                    Button {
                        state.unit = unit
                    } label: {
                        HStack {
                            Text(unit.rawValue)
                            Spacer()
                            if state.unit == unit {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }
            Divider()
            Button("Transparency…") {
                NSApp.activate(ignoringOtherApps: true)
                showTransparencyPanel = true
            }
            Divider()
            Button("Quit") {
                NSApp.terminate(nil)
            }
        }
    }
}