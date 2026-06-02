import Foundation

struct CoopArchive: Codable {
    let pecks: [String: String]
    let crows: [String: String]
    let routeURL: String?
    let routeMode: String?
    let unhatched: Bool
    let consentNested: Bool
    let consentScattered: Bool
    let consentMarkedAt: Date?
}

enum FlightOutcome: Equatable {
    case hovering
    case askConsent
    case openDisplay
    case grounded
}

final class FlightTicket {
    private var stamped: Bool = false
    private let lock = NSLock()
    
    func tryStamp() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        guard !stamped else { return false }
        stamped = true
        return true
    }
    
    var isStamped: Bool {
        lock.lock()
        defer { lock.unlock() }
        return stamped
    }
}
