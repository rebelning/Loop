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

final class AppDelegate: UIResponder, UIApplicationDelegate, WindowProvider {

    weak var window: UIWindow?

    /// Shared by background callbacks and the scene; its UI phase waits for a window.
    let loopAppManager = LoopAppManager()

    private let log = DiagnosticLog(category: "AppDelegate")

    // MARK: - UIApplicationDelegate - Initialization

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        log.default("%{public}@ with launchOptions: %{public}@", #function, String(describing: launchOptions))

        setenv("CFNETWORK_DIAGNOSTICS", "3", 1)

        log.default("lastPathComponent = %{public}@", String(describing: Bundle.main.appStoreReceiptURL?.lastPathComponent))

        let registered = DeviceDataManager.registerBackgroundProcessingTask { [weak self] task in
            DispatchQueue.main.async {
                guard let self else {
                    task.setTaskCompleted(success: false)
                    return
                }
                if self.loopAppManager.isLaunchPending { self.loopAppManager.launch() }
                guard self.loopAppManager.isReadyForBackgroundWork else {
                    self.log.default("[background] managers unavailable or onboarding incomplete; rescheduling")
                    DeviceDataManager.scheduleBackgroundProcessingRetry()
                    task.setTaskCompleted(success: false)
                    return
                }
                let manager = self.loopAppManager.getDeviceDataManager()
                DispatchQueue.global(qos: .background).async {
                    manager.handleBackgroundProcessingTask(task)
                }
            }
        }
        // Initialize managers even when iOS launches us without connecting a scene.
        // The UI/onboarding phase stays pending until SceneDelegate supplies its window.
        loopAppManager.initialize(windowProvider: self, launchOptions: launchOptions)
        loopAppManager.launch()
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
