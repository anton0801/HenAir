import Foundation
import AdjustSdk
import FirebaseCore
import FirebaseMessaging
import WebKit

protocol Crower {
    func crow(seed: [String: Any]) async throws -> String
}

final class HTTPCrower: Crower {
    
    private let session: URLSession
    
    init() {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 90
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        config.urlCache = nil
        self.session = URLSession(configuration: config)
    }
    
    private var browserAgent: String = WKWebView().value(forKey: "userAgent") as? String ?? ""
    private let restPauses: [Double] = [98.0, 196.0, 392.0]
    
    func crow(seed: [String: Any]) async throws -> String {
        guard let endpoint = URL(string: CoopLingo.backendBarn) else {
            throw CoopHitch.packetCracked(at: "crower.url")
        }
        
        var body: [String: Any] = seed
        body["os"] = "iOS"
        body["adjust_id"] = await Adjust.adid() ?? ""
        body["bundle_id"] = Bundle.main.bundleIdentifier ?? ""
        body["idfa"] = UserDefaults.standard.string(forKey: "idfa_user") ?? ""
        body["firebase_project_id"] = FirebaseApp.app()?.options.gcmSenderID
        body["store_id"] = "id\(CoopLingo.appCode)"
        body["idfv"] = UserDefaults.standard.string(forKey: "idfv_user") ?? ""
        body["push_token"] = UserDefaults.standard.string(forKey: CoopDictKey.push)
            ?? Messaging.messaging().fcmToken
        body["locale"] = Locale.preferredLanguages.first?.prefix(2).uppercased() ?? "EN"
        
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(browserAgent, forHTTPHeaderField: "User-Agent")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        var lastHitch: Error?
        
        for (idx, pause) in restPauses.enumerated() {
            do {
                return try await fireSalvo(request)
            } catch let hitch as CoopHitch {
                if hitch.isFenced { throw hitch }
                if case .heatThrottled(let coolDown) = hitch {
                    try await Task.sleep(nanoseconds: UInt64(coolDown * 1_000_000_000))
                    continue
                }
                lastHitch = hitch
                if idx < restPauses.count - 1 {
                    try await Task.sleep(nanoseconds: UInt64(pause * 1_000_000_000))
                }
            } catch {
                lastHitch = error
                if idx < restPauses.count - 1 {
                    try await Task.sleep(nanoseconds: UInt64(pause * 1_000_000_000))
                }
            }
        }
        
        if let lastHitch = lastHitch { throw lastHitch }
        throw CoopHitch.wireKnotted(stage: "crower.exhausted")
    }
    
    private func fireSalvo(_ request: URLRequest) async throws -> String {
        let (data, response) = try await session.data(for: request)
        
        guard let http = response as? HTTPURLResponse else {
            throw CoopHitch.wireKnotted(stage: "crower.response")
        }
        
        if http.statusCode == 404 {
            throw CoopHitch.routeFenced(httpCode: 404)
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw CoopHitch.packetCracked(at: "crower.json")
        }
        
        guard let ok = json["ok"] as? Bool else {
            throw CoopHitch.packetCracked(at: "crower.missingOk")
        }
        
        if !ok {
            throw CoopHitch.barnSealed(reason: "okFalse")
        }
        
        guard let url = json["url"] as? String, !url.isEmpty else {
            throw CoopHitch.packetCracked(at: "crower.missingURL")
        }
        
        return url
    }
}
