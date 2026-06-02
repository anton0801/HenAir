import UIKit
import FirebaseCore
import FirebaseMessaging
import AppTrackingTransparency
import UserNotifications
import AdjustSdk
import AdSupport

final class AppDelegate: UIResponder, UIApplicationDelegate {
    
    private lazy var firebaseInit = FirebaseInitializer()
    private lazy var messagingInit = MessagingInitializer(host: self)
    private lazy var notificationsInit = NotificationsInitializer(host: self)
    private lazy var adjustInit = AdjustInitializer(host: self)
    private lazy var fusionInit = FusionInitializer()
    private lazy var pushHarvestInit = PushHarvestInitializer()
    
    private var initializerChain: [Initializer] {
        [firebaseInit, messagingInit, notificationsInit, adjustInit, fusionInit, pushHarvestInit]
    }
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        for initializer in initializerChain {
            initializer.runInit()
        }
        
        if let remote = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
            pushHarvestInit.harvest(remote)
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onActivation),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        return true
    }
    
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Messaging.messaging().apnsToken = deviceToken
        Adjust.setPushToken(deviceToken)
    }
    
    @objc private func onActivation() {
        adjustInit.startTracking()
    }
}

// MARK: - MessagingDelegate

extension AppDelegate: MessagingDelegate {
    func messaging(
        _ messaging: Messaging,
        didReceiveRegistrationToken fcmToken: String?
    ) {
        messaging.token { token, err in
            guard err == nil, let t = token else { return }
            UserDefaults.standard.set(t, forKey: CoopDictKey.fcm)
            UserDefaults.standard.set(t, forKey: CoopDictKey.push)
            UserDefaults(suiteName: CoopLingo.suiteCoop)?.set(t, forKey: "shared_fcm")
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        pushHarvestInit.harvest(notification.request.content.userInfo)
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        pushHarvestInit.harvest(response.notification.request.content.userInfo)
        completionHandler()
    }
    
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        pushHarvestInit.harvest(userInfo)
        completionHandler(.newData)
    }
}

// MARK: - AdjustDelegate

extension AppDelegate: AdjustDelegate {
    
    func adjustAttributionChanged(_ attribution: ADJAttribution?) {
        guard let attribution else { return }
        
        var data: [AnyHashable: Any] = [:]
        if let network      = attribution.network      { data["network"]       = network }
        if let campaign     = attribution.campaign     { data["campaign"]      = campaign }
        if let adgroup      = attribution.adgroup      { data["adgroup"]       = adgroup }
        if let creative     = attribution.creative     { data["creative"]      = creative }
        if let clickLabel   = attribution.clickLabel   { data["click_label"]   = clickLabel }
        if let trackerName  = attribution.trackerName  { data["tracker_name"]  = trackerName }
        if let trackerToken = attribution.trackerToken { data["tracker_token"] = trackerToken }
        if let costType     = attribution.costType     { data["cost_type"]     = costType }
        if let costAmount   = attribution.costAmount   { data["cost_amount"]   = costAmount }
        if let costCurrency = attribution.costCurrency { data["cost_currency"] = costCurrency }
        data["is_organic"] = attribution.network == nil || attribution.network == "Organic"
        
        fusionInit.acceptPecks(data)
        
        NotificationCenter.default.post(name: .init("AdjustAttributionReceived"), object: nil)
    }
    
    func adjustSessionTrackingFailed(_ sessionFailureResponseData: ADJSessionFailure?) {
        let desc = sessionFailureResponseData?.message ?? "unknown"
        fusionInit.acceptPecks(["error": true, "error_desc": desc])
    }
    
    func adjustDeeplinkResponse(_ deeplink: URL?) -> Bool {
        guard let deeplink else { return false }
        guard !UserDefaults.standard.bool(forKey: CoopDictKey.primed) else { return true }
        
        let data: [AnyHashable: Any] = [
            "deeplink_url":    deeplink.absoluteString,
            "deeplink_scheme": deeplink.scheme ?? "",
            "deeplink_host":   deeplink.host ?? "",
            "deeplink_path":   deeplink.path
        ]
        fusionInit.acceptCrows(data)
        return true
    }
}

protocol Initializer: AnyObject {
    func runInit()
}

final class FirebaseInitializer: Initializer {
    func runInit() {
        FirebaseApp.configure()
    }
}

final class MessagingInitializer: Initializer {
    private weak var host: MessagingDelegate?
    
    init(host: MessagingDelegate) { self.host = host }
    
