import Foundation
import Combine

@MainActor
final class HenAirWatcher: ObservableObject {
    
    @Published var navigateToMain = false {
        didSet {
            if navigateToMain {
                deadlineTask?.cancel()
                cachedDataTask?.cancel()
                uiLocked = true
            }
        }
    }
    
    @Published var navigateToWeb = false {
        didSet {
            if navigateToWeb {
                deadlineTask?.cancel()
                cachedDataTask?.cancel()
                uiLocked = true
            }
        }
    }
    
    @Published var showPermissionPrompt = false
    @Published var showOfflineView = false
    
    private let conveyor: FlightConveyor
    private var cancellables = Set<AnyCancellable>()
    private var deadlineTask: Task<Void, Never>?
    private var cachedDataTask: Task<Void, Never>?
    private var attObserver: NSObjectProtocol?
    
    private var uiLocked = false
    private var adjustAttributionReceived = false
    
    init() {
        self.conveyor = Roosting.shared.provideConveyor()
        wireUp()
    }
    
    deinit {
        deadlineTask?.cancel()
        cachedDataTask?.cancel()
        if let obs = attObserver {
            NotificationCenter.default.removeObserver(obs)
        }
    }
    
    private func wireUp() {
        conveyor.outcomePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] outcome in
                self?.handleOutcome(outcome)
            }
            .store(in: &cancellables)
    }
    
    func ignite() {
        conveyor.hatchCoop()
        armDeadline()
        
        // Таймер стартует только после ATT ответа
        attObserver = NotificationCenter.default.addObserver(
            forName: .init("ATTConsentDone"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self, !self.uiLocked else { return }
            self.armCachedDataFallback()
        }
    }
    
    func ingestAttribution(_ data: [String: Any]) {
        adjustAttributionReceived = true
        cachedDataTask?.cancel()
        cachedDataTask = nil
        
        Task {
            conveyor.absorbPecks(data)
            await conveyor.runFlight()
        }
    }
    
    func ingestDeeplinks(_ data: [String: Any]) {
        conveyor.absorbCrows(data)
    }
    
    func acceptConsent() {
        conveyor.approveConsent {
            self.showPermissionPrompt = false
        }
    }
    
    func skipConsent() {
        showPermissionPrompt = false
        conveyor.deferConsent()
    }
    
    func networkConnectivityChanged(_ connected: Bool) {
        showOfflineView = !connected
    }
    
    private func handleOutcome(_ outcome: FlightOutcome) {
        guard !uiLocked else { return }
        
        switch outcome {
        case .hovering:       break
        case .askConsent:     showPermissionPrompt = true
        case .openDisplay:    navigateToWeb = true
        case .grounded:       navigateToMain = true
        }
    }
    
    private func armCachedDataFallback() {
        guard !adjustAttributionReceived else {
            return
        }
        
        // Проверяем есть ли сохранённые pecks
        let bundle = Roosting.shared.provideBundle()
        let archive = bundle.henhouse.unroost()
        guard !archive.pecks.isEmpty else {
            return
        }
        
        cachedDataTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            
            guard let self else { return }
            guard !Task.isCancelled else { return }
            guard !self.uiLocked else { return }
            guard !self.adjustAttributionReceived else { return }
            
            let cached = archive.pecks
            
            NotificationCenter.default.post(
                name: .attributionRoost,
                object: nil,
                userInfo: ["conversionData": cached]
            )
        }
    }
    
    // MARK: - Deadline
    
    private func armDeadline() {
        deadlineTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 30_000_000_000)
            guard let self else { return }
            let shouldFire = self.conveyor.reportClockExpired()
            if shouldFire { self.handleOutcome(.grounded) }
        }
    }
}
