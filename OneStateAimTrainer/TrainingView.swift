import SwiftUI
import Combine
import UIKit
import Foundation

struct TrainingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var engine: AimTrainerEngine
    @State private var previousDrag: CGSize = .zero

    private let frameTimer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()

    init(mode: TrainingMode, settings: TrainingSettings) {
        _engine = StateObject(wrappedValue: AimTrainerEngine(mode: mode, settings: settings))
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                TrainingBackground()

                ForEach(engine.targets) { target in
                    TargetView(target: target)
                        .position(target.position)
                }

                aimingSurface(in: geometry.size)

                CrosshairView(tint: engine.settings.crosshairTint)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)

                if let feedback = engine.feedback {
                    ShotFeedbackView(feedback: feedback)
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2 - 54)
                        .transition(.scale.combined(with: .opacity))
                }

                HUDView(engine: engine)

                pauseButton
                fireButton(in: geometry.size)

                if engine.phase == .paused {
                    PauseOverlay(
                        onResume: engine.togglePause,
                        onExit: { dismiss() }
                    )
                }

                if engine.phase == .finished, let summary = engine.summary {
                    ResultsOverlay(
                        summary: summary,
                        onReplay: {
                            engine.start(in: geometry.size)
                        },
                        onExit: { dismiss() }
                    )
                }
            }
            .onAppear {
                UIApplication.shared.isIdleTimerDisabled = true
                engine.start(in: geometry.size)
            }
            .onReceive(frameTimer) { date in
                engine.tick(at: date.timeIntervalSinceReferenceDate, in: geometry.size)
            }
            .onChange(of: geometry.size) { _, newSize in
                if engine.phase == .ready {
                    engine.start(in: newSize)
                }
            }
        }
        .ignoresSafeArea()
        .persistentSystemOverlays(.hidden)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase != .active {
                engine.pauseIfNeeded()
            }
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }

    private func aimingSurface(in size: CGSize) -> some View {
        Color.clear
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .local)
                    .onChanged { value in
                        let current = value.translation
                        let delta = CGSize(
                            width: current.width - previousDrag.width,
                            height: current.height - previousDrag.height
                        )
                        previousDrag = current
                        engine.pan(by: delta, in: size)
                    }
                    .onEnded { _ in
                        previousDrag = .zero
                    }
            )
    }

    private var pauseButton: some View {
        VStack {
            HStack {
                Spacer()
                Button(action: engine.togglePause) {
                    Image(systemName: "pause.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(.black.opacity(0.42), in: Circle())
                        .overlay { Circle().stroke(.white.opacity(0.16), lineWidth: 1) }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("إيقاف مؤقت")
            }
            Spacer()
        }
        .padding(.top, 18)
        .padding(.trailing, 58)
    }

    private func fireButton(in size: CGSize) -> some View {
        FireButton { engine.fire(in: size) }
            .position(AimLayout.fireButtonCenter(for: engine.settings.fireButtonSide, in: size))
    }
}
