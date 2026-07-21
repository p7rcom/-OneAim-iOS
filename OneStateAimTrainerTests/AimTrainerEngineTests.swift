import XCTest
import CoreGraphics
import Foundation
@testable import OneStateAimTrainer

final class AimTrainerEngineTests: XCTestCase {
    func testAccuracyUsesShotsAsDenominator() {
        XCTAssertEqual(AimMath.accuracy(hits: 3, shots: 4), 75, accuracy: 0.001)
        XCTAssertEqual(AimMath.accuracy(hits: 0, shots: 0), 0)
    }

    func testHitDetectionIncludesBoundary() {
        let center = CGPoint(x: 100, y: 100)
        XCTAssertTrue(AimMath.isHit(target: CGPoint(x: 120, y: 100), center: center, hitRadius: 20))
        XCTAssertFalse(AimMath.isHit(target: CGPoint(x: 121, y: 100), center: center, hitRadius: 20))
    }

    func testPreciseFastShotScoresHigher() {
        let precise = AimMath.score(distance: 0, hitRadius: 30, reactionTime: 0.25, streak: 4)
        let edge = AimMath.score(distance: 28, hitRadius: 30, reactionTime: 1.5, streak: 0)
        XCTAssertGreaterThan(precise, edge)
    }

    func testModeTargetCounts() {
        XCTAssertEqual(TrainingMode.flick.targetCount, 1)
        XCTAssertEqual(TrainingMode.moving.targetCount, 1)
        XCTAssertEqual(TrainingMode.chaos.targetCount, 3)
    }

    @MainActor
    func testHorizontalPanFollowsDragDirection() {
        let fieldSize = CGSize(width: 390, height: 844)
        let settings = TrainingSettings(
            sensitivity: 1,
            targetDiameter: 46,
            targetSpeed: 130,
            duration: 60,
            fireButtonSide: .left,
            crosshairTint: .cyan,
            hapticsEnabled: false
        )
        let engine = AimTrainerEngine(mode: .flick, settings: settings)
        engine.start(in: fieldSize, at: 0)

        let initialX = try! XCTUnwrap(engine.targets.first).position.x
        engine.pan(by: CGSize(width: -12, height: 0), in: fieldSize)

        XCTAssertEqual(engine.targets[0].position.x, initialX - 12, accuracy: 0.001)
    }

    func testFireButtonUsesPhysicalScreenSide() {
        let landscape = CGSize(width: 844, height: 390)
        let left = AimLayout.fireButtonCenter(for: .left, in: landscape)
        let right = AimLayout.fireButtonCenter(for: .right, in: landscape)

        XCTAssertLessThan(left.x, landscape.width / 2)
        XCTAssertGreaterThan(right.x, landscape.width / 2)
        XCTAssertEqual(left.x, 104, accuracy: 0.001)
        XCTAssertEqual(right.x, 740, accuracy: 0.001)
        XCTAssertEqual(left.y, right.y, accuracy: 0.001)
    }

    @MainActor
    func testRightFireButtonPreferencePersistsIntoSession() {
        let suiteName = "OneStateAimTrainerTests.\(UUID().uuidString)"
        let defaults = try! XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let settings = AppSettings(defaults: defaults)
        settings.fireButtonSide = .right

        XCTAssertEqual(settings.snapshot.fireButtonSide, .right)
        XCTAssertEqual(AppSettings(defaults: defaults).fireButtonSide, .right)
    }
}