    func runInit() {
        Messaging.messaging().delegate = host
        UIApplication.shared.registerForRemoteNotifications()
    }
}

final class NotificationsInitializer: Initializer {
    private weak var host: UNUserNotificationCenterDelegate?
    
    init(host: UNUserNotificationCenterDelegate) { self.host = host }
    
    func runInit() {
        UNUserNotificationCenter.current().delegate = host
    }
}

final class AdjustInitializer: Initializer {
    private weak var adjustDelegate: (NSObject & AdjustDelegate)?
    private static var trackingStarted = false
    
    init(host: NSObject & AdjustDelegate) {
        self.adjustDelegate = host
    }
    
    func runInit() { }
    
    func startTracking() {
        guard !AdjustInitializer.trackingStarted else { return }
        
        if #available(iOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization { [weak self] status in
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    guard !AdjustInitializer.trackingStarted else { return }
                    AdjustInitializer.trackingStarted = true
                    UserDefaults.standard.set(status.rawValue, forKey: "att_status")
                    self?.initAdjust()
                    NotificationCenter.default.post(name: .init("ATTConsentDone"), object: nil)
                    let idfa = ASIdentifierManager.shared().advertisingIdentifier.uuidString
                    UserDefaults.standard.set(idfa, forKey: "idfa_user")
                }
            }
        } else {
            AdjustInitializer.trackingStarted = true
            initAdjust()
            NotificationCenter.default.post(name: .init("ATTConsentDone"), object: nil)
        }
    }
    
    private func initAdjust() {
        guard let config = ADJConfig(
            appToken: CoopLingo.adjustAppToken,
            environment: ADJEnvironmentProduction
        ) else {
            return
        }
        config.delegate = adjustDelegate
        config.logLevel = ADJLogLevel.suppress
        Adjust.initSdk(config)
        Adjust.idfv { adIdfv in
            let idfv = adIdfv ?? self.getIDFV()
            UserDefaults.standard.set(idfv, forKey: "idfv_user")
        }
    }
    
    func getIDFV() -> String {
        return UIDevice.current.identifierForVendor?.uuidString ?? "Unavailable"
    }
    
}

// MARK: - FusionInitializer

final class FusionInitializer: Initializer {
    
    private var pecksBuffer: [AnyHashable: Any] = [:]
    private var crowsBuffer: [AnyHashable: Any] = [:]
    private var fuseTimer: Timer?
    
    func runInit() {}
    
    func acceptPecks(_ data: [AnyHashable: Any]) {
        pecksBuffer = data
        scheduleFuse()
        if !crowsBuffer.isEmpty { performFuse() }
    }
    
    func acceptCrows(_ data: [AnyHashable: Any]) {
        guard !UserDefaults.standard.bool(forKey: CoopDictKey.primed) else { return }
        crowsBuffer = data
        NotificationCenter.default.post(
            name: .deeplinksRoost,
            object: nil,
            userInfo: ["deeplinksData": data]
        )
        fuseTimer?.invalidate()
        if !pecksBuffer.isEmpty { performFuse() }
    }
    
    private func scheduleFuse() {
        fuseTimer?.invalidate()
        fuseTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false) { [weak self] _ in
            self?.performFuse()
        }
    }
    
    private func performFuse() {
        var combined = pecksBuffer
        for (k, v) in crowsBuffer {
            let prefixed = "deep_\(k)"
            if combined[prefixed] == nil {
                combined[prefixed] = v
            }
        }
        NotificationCenter.default.post(
            name: .attributionRoost,
            object: nil,
            userInfo: ["conversionData": combined]
        )
    }
}

// MARK: - PushHarvestInitializer

final class PushHarvestInitializer: Initializer {
    
    func runInit() {}
    
    func harvest(_ payload: [AnyHashable: Any]) {
        guard let url = extract(payload) else { return }
        UserDefaults.standard.set(url, forKey: CoopDictKey.pushURL)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
            NotificationCenter.default.post(
                name: .pushPerch,
                object: nil,
                userInfo: ["temp_url": url]
            )
        }
    }
    
    private func extract(_ payload: [AnyHashable: Any]) -> String? {
        if let direct = payload["url"] as? String { return direct }
        if let nested = payload["data"] as? [String: Any],
           let url = nested["url"] as? String { return url }
        if let aps = payload["aps"] as? [String: Any],
           let nested = aps["data"] as? [String: Any],
           let url = nested["url"] as? String { return url }
        if let custom = payload["custom"] as? [String: Any],
           let url = custom["target_url"] as? String { return url }
        return nil
    }
}
