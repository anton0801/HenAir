import Foundation

protocol Henhouse {
    func roost(_ archive: CoopArchive)
    func markRoute(url: String, mode: String)
    func raisePrimedFlag()
    func unroost() -> CoopArchive
}

final class JSONHenhouse: Henhouse {
    
    private let fm = FileManager.default
    private let dataDir: URL
    private let homeStore: UserDefaults
    private let suiteStore: UserDefaults
    
    init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.dataDir = docs.appendingPathComponent("HenCoop", isDirectory: true)
        if !fm.fileExists(atPath: dataDir.path) {
            try? fm.createDirectory(at: dataDir, withIntermediateDirectories: true)
        }
        self.homeStore = UserDefaults.standard
        self.suiteStore = UserDefaults(suiteName: CoopLingo.suiteCoop) ?? .standard
    }
    
    private var archiveURL: URL {
        dataDir.appendingPathComponent(CoopLingo.coopFile)
    }
    
    func roost(_ archive: CoopArchive) {
        let veiled = VeiledCoop(
            pecks: maskDict(archive.pecks),
            crows: maskDict(archive.crows),
            routeURL: archive.routeURL,
            routeMode: archive.routeMode,
            unhatched: archive.unhatched,
            consentNested: archive.consentNested,
            consentScattered: archive.consentScattered,
            consentMarkedAt: archive.consentMarkedAt
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .millisecondsSince1970
        
        do {
            let data = try encoder.encode(veiled)
            try data.write(to: archiveURL, options: .atomic)
        } catch {
        }
        
        suiteStore.set(archive.consentNested, forKey: "ha_consent_nested")
        suiteStore.set(archive.consentScattered, forKey: "ha_consent_scattered")
        if let date = archive.consentMarkedAt {
            suiteStore.set(date.timeIntervalSince1970, forKey: "ha_consent_marked_at")
        }
        homeStore.set(archive.consentNested, forKey: "ha_consent_nested")
        homeStore.set(archive.consentScattered, forKey: "ha_consent_scattered")
        if let date = archive.consentMarkedAt {
            homeStore.set(date.timeIntervalSince1970, forKey: "ha_consent_marked_at")
        }
    }
    
    func markRoute(url: String, mode: String) {
        suiteStore.set(url, forKey: CoopDictKey.routeURL)
        homeStore.set(url, forKey: CoopDictKey.routeURL)
        suiteStore.set(mode, forKey: CoopDictKey.routeMode)
    }
    
    func raisePrimedFlag() {
        suiteStore.set(true, forKey: CoopDictKey.primed)
        homeStore.set(true, forKey: CoopDictKey.primed)
    }
    
    func unroost() -> CoopArchive {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        
        if fm.fileExists(atPath: archiveURL.path),
           let data = try? Data(contentsOf: archiveURL),
           let veiled = try? decoder.decode(VeiledCoop.self, from: data) {
            return CoopArchive(
                pecks: unmaskDict(veiled.pecks),
                crows: unmaskDict(veiled.crows),
                routeURL: veiled.routeURL,
                routeMode: veiled.routeMode,
                unhatched: veiled.unhatched,
                consentNested: veiled.consentNested,
                consentScattered: veiled.consentScattered,
                consentMarkedAt: veiled.consentMarkedAt
            )
        }
        
        return restoreFromDefaults()
    }
    
    private func restoreFromDefaults() -> CoopArchive {
        let routeURL = homeStore.string(forKey: CoopDictKey.routeURL)
            ?? suiteStore.string(forKey: CoopDictKey.routeURL)
        let routeMode = suiteStore.string(forKey: CoopDictKey.routeMode)
        let primed = suiteStore.bool(forKey: CoopDictKey.primed)
        
        let nested = suiteStore.bool(forKey: "ha_consent_nested")
            || homeStore.bool(forKey: "ha_consent_nested")
        let scattered = suiteStore.bool(forKey: "ha_consent_scattered")
            || homeStore.bool(forKey: "ha_consent_scattered")
        let markedTs = suiteStore.double(forKey: "ha_consent_marked_at")
        let markedAt: Date? = markedTs > 0 ? Date(timeIntervalSince1970: markedTs) : nil
        
        return CoopArchive(
            pecks: [:], crows: [:],
            routeURL: routeURL, routeMode: routeMode,
            unhatched: !primed,
            consentNested: nested, consentScattered: scattered, consentMarkedAt: markedAt
        )
    }
    
    private func maskDict(_ dict: [String: String]) -> [String: String] {
        var result: [String: String] = [:]
        for (k, v) in dict { result[k] = mask(v) }
        return result
    }
    
    private func unmaskDict(_ dict: [String: String]) -> [String: String] {
        var result: [String: String] = [:]
        for (k, v) in dict { result[k] = unmask(v) ?? v }
        return result
    }
    
    private func mask(_ input: String) -> String {
        let b64 = Data(input.utf8).base64EncodedString()
        return b64
            .replacingOccurrences(of: "+", with: "!")
            .replacingOccurrences(of: "/", with: "*")
    }
    
    private func unmask(_ input: String) -> String? {
        let b64 = input
            .replacingOccurrences(of: "!", with: "+")
            .replacingOccurrences(of: "*", with: "/")
        guard let data = Data(base64Encoded: b64),
              let text = String(data: data, encoding: .utf8) else { return nil }
        return text
    }
}

struct VeiledCoop: Codable {
    let pecks: [String: String]
    let crows: [String: String]
    let routeURL: String?
    let routeMode: String?
    let unhatched: Bool
    let consentNested: Bool
    let consentScattered: Bool
    let consentMarkedAt: Date?
}
