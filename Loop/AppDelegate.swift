//
//  AppDelegate.swift
//  Naterade
//
//  Created by Nathan Racklyeft on 8/15/15.
//  Copyright © 2015 Nathan Racklyeft. All rights reserved.
//

import UIKit
import LoopKit
import BackgroundTasks

final class AppDelegate: UIResponder, UIApplicationDelegate {

    /// The shared app manager. Per-scene lifecycle is driven by `SceneDelegate`, which
    /// accesses this instance through the app delegate.
    let loopAppManager = LoopAppManager()

    /// The launch options passed at `didFinishLaunchingWithOptions`, retained so the
    /// scene delegate can forward them to `LoopAppManager` when it connects.
    private(set) var launchOptions: [UIApplication.LaunchOptionsKey: Any]?

    private let log = DiagnosticLog(category: "AppDelegate")

    // MARK: - UIApplicationDelegate - Initialization

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        log.default("%{public}@ with launchOptions: %{public}@", #function, String(describing: launchOptions))

        setenv("CFNETWORK_DIAGNOSTICS", "3", 1)

        log.default("lastPathComponent = %{public}@", String(describing: Bundle.main.appStoreReceiptURL?.lastPathComponent))

        // The window is owned by the scene, so app manager initialization and launch are
        // deferred to `SceneDelegate.scene(_:willConnectTo:options:)`.
        self.launchOptions = launchOptions
        let registered = DeviceDataManager.registerBackgroundProcessingTask { [weak self] task in
            guard let self, self.loopAppManager.isLaunchComplete else {
                task.setTaskCompleted(success: false)
                return
            }
            let deviceDataManager = self.loopAppManager.getDeviceDataManager()
            DispatchQueue.global(qos: .background).async {
                deviceDataManager.handleBackgroundProcessingTask(task)
            }
        }
        log.default("Background processing task registration: %{public}@", String(registered))
        return true
    }

    // MARK: - UIApplicationDelegate - Scene Configuration

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    // MARK: - UIApplicationDelegate - Environment

    func applicationProtectedDataDidBecomeAvailable(_ application: UIApplication) {
        DispatchQueue.main.async {
            if self.loopAppManager.isLaunchPending {
                self.loopAppManager.launch()
            }
        }
    }

    // MARK: - UIApplicationDelegate - Remote Notification

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        log.default(#function)

        loopAppManager.remoteNotificationRegistrationDidFinish(.success(deviceToken))
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        log.error("%{public}@ with error: %{public}@", #function, String(describing: error))
        loopAppManager.remoteNotificationRegistrationDidFinish(.failure(error))
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        log.default(#function)

        completionHandler(loopAppManager.handleRemoteNotification(userInfo as? [String: AnyObject]) ? .noData : .failed)
    }

    // MARK: - UIApplicationDelegate - Interface

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return loopAppManager.supportedInterfaceOrientations
    }
    
    // MARK: - UIApplicationDelegate - performFetchWithCompletionHandler
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
            log.default("Performing background fetch")
            loopAppManager.performFetch { result in
                switch result {
                case .newData:
                    completionHandler(.newData)
                case .noData:
                    completionHandler(.noData)
                case .failed:
                    completionHandler(.failed)
                @unknown default:
                    completionHandler(.failed)
                }
            }
        }
}
