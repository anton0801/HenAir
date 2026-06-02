import Foundation
import UIKit
import UserNotifications

protocol Doorman {
    func openDoor() async -> Bool
    func raiseFlagPush()
}

final class NotificationDoorman: Doorman {
    
    func openDoor() async -> Bool {
        await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
            let onceLatch = OnceLatch()
            UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .sound, .badge]
            ) { granted, error in
                DispatchQueue.main.async {
                    guard onceLatch.tryLatch() else { return }
                    continuation.resume(returning: granted)
                }
            }
        }
    }
    
    func raiseFlagPush() {
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
}

final class OnceLatch {
    private var latched = false
    private let lock = NSLock()
    
    func tryLatch() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        guard !latched else { return false }
        latched = true
        return true
    }
}
