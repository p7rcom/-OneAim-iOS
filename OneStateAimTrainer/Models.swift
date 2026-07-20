import SwiftUI
import Combine
import Foundation

enum TrainingMode: String, CaseIterable, Identifiable {
    case flick
    case moving
    case chaos

    var id: String { rawValue }

    var title: String {
        switch self {
        case .flick: return "فلك سريع"
        case .moving: return "هدف متحرك"
        case .chaos: return "فوضى الأهداف"
        }
    }

    var subtitle: String {
        switch self {
        case .flick: return "هدف ثابت واحد — دقة وسرعة النقل"
        case .moving: return "هدف واحد يتحرك — تتبع وتحكم ناعم"
        case .chaos: return "ثلاثة أهداف — اختيار وردة فعل"
        }
    }

    var symbol: String {
        switch self {
        case .flick: return "scope"
        case .moving: return "figure.run"
        case .chaos: return "circle.grid.cross"
        }
    }

    var targetCount: Int {
        switch self {
        case .flick, .moving: return 1
        case .chaos: return 3
        }
    }

    var targetsMove: Bool { self != .flick }
}

enum FireButtonSide: String, CaseIterable, Identifiable {
    case left
    case right

    var id: String { rawValue }
    var title: String { self == .left ? "يسار" : "يمين" }
}

enum CrosshairTint: String, CaseIterable, Identifiable {
    case cyan
    case green
    case red
    case white

    var id: String { rawValue }

    var title: String {
        switch self {
        case .cyan: return "سماوي"
        case .green: return "أخضر"
        case .red: return "أحمر"
        case .white: return "أبيض"
        }
    }
}

struct TrainingSettings: Equatable {
    var sensitivity: Double
    var targetDiameter: Double
    var targetSpeed: Double
    var duration: Int
    var fireButtonSide: FireButtonSide
    var crosshairTint: CrosshairTint
    var hapticsEnabled: Bool
}

@MainActor
final class AppSettings: ObservableObject {
    @Published var sensitivity: Double { didSet { persist() } }
    @Published var targetDiameter: Double { didSet { persist() } }
    @Published var targetSpeed: Double { didSet { persist() } }
    @Published var duration: Int { didSet { persist() } }
    @Published var fireButtonSide: FireButtonSide { didSet { persist() } }
    @Published var crosshairTint: CrosshairTint { didSet { persist() } }
    @Published var hapticsEnabled: Bool { didSet { persist() } }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        sensitivity = defaults.object(forKey: Keys.sensitivity) as? Double ?? 1.0
        targetDiameter = defaults.object(forKey: Keys.targetDiameter) as? Double ?? 46
        targetSpeed = defaults.object(forKey: Keys.targetSpeed) as? Double ?? 130

        let storedDuration = defaults.integer(forKey: Keys.duration)
        duration = storedDuration == 0 ? 60 : storedDuration

        fireButtonSide = FireButtonSide(
            rawValue: defaults.string(forKey: Keys.fireButtonSide) ?? ""
        ) ?? .left
        crosshairTint = CrosshairTint(
            rawValue: defaults.string(forKey: Keys.crosshairTint) ?? ""
        ) ?? .cyan

        if defaults.object(forKey: Keys.hapticsEnabled) == nil {
            hapticsEnabled = true
        } else {
            hapticsEnabled = defaults.bool(forKey: Keys.hapticsEnabled)
        }
    }

    var snapshot: TrainingSettings {
        TrainingSettings(
            sensitivity: sensitivity,
            targetDiameter: targetDiameter,
            targetSpeed: targetSpeed,
            duration: duration,
            fireButtonSide: fireButtonSide,
            crosshairTint: crosshairTint,
            hapticsEnabled: hapticsEnabled
        )
    }

    private func persist() {
        defaults.set(sensitivity, forKey: Keys.sensitivity)
        defaults.set(targetDiameter, forKey: Keys.targetDiameter)
        defaults.set(targetSpeed, forKey: Keys.targetSpeed)
        defaults.set(duration, forKey: Keys.duration)
        defaults.set(fireButtonSide.rawValue, forKey: Keys.fireButtonSide)
        defaults.set(crosshairTint.rawValue, forKey: Keys.crosshairTint)
        defaults.set(hapticsEnabled, forKey: Keys.hapticsEnabled)
    }

    private enum Keys {
        static let sensitivity = "aim.sensitivity"
        static let targetDiameter = "aim.targetDiameter"
        static let targetSpeed = "aim.targetSpeed"
        static let duration = "aim.duration"
        static let fireButtonSide = "aim.fireButtonSide"
        static let crosshairTint = "aim.crosshairTint"
        static let hapticsEnabled = "aim.hapticsEnabled"
    }
}

struct AimTarget: Identifiable {
    let id: UUID
    var position: CGPoint
    var velocity: CGVector
    var radius: CGFloat
    var spawnedAt: TimeInterval
}

enum SessionPhase: Equatable {
    case ready
    case running
    case paused
    case finished
}

struct ShotFeedback: Identifiable, Equatable {
    let id = UUID()
    let isHit: Bool
    let points: Int
}

struct SessionSummary: Equatable {
    let mode: TrainingMode
    let score: Int
    let shots: Int
    let hits: Int
    let bestStreak: Int

    var accuracy: Double { AimMath.accuracy(hits: hits, shots: shots) }
}

enum AimMath {
    static func distance(from point: CGPoint, to other: CGPoint) -> CGFloat {
        hypot(point.x - other.x, point.y - other.y)
    }

    static func isHit(target: CGPoint, center: CGPoint, hitRadius: CGFloat) -> Bool {
        distance(from: target, to: center) <= hitRadius
    }

    static func accuracy(hits: Int, shots: Int) -> Double {
        guard shots > 0 else { return 0 }
        return (Double(hits) / Double(shots)) * 100
    }

    static func score(distance: CGFloat, hitRadius: CGFloat, reactionTime: TimeInterval, streak: Int) -> Int {
        guard hitRadius > 0 else { return 0 }
        let precision = max(0, 1 - Double(distance / hitRadius))
        let reactionBonus = max(0, 80 - Int(reactionTime * 18))
        return 100 + Int(precision * 100) + reactionBonus + min(streak * 3, 60)
    }
}
