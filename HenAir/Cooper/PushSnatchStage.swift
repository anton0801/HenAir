import Foundation

final class PushSnatchStage: FlightStage {
    let stageID = "pushSnatch"
    
    func process(context: PipelineContext) async -> StageVerdict {
        guard let pushURL = UserDefaults.standard.string(forKey: CoopDictKey.pushURL),
              !pushURL.isEmpty else {
            return .advance
        }
        
        let needsConsent = context.coop.consentRipe
        
        context.coop.routeURL = pushURL
        context.coop.routeMode = "Active"
        context.coop.unhatched = false
        context.coop.roosted = true
        
        context.bundle.henhouse.roost(context.coop.crystallize())
        context.bundle.henhouse.markRoute(url: pushURL, mode: "Active")
        context.bundle.henhouse.raisePrimedFlag()
        UserDefaults.standard.removeObject(forKey: CoopDictKey.pushURL)
        
        return .halt(needsConsent ? .askConsent : .openDisplay)
    }
}

final class PecksReadyStage: FlightStage {
    let stageID = "pecksReady"
    
    func process(context: PipelineContext) async -> StageVerdict {
        guard context.coop.pecksReady else {
            return .halt(.hovering)
        }
        return .advance
    }
}

final class BarnCrowingStage: FlightStage {
    let stageID = "barnCrowing"
    
    func process(context: PipelineContext) async -> StageVerdict {
        guard context.coop.pecksReady else {
            return .halt(.hovering)
        }
        
        let seed = context.coop.pecks.mapValues { $0 as Any }
        
        do {
            let url = try await context.bundle.crower.crow(seed: seed)
            
            let needsConsent = context.coop.consentRipe
            
            context.coop.routeURL = url
            context.coop.routeMode = "Active"
            context.coop.unhatched = false
            context.coop.roosted = true
            
            context.bundle.henhouse.roost(context.coop.crystallize())
            context.bundle.henhouse.markRoute(url: url, mode: "Active")
            context.bundle.henhouse.raisePrimedFlag()
            UserDefaults.standard.removeObject(forKey: CoopDictKey.pushURL)
            
            return .halt(needsConsent ? .askConsent : .openDisplay)
        } catch let hitch as CoopHitch {
            return .stumbled(hitch)
        } catch {
            return .stumbled(.wireKnotted(stage: "barnCrowing"))
        }
    }
}
