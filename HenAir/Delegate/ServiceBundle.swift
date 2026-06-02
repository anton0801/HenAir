import Foundation

final class ServiceBundle {
    let henhouse: Henhouse
    let crower: Crower
    let doorman: Doorman
    
    init(henhouse: Henhouse, crower: Crower, doorman: Doorman) {
        self.henhouse = henhouse
        self.crower = crower
        self.doorman = doorman
    }
    
    static func productionBundle() -> ServiceBundle {
        ServiceBundle(
            henhouse: JSONHenhouse(),
            crower: HTTPCrower(),
            doorman: NotificationDoorman()
        )
    }
}

@MainActor
final class Roosting {
    
    static let shared = Roosting()
    
    private var bundleInstance: ServiceBundle?
    private var hooksInstance: HookBundle?
    private var conveyorInstance: FlightConveyor?
    
    private init() {}
    
    func provideBundle() -> ServiceBundle {
        if let b = bundleInstance { return b }
        let inst = ServiceBundle.productionBundle()
        bundleInstance = inst
        return inst
    }
    
    func provideHooks() -> HookBundle {
        if let h = hooksInstance { return h }
        let inst = HookBundle()
        inst.attach(TraceHook())
        hooksInstance = inst
        return inst
    }
    
    func provideConveyor() -> FlightConveyor {
        if let c = conveyorInstance { return c }
        let inst = FlightConveyor(bundle: provideBundle(), hooks: provideHooks())
        conveyorInstance = inst
        return inst
    }
}
