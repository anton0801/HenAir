import Foundation
import Combine

@MainActor
final class FlightConveyor {
    
    private var coop: CoopMain = CoopMain()
    private var hatched: Bool = false
    
    let ticket = FlightTicket()
    
    private let bundle: ServiceBundle
    private let hooks: HookBundle
    
    private let outcomeSubject = PassthroughSubject<FlightOutcome, Never>()
    var outcomePublisher: AnyPublisher<FlightOutcome, Never> {
        outcomeSubject.eraseToAnyPublisher()
    }
    
    private var consentTask: Task<Void, Never>?
    
    init(bundle: ServiceBundle, hooks: HookBundle) {
        self.bundle = bundle
        self.hooks = hooks
    }
    
    private func ensureHatched() {
        guard !hatched else { return }
        let archive = bundle.henhouse.unroost()
        coop = CoopMain.revive(from: archive)
        hatched = true
    }
    
    func hatchCoop() {
        ensureHatched()
    }
    
    func absorbPecks(_ raw: [String: Any]) {
        ensureHatched()
        let mapped = raw.mapValues { "\($0)" }
        coop.pecks = mapped
        bundle.henhouse.roost(coop.crystallize())
    }
    
    func absorbCrows(_ raw: [String: Any]) {
        ensureHatched()
        let mapped = raw.mapValues { "\($0)" }
        coop.crows = mapped
        bundle.henhouse.roost(coop.crystallize())
    }
    
    func runFlight() async {
        ensureHatched()
        guard !ticket.isStamped else { return }
        
        // OrganicFlapStage убран — Adjust не поддерживает такой API
        let stages: [FlightStage] = [
            PushSnatchStage(),
            PecksReadyStage(),
            BarnCrowingStage()
        ]
        
        let context = PipelineContext(coop: coop, bundle: bundle)
        
        for stage in stages {
            if ticket.isStamped {
                coop = context.coop
                return
            }
            
            hooks.fireStageEnter(stage.stageID)
            let verdict = await stage.process(context: context)
            hooks.fireStageVerdict(stage.stageID, verdict: verdict)
            
            switch verdict {
            case .advance:
                continue
            case .halt(let outcome):
                coop = context.coop
                if case .hovering = outcome {
                    outcomeSubject.send(.hovering)
                    return
                }
                if ticket.tryStamp() {
                    outcomeSubject.send(outcome)
                }
                return
            case .stumbled:
                coop = context.coop
                if ticket.tryStamp() {
                    outcomeSubject.send(.grounded)
                }
                return
            }
        }
        
        coop = context.coop
    }
    
    func approveConsent() {
        ensureHatched()
        consentTask = Task { [weak self] in
            guard let self = self else { return }
            
            let granted = await self.bundle.doorman.openDoor()
            let now = Date()
            
            self.coop.consentNested = granted
            self.coop.consentScattered = !granted
            self.coop.consentMarkedAt = now
            
            self.bundle.henhouse.roost(self.coop.crystallize())
            
            if granted { self.bundle.doorman.raiseFlagPush() }
            
            self.outcomeSubject.send(.openDisplay)
        }
    }
    
    func deferConsent() {
        ensureHatched()
        let now = Date()
        coop.consentMarkedAt = now
        bundle.henhouse.roost(coop.crystallize())
        outcomeSubject.send(.openDisplay)
    }
    
    func reportClockExpired() -> Bool {
        return ticket.tryStamp()
    }
}
