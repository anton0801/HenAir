import Foundation

final class PipelineContext {
    var coop: CoopMain
    let bundle: ServiceBundle
    
    init(coop: CoopMain, bundle: ServiceBundle) {
        self.coop = coop
        self.bundle = bundle
    }
}

enum StageVerdict {
    case advance
    case halt(FlightOutcome)
    case stumbled(CoopHitch)
}

protocol FlightStage: AnyObject {
    var stageID: String { get }
    func process(context: PipelineContext) async -> StageVerdict
}
