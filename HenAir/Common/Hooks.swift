import Foundation

protocol PipelineHook: AnyObject {
    var hookID: String { get }
    func onStageEnter(_ stageID: String)
    func onStageVerdict(_ stageID: String, verdict: StageVerdict)
}

@MainActor
final class HookBundle {
    private var hooks: [PipelineHook] = []
    
    func attach(_ hook: PipelineHook) {
        hooks.append(hook)
    }
    
    func fireStageEnter(_ stageID: String) {
        for hook in hooks {
            hook.onStageEnter(stageID)
        }
    }
    
    func fireStageVerdict(_ stageID: String, verdict: StageVerdict) {
        for hook in hooks {
            hook.onStageVerdict(stageID, verdict: verdict)
        }
    }
}

final class TraceHook: PipelineHook {
    let hookID = "trace"
    
    func onStageEnter(_ stageID: String) {
    }
    
    func onStageVerdict(_ stageID: String, verdict: StageVerdict) {
        switch verdict {
        case .advance:
            print("")
        case .halt(let outcome):
            print("")
        case .stumbled(let hitch):
            print("")
        }
    }
}
