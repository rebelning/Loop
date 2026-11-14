import Foundation

/// Managers can serve a background launch without creating onboarding or home UI.
enum LoopAppLaunchState: Int {
    case initialize, checkProtectedDataAvailable, launchManagers
    case launchOnboarding, launchHomeScreen, launchComplete

    var next: Self { Self(rawValue: rawValue + 1) ?? .launchComplete }

    func canRunBackgroundWork(onboardingComplete: Bool) -> Bool {
        rawValue >= Self.launchOnboarding.rawValue && onboardingComplete
    }

    func shouldLaunchOnboarding(hasWindow: Bool, alreadyLaunching: Bool) -> Bool {
        self == .launchOnboarding && hasWindow && !alreadyLaunching
    }
}

/// Pump callbacks can race task expiration, or arrive more than once.
/// Complete the system task once, without invoking a callback while holding a lock.
final class BackgroundRefreshCompletion {
    private let lock = NSLock()
    private var completion: ((Bool) -> Void)?

    init(_ completion: @escaping (Bool) -> Void) { self.completion = completion }

    func finish(_ success: Bool) {
        lock.lock()
        let callback = completion
        completion = nil
        lock.unlock()
        callback?(success)
    }
}
