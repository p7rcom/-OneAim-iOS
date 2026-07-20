import SwiftUI
import Foundation

struct AppBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.025, green: 0.075, blue: 0.105), .black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            RadialGradient(
                colors: [Color.cyan.opacity(0.12), .clear],
                center: .topLeading,
                startRadius: 0,
                endRadius: 480
            )
            DotGrid()
                .opacity(0.12)
        }
    }
}

struct TrainingBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.025, green: 0.07, blue: 0.09), Color(red: 0.015, green: 0.02, blue: 0.025)],
                startPoint: .top,
                endPoint: .bottom
            )
            DotGrid().opacity(0.18)
            LinearGradient(
                colors: [.black.opacity(0.15), .clear, .black.opacity(0.25)],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }
}

private struct DotGrid: View {
    var body: some View {
        Canvas { context, size in
            let spacing: CGFloat = 28
            var x: CGFloat = 0
            while x <= size.width {
                var y: CGFloat = 0
                while y <= size.height {
                    let rect = CGRect(x: x, y: y, width: 1.2, height: 1.2)
                    context.fill(Path(ellipseIn: rect), with: .color(.white))
                    y += spacing
                }
                x += spacing
            }
        }
    }
}

struct ModeCard: View {
    let mode: TrainingMode

    var body: some View {
        HStack(spacing: 13) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(0.055))
                Image(systemName: mode.symbol)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.cyan)
            }
            .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 3) {
                Text(mode.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                Text(mode.subtitle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.52))
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "play.fill")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.black)
                .frame(width: 32, height: 32)
                .background(Color.cyan, in: Circle())
        }
        .padding(.horizontal, 12)
        .frame(height: 64)
        .background(.white.opacity(0.035), in: RoundedRectangle(cornerRadius: 17, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .stroke(.white.opacity(0.09), lineWidth: 1)
        }
        .contentShape(Rectangle())
    }
}

struct SettingsPanel: View {
    @ObservedObject var settings: AppSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "slider.horizontal.3")
                    .foregroundStyle(Color.cyan)
                Text("إعداد التدريب")
                    .font(.system(size: 16, weight: .bold))
                Spacer()
            }

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 11) {
                    SettingSlider(
                        title: "حساسية السحب",
                        valueText: String(format: "%.2f×", settings.sensitivity),
                        value: $settings.sensitivity,
                        range: 0.50...2.00,
                        step: 0.05
                    )

                    SettingSlider(
                        title: "حجم الهدف",
                        valueText: "\(Int(settings.targetDiameter))",
                        value: $settings.targetDiameter,
                        range: 30...72,
                        step: 2
                    )

                    SettingSlider(
                        title: "سرعة الهدف",
                        valueText: "\(Int(settings.targetSpeed))",
                        value: $settings.targetSpeed,
                        range: 70...230,
                        step: 10
                    )

                    CompactChoiceRow(title: "مدة الجولة") {
                        ForEach([30, 60, 90], id: \.self) { seconds in
                            ChoicePill(
                                title: "\(seconds)ث",
                                selected: settings.duration == seconds
                            ) {
                                settings.duration = seconds
                            }
                        }
                    }

                    CompactChoiceRow(title: "زر الإطلاق") {
                        ForEach(FireButtonSide.allCases) { side in
                            ChoicePill(
                                title: side.title,
                                selected: settings.fireButtonSide == side
                            ) {
                                settings.fireButtonSide = side
                            }
                        }
                    }

                    HStack {
                        Text("لون الكروس هير")
                            .font(.system(size: 12, weight: .semibold))
                        Spacer()
                        ForEach(CrosshairTint.allCases) { tint in
                            Button {
                                settings.crosshairTint = tint
                            } label: {
                                Circle()
                                    .fill(tint.color)
                                    .frame(width: 20, height: 20)
                                    .overlay {
                                        if settings.crosshairTint == tint {
                                            Circle().stroke(.white, lineWidth: 2)
                                                .padding(-3)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(tint.title)
                        }
                    }

                    Toggle(isOn: $settings.hapticsEnabled) {
                        Text("اهتزاز عند الإصابة")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .tint(.cyan)
                }
            }
        }
        .padding(15)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(.white.opacity(0.11), lineWidth: 1)
        }
    }
}

private struct SettingSlider: View {
    let title: String
    let valueText: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double

    var body: some View {
        VStack(spacing: 5) {
            HStack {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                Spacer()
                Text(valueText)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.cyan)
            }
            Slider(value: $value, in: range, step: step)
                .tint(.cyan)
        }
    }
}

private struct CompactChoiceRow<Content: View>: View {
    let title: String
    private let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
            Spacer()
            HStack(spacing: 5) { content }
        }
    }
}

private struct ChoicePill: View {
    let title: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(selected ? .black : .white.opacity(0.7))
                .padding(.horizontal, 10)
                .frame(height: 26)
                .background(selected ? Color.cyan : .white.opacity(0.07), in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct TargetView: View {
    let target: AimTarget

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.red.opacity(0.18))
                .frame(width: target.radius * 2.65, height: target.radius * 2.65)
                .blur(radius: 5)
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.white, .red, Color(red: 0.35, green: 0.01, blue: 0.03)],
                        center: .center,
                        startRadius: 0,
                        endRadius: target.radius
                    )
                )
                .overlay { Circle().stroke(.white.opacity(0.72), lineWidth: 1.5) }
                .overlay {
                    Circle()
                        .stroke(.black.opacity(0.32), lineWidth: 1)
                        .padding(target.radius * 0.55)
                }
                .frame(width: target.radius * 2, height: target.radius * 2)
                .shadow(color: .red.opacity(0.42), radius: 10)
        }
        .frame(width: target.radius * 2.8, height: target.radius * 2.8)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

