import UIKit

/// Class defines methods to allow running of closures when app comes to foreground or to background
class ApplicationManager {

    // MARK: - Private Properties
    
    /// List of closures to run when app enters background
    private var closuresToRunWhenAppDidEnterBackground = [String : (() -> Void)]()
    
    /// List of closures to run when app enters foreground
    private var closuresToRunWhenAppWillEnterForeground = [String : (() -> Void)]()
    
    // MARK: - Public Properties
    
    /// Access to shared instance of ApplicationManager
    static let shared = ApplicationManager()
    
    // MARK: - Initializer
    
    /// Init is private to avoid creation
    private init() {
        // Setup notification handling
        setupNotificationHandling()
    }
    
    // MARK: - Public Functions
    
    /// Adds closure to run identified by key when app moves to background
    ///
    /// - Parameters:
    ///   - key: Identifier key
    ///   - closure: Closure to run
    func addClosureToRunWhenAppDidEnterBackground(key: String, closure: @escaping () -> Void) {
        closuresToRunWhenAppDidEnterBackground[key] = closure
    }
    
    /// Adds closure to run identified by key when app moves to foreground
    ///
    /// - Parameters:
    ///   - key: Identifier key
    ///   - closure: Closure to run
    func addClosureToRunWhenAppWillEnterForeground(key: String, closure: @escaping () -> Void) {
        closuresToRunWhenAppWillEnterForeground[key] = closure
    }
    
    
    /// removes closure to run identified by key, when app moved to background
    ///
    /// closures are stored in a dictionary, key is the identifier
    func removeClosureToRunWhenAppDidEnterBackground(key:String) {
        closuresToRunWhenAppDidEnterBackground[key] = nil
    }
    
    /// removes closure to run identified by key, when app moved to foreground
    ///
    /// closures are stored in a dictionary, key is the identifier
    func removeClosureToRunWhenAppWillEnterForeground(key:String) {
        closuresToRunWhenAppWillEnterForeground[key] = nil
    }
    
 
    
    
    // MARK: - Private Helper Functions
    
    private func setupNotificationHandling() {
        // Define notification center
        let notificationCenter = NotificationCenter.default
        
        // Add observer for did enter background
        notificationCenter.addObserver(self, selector: #selector(runWhenAppDidEnterBackground(_:)), name: UIApplication.didEnterBackgroundNotification, object: nil)
        
        // Add observer for will enter foreground
        notificationCenter.addObserver(self, selector: #selector(runWhenAppWillEnterForeground(_:)), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    @objc private func runWhenAppDidEnterBackground(_ : Notification) {
        // Run the closures
        for closure in closuresToRunWhenAppDidEnterBackground {
            closure.value()
        }
    }

    @objc private func runWhenAppWillEnterForeground(_ : Notification) {
        // Run the closures
        for closure in closuresToRunWhenAppWillEnterForeground {
            closure.value()
        }
    }
}
