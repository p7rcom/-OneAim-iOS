import XCTest
import CoreGraphics
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
}
