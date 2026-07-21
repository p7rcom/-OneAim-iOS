import SwiftUI

struct HomeView: View {
    @StateObject private var settings = AppSettings()
    @State private var activeMode: TrainingMode?

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                AppBackground()

                HStack(spacing: 18) {
                    VStack(alignment: .leading, spacing: 12) {
                        brandHeader

                        VStack(spacing: 9) {
                            ForEach(TrainingMode.allCases) { mode in
                                Button {
                                    activeMode = mode
                                } label: {
                                    ModeCard(mode: mode)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        HStack(spacing: 6) {
                            Image(systemName: "lock.shield")
                            Text("تدريب مستقل — لا يقرأ اللعبة ولا يظهر فوقها")
                        }
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.48))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)

                    SettingsPanel(settings: settings)
                        .frame(width: min(350, geometry.size.width * 0.40))
                }
                .padding(.leading, max(58, geometry.safeAreaInsets.leading + 18))
                .padding(.trailing, max(58, geometry.safeAreaInsets.trailing + 18))
                .padding(.vertical, 20)
            }
        }
        .ignoresSafeArea()
        .persistentSystemOverlays(.hidden)
        .fullScreenCover(item: $activeMode) { mode in
            TrainingView(mode: mode, settings: settings.snapshot)
                .interactiveDismissDisabled()
        }
    }

    private var brandHeader: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.cyan.opacity(0.12))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.cyan.opacity(0.35), lineWidth: 1)
                    }
                Image(systemName: "scope")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(Color.cyan)
            }
            .frame(width: 58, height: 58)

            VStack(alignment: .leading, spacing: 2) {
                Text("ONE AIM")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .tracking(2.5)
                Text("مدرّب لمس مخصص للآيفون")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.62))
            }
        }
    }
}

#Preview {
    HomeView()
}