struct CrosshairView: View {
    let tint: CrosshairTint

    var body: some View {
        ZStack {
            line(width: 14, height: 2).offset(x: -13)
            line(width: 14, height: 2).offset(x: 13)
            line(width: 2, height: 14).offset(y: -13)
            line(width: 2, height: 14).offset(y: 13)
            Circle()
                .fill(tint.color)
                .frame(width: 4, height: 4)
                .shadow(color: .black.opacity(0.85), radius: 1)
        }
        .frame(width: 54, height: 54)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func line(width: CGFloat, height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 1)
            .fill(tint.color)
            .frame(width: width, height: height)
            .overlay { RoundedRectangle(cornerRadius: 1).stroke(.black.opacity(0.75), lineWidth: 0.7) }
    }
}

extension CrosshairTint {
    var color: Color {
        switch self {
        case .cyan: return .cyan
        case .green: return Color(red: 0.35, green: 1, blue: 0.28)
        case .red: return Color(red: 1, green: 0.18, blue: 0.16)
        case .white: return .white
        }
    }
}

struct HUDView: View {
    @ObservedObject var engine: AimTrainerEngine

    var body: some View {
        VStack {
            HStack(spacing: 8) {
                HUDChip(label: "النقاط", value: "\(engine.score)", icon: "bolt.fill")
                HUDChip(label: "الدقة", value: String(format: "%.0f%%", AimMath.accuracy(hits: engine.hits, shots: engine.shots)), icon: "scope")
                HUDChip(label: "السلسلة", value: "×\(engine.streak)", icon: "flame.fill")
                HUDChip(label: "الوقت", value: "\(Int(ceil(engine.timeRemaining)))", icon: "timer")
            }
            Spacer()
        }
        .padding(.top, 17)
        .allowsHitTesting(false)
    }
}

private struct HUDChip: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color.cyan)
            VStack(alignment: .leading, spacing: 0) {
                Text(label)
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.45))
                Text(value)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
            }
        }
        .frame(minWidth: 70)
        .padding(.horizontal, 10)
        .frame(height: 39)
        .background(.black.opacity(0.40), in: Capsule())
        .overlay { Capsule().stroke(.white.opacity(0.10), lineWidth: 1) }
    }
}

struct FireButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.16))
                Circle()
                    .stroke(Color.red.opacity(0.55), lineWidth: 2)
                    .padding(5)
                Image(systemName: "scope")
                    .font(.system(size: 27, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(width: 76, height: 76)
            .background(.black.opacity(0.28), in: Circle())
        }
        .buttonStyle(PressScaleButtonStyle())
        .accessibilityLabel("إطلاق")
    }
}

private struct PressScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.88 : 1)
            .opacity(configuration.isPressed ? 0.82 : 1)
            .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
    }
}

struct ShotFeedbackView: View {
    let feedback: ShotFeedback

    var body: some View {
        Text(feedback.isHit ? "+\(feedback.points)" : "خطأ")
            .font(.system(size: 15, weight: .black, design: .rounded))
            .foregroundStyle(feedback.isHit ? Color.green : Color.red)
            .shadow(color: .black, radius: 2)
            .id(feedback.id)
            .allowsHitTesting(false)
    }
}

struct PauseOverlay: View {
    let onResume: () -> Void
    let onExit: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.70)
                .ignoresSafeArea()
            VStack(spacing: 14) {
                Image(systemName: "pause.circle.fill")
                    .font(.system(size: 46))
                    .foregroundStyle(Color.cyan)
                Text("متوقف مؤقتًا")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                HStack(spacing: 10) {
                    OverlayButton(title: "إنهاء", icon: "xmark", prominent: false, action: onExit)
                    OverlayButton(title: "متابعة", icon: "play.fill", prominent: true, action: onResume)
                }
            }
        }
    }
}

struct ResultsOverlay: View {
    let summary: SessionSummary
    let onReplay: () -> Void
    let onExit: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.78)
                .ignoresSafeArea()

            VStack(spacing: 13) {
                Text("انتهت الجولة")
                    .font(.system(size: 25, weight: .black, design: .rounded))
                Text(summary.mode.title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.cyan)

                HStack(spacing: 9) {
                    ResultStat(title: "النقاط", value: "\(summary.score)")
                    ResultStat(title: "الدقة", value: String(format: "%.1f%%", summary.accuracy))
                    ResultStat(title: "الإصابات", value: "\(summary.hits)/\(summary.shots)")
                    ResultStat(title: "أفضل سلسلة", value: "×\(summary.bestStreak)")
                }

                HStack(spacing: 10) {
                    OverlayButton(title: "الرئيسية", icon: "house.fill", prominent: false, action: onExit)
                    OverlayButton(title: "إعادة", icon: "arrow.clockwise", prominent: true, action: onReplay)
                }
            }
            .padding(22)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(.white.opacity(0.12), lineWidth: 1)
            }
        }
    }
}

private struct ResultStat: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 18, weight: .black, design: .rounded))
            Text(title)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.white.opacity(0.48))
        }
        .frame(width: 92, height: 58)
        .background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
    }
}

private struct OverlayButton: View {
    let title: String
    let icon: String
    let prominent: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(prominent ? .black : .white)
                .frame(width: 120, height: 40)
                .background(prominent ? Color.cyan : .white.opacity(0.08), in: Capsule())
                .overlay {
                    if !prominent {
                        Capsule().stroke(.white.opacity(0.12), lineWidth: 1)
                    }
                }
        }
        .buttonStyle(.plain)
    }
}
