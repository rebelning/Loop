import XCTest
import UIKit
@testable import Loop

@MainActor
final class BackgroundLaunchTests: XCTestCase {
    func testFetchBeforeInitializationFailsWithoutAccessingManagers() {
        let manager = LoopAppManager()
        var result: UIBackgroundFetchResult?
        manager.performFetch { result = $0 }
        XCTAssertEqual(result, .failed)
    }

    func testEarlyForegroundResetCheckDoesNotAccessUninitializedManagers() {
        let manager = LoopAppManager()
        manager.askUserToConfirmLoopReset()
        XCTAssertFalse(manager.isLaunchComplete)
        XCTAssertFalse(manager.isReadyForBackgroundWork)
    }

    func testProtectedDataAndManagersMustBeReady() {
        for state in [LoopAppLaunchState.initialize, .checkProtectedDataAvailable, .launchManagers] {
            XCTAssertFalse(state.canRunBackgroundWork(onboardingComplete: true))
        }
    }

    func testHeadlessBackgroundWorkDoesNotRequireUICompletion() {
        XCTAssertTrue(LoopAppLaunchState.launchOnboarding.canRunBackgroundWork(onboardingComplete: true))
        XCTAssertFalse(LoopAppLaunchState.launchOnboarding.canRunBackgroundWork(onboardingComplete: false))
        XCTAssertFalse(LoopAppLaunchState.launchOnboarding.shouldLaunchOnboarding(hasWindow: false, alreadyLaunching: false))
    }

    func testSceneAttachmentDoesNotRepeatOnboarding() {
        XCTAssertTrue(LoopAppLaunchState.launchOnboarding.shouldLaunchOnboarding(hasWindow: true, alreadyLaunching: false))
        XCTAssertFalse(LoopAppLaunchState.launchOnboarding.shouldLaunchOnboarding(hasWindow: true, alreadyLaunching: true))
        XCTAssertFalse(LoopAppLaunchState.launchComplete.shouldLaunchOnboarding(hasWindow: true, alreadyLaunching: false))
    }
    func testExpiredTaskIgnoresLateCompletion() {
        var results: [Bool] = []
        let completion = BackgroundRefreshCompletion { results.append($0) }
        completion.finish(false)
        completion.finish(true)
        completion.finish(true)
        XCTAssertEqual(results, [false])
    }

    func testCompletedTaskIgnoresLateExpiration() {
        var results: [Bool] = []
        let completion = BackgroundRefreshCompletion { results.append($0) }
        completion.finish(true)
        completion.finish(false)
        XCTAssertEqual(results, [true])
    }

}
