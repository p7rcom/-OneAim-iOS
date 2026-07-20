import SwiftUI
import UIKit
import Foundation

@MainActor
final class AimTrainerEngine: ObservableObject {
    @Published private(set) var targets: [AimTarget] = []
    @Published private(set) var phase: SessionPhase = .ready
    @Published private(set) var timeRemaining: TimeInterval
    @Published private(set) var score = 0
    @Published private(set) var shots = 0
    @Published private(set) var hits = 0
    @Published private(set) var streak = 0
    @Published private(set) var bestStreak = 0
    @Published private(set) var feedback: ShotFeedback?
    @Published private(set) var summary: SessionSummary?

    let mode: TrainingMode
    let settings: TrainingSettings

    private var lastTimestamp: TimeInterval?
    private var lastShotAt: TimeInterval = 0
    private var fieldSize: CGSize = .zero

    init(mode: TrainingMode, settings: TrainingSettings) {
        self.mode = mode
        self.settings = settings
        timeRemaining = TimeInterval(settings.duration)
    }

    func start(in size: CGSize, at timestamp: TimeInterval = Date.timeIntervalSinceReferenceDate) {
        fieldSize = size
        targets.removeAll()
        score = 0
        shots = 0
        hits = 0
        streak = 0
        bestStreak = 0
        feedback = nil
        summary = nil
        timeRemaining = TimeInterval(settings.duration)
        lastTimestamp = timestamp
        lastShotAt = 0
        phase = .running
        fillTargets(at: timestamp)
    }

    func tick(at timestamp: TimeInterval, in size: CGSize) {
        guard phase == .running else { return }
        fieldSize = size

        guard let previousTimestamp = lastTimestamp else {
            lastTimestamp = timestamp
            return
        }

        let delta = min(max(timestamp - previousTimestamp, 0), 1.0 / 20.0)
        let frameDelta = CGFloat(delta)
        lastTimestamp = timestamp
        timeRemaining = max(0, timeRemaining - delta)

        if timeRemaining <= 0 {
            finish()
            return
        }

        guard mode.targetsMove else { return }

        for index in targets.indices {
            var target = targets[index]
            target.position.x += target.velocity.dx * frameDelta
            target.position.y += target.velocity.dy * frameDelta
            bounce(&target, inside: size)
            targets[index] = target
        }
    }

    func pan(by translation: CGSize, in size: CGSize) {
        guard phase == .running else { return }
        fieldSize = size
        let scale = CGFloat(settings.sensitivity)

        for index in targets.indices {
            var target = targets[index]
            target.position.x -= translation.width * scale
            target.position.y -= translation.height * scale
            wrap(&target, inside: size)
            targets[index] = target
        }
    }

    func fire(in size: CGSize, at timestamp: TimeInterval = Date.timeIntervalSinceReferenceDate) {
        guard phase == .running, timestamp - lastShotAt >= 0.085 else { return }
        lastShotAt = timestamp
        shots += 1

        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let nearest = targets.enumerated().min { left, right in
            let leftDistance = AimMath.distance(from: left.element.position, to: center)
            let rightDistance = AimMath.distance(from: right.element.position, to: center)
            return leftDistance < rightDistance
        }

        if let nearest {
            let distance = AimMath.distance(from: nearest.element.position, to: center)
            let hitRadius = nearest.element.radius + 8

            if AimMath.isHit(target: nearest.element.position, center: center, hitRadius: hitRadius) {
                hits += 1
                streak += 1
                bestStreak = max(bestStreak, streak)
                let points = AimMath.score(
                    distance: distance,
                    hitRadius: hitRadius,
                    reactionTime: max(0, timestamp - nearest.element.spawnedAt),
                    streak: streak
                )
                score += points
                targets.remove(at: nearest.offset)
                fillTargets(at: timestamp)
                publishFeedback(isHit: true, points: points)
                haptic(hit: true)
                return
            }
        }

        streak = 0
        publishFeedback(isHit: false, points: 0)
        haptic(hit: false)
    }

    func togglePause() {
        switch phase {
        case .running:
            phase = .paused
        case .paused:
            lastTimestamp = nil
            phase = .running
        case .ready, .finished:
            break
        }
    }

    func pauseIfNeeded() {
        if phase == .running {
            phase = .paused
        }
    }

    private func finish() {
        phase = .finished
        summary = SessionSummary(
            mode: mode,
            score: score,
            shots: shots,
            hits: hits,
            bestStreak: bestStreak
        )
    }

    private func fillTargets(at timestamp: TimeInterval) {
        guard fieldSize.width > 0, fieldSize.height > 0 else { return }
        while targets.count < mode.targetCount {
            targets.append(makeTarget(at: timestamp))
        }
    }

    private func makeTarget(at timestamp: TimeInterval) -> AimTarget {
        let radius = CGFloat(settings.targetDiameter / 2)
        let horizontalInset = max(radius + 42, 74)
        let verticalInset = max(radius + 28, 54)
        let xRange = horizontalInset...max(horizontalInset, fieldSize.width - horizontalInset)
        let yRange = verticalInset...max(verticalInset, fieldSize.height - verticalInset)

        let velocity: CGVector
        if mode.targetsMove {
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let speed = CGFloat(settings.targetSpeed) * CGFloat.random(in: 0.82...1.18)
            velocity = CGVector(dx: cos(angle) * speed, dy: sin(angle) * speed)
        } else {
            velocity = .zero
        }

        return AimTarget(
            id: UUID(),
            position: CGPoint(x: CGFloat.random(in: xRange), y: CGFloat.random(in: yRange)),
            velocity: velocity,
            radius: radius,
            spawnedAt: timestamp
        )
    }

    private func bounce(_ target: inout AimTarget, inside size: CGSize) {
        let sideInset = target.radius + 24
        let topInset = target.radius + 38
        let bottomInset = target.radius + 24

        if target.position.x < sideInset {
            target.position.x = sideInset
            target.velocity.dx = abs(target.velocity.dx)
        } else if target.position.x > size.width - sideInset {
            target.position.x = size.width - sideInset
            target.velocity.dx = -abs(target.velocity.dx)
        }

        if target.position.y < topInset {
            target.position.y = topInset
            target.velocity.dy = abs(target.velocity.dy)
        } else if target.position.y > size.height - bottomInset {
            target.position.y = size.height - bottomInset
            target.velocity.dy = -abs(target.velocity.dy)
        }
    }

    private func wrap(_ target: inout AimTarget, inside size: CGSize) {
        let margin = target.radius + 18
        if target.position.x < -margin { target.position.x = size.width + margin }
        if target.position.x > size.width + margin { target.position.x = -margin }
        if target.position.y < -margin { target.position.y = size.height + margin }
        if target.position.y > size.height + margin { target.position.y = -margin }
    }

    private func publishFeedback(isHit: Bool, points: Int) {
        let event = ShotFeedback(isHit: isHit, points: points)
        feedback = event

        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 360_000_000)
            guard self?.feedback?.id == event.id else { return }
            self?.feedback = nil
        }
    }

    private func haptic(hit: Bool) {
        guard settings.hapticsEnabled else { return }
        if hit {
            UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.8)
        } else {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.35)
        }
    }
}
