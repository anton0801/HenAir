import Foundation

enum CoopHitch: Error, CustomStringConvertible {
    case feedScarce(at: String)
    case packetCracked(at: String)
    case wireKnotted(stage: String)
    case heatThrottled(coolDown: TimeInterval)
    case clockExpired(stage: String)
    case routeFenced(httpCode: Int)
    case barnSealed(reason: String)
    
    var description: String {
        switch self {
        case .feedScarce(let at): return "feedScarce(\(at))"
        case .packetCracked(let at): return "packetCracked(\(at))"
        case .wireKnotted(let stage): return "wireKnotted(\(stage))"
        case .heatThrottled(let cd): return "heatThrottled(cd=\(cd))"
        case .clockExpired(let stage): return "clockExpired(\(stage))"
        case .routeFenced(let code): return "routeFenced(\(code))"
        case .barnSealed(let reason): return "barnSealed(\(reason))"
        }
    }
    
    var isFenced: Bool {
        switch self {
        case .routeFenced, .barnSealed: return true
        default: return false
        }
    }
    
    var isWire: Bool {
        switch self {
        case .wireKnotted, .heatThrottled, .clockExpired: return true
        default: return false
        }
    }
}
