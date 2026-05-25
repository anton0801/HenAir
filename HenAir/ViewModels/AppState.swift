import SwiftUI
import Combine
import UserNotifications

// MARK: - AppState (EnvironmentObject)
class AppState: ObservableObject {
    @AppStorage("colorScheme") var colorSchemeRaw: String = "system" {
        didSet { objectWillChange.send() }
    }
    @AppStorage("temperatureUnit") var temperatureUnitRaw: String = "°C" {
        didSet { objectWillChange.send() }
    }
    @AppStorage("notificationsEnabled") var notificationsEnabled: Bool = true {
        didSet {
            if notificationsEnabled { requestNotifications() }
            else { UNUserNotificationCenter.current().removeAllPendingNotificationRequests() }
            objectWillChange.send()
        }
    }
    @AppStorage("userName") var userName: String = "Farmer"
    @AppStorage("farmName") var farmName: String = ""
    @AppStorage("userEmail") var userEmail: String = ""
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false

    var colorScheme: ColorScheme? {
        switch colorSchemeRaw {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }
    var temperatureUnit: TemperatureUnit {
        TemperatureUnit(rawValue: temperatureUnitRaw) ?? .celsius
    }

    func requestNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                if !granted { self.notificationsEnabled = false }
            }
        }
    }

    func scheduleAlert(_ alert: ClimateAlert) {
        guard notificationsEnabled else { return }
        let content = UNMutableNotificationContent()
        content.title = "⚠️ \(alert.type.rawValue)"
        content.body = alert.message
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let req = UNNotificationRequest(identifier: alert.id.uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(req)
    }
}

// MARK: - Main ViewModel (Coops + Data)
class CoopsViewModel: ObservableObject {
    @Published var coops: [Coop] = []
    @Published var alerts: [ClimateAlert] = []
    @Published var historyEntries: [HistoryEntry] = []
    @Published var tasks: [CoopTask] = []
    @Published var reports: [ReportData] = []

    private let coopsKey = "coops_v1"
    private let alertsKey = "alerts_v1"
    private let historyKey = "history_v1"
    private let tasksKey = "tasks_v1"
    private let reportsKey = "reports_v1"
    private var timer: Timer?

    init() {
        load()
        if coops.isEmpty { seedDemo() }
        startSimulation()
    }

    deinit { timer?.invalidate() }

    // MARK: - Persistence
    func save() {
        if let d = try? JSONEncoder().encode(coops) { UserDefaults.standard.set(d, forKey: coopsKey) }
        if let d = try? JSONEncoder().encode(alerts) { UserDefaults.standard.set(d, forKey: alertsKey) }
        if let d = try? JSONEncoder().encode(historyEntries) { UserDefaults.standard.set(d, forKey: historyKey) }
        if let d = try? JSONEncoder().encode(tasks) { UserDefaults.standard.set(d, forKey: tasksKey) }
        if let d = try? JSONEncoder().encode(reports) { UserDefaults.standard.set(d, forKey: reportsKey) }
    }

    func load() {
        if let d = UserDefaults.standard.data(forKey: coopsKey), let v = try? JSONDecoder().decode([Coop].self, from: d) { coops = v }
        if let d = UserDefaults.standard.data(forKey: alertsKey), let v = try? JSONDecoder().decode([ClimateAlert].self, from: d) { alerts = v }
        if let d = UserDefaults.standard.data(forKey: historyKey), let v = try? JSONDecoder().decode([HistoryEntry].self, from: d) { historyEntries = v }
        if let d = UserDefaults.standard.data(forKey: tasksKey), let v = try? JSONDecoder().decode([CoopTask].self, from: d) { tasks = v }
        if let d = UserDefaults.standard.data(forKey: reportsKey), let v = try? JSONDecoder().decode([ReportData].self, from: d) { reports = v }
    }

    // MARK: - Demo Data
    func seedDemo() {
        let s1 = Sensor(name: "Main Sensor", type: .climate, temperature: 21.4, humidity: 62, co2: 850, ventilationSpeed: 0.8, batteryLevel: 0.87, isOnline: true, lastUpdated: Date())
        let s2 = Sensor(name: "Ventilation", type: .ventilation, temperature: nil, humidity: nil, co2: nil, ventilationSpeed: 1.2, batteryLevel: 0.6, isOnline: true, lastUpdated: Date())
        let coop1 = Coop(name: "Main Coop", size: "Large", sizeM2: 24, sensors: [s1, s2])

        let s3 = Sensor(name: "Climate A", type: .climate, temperature: 28.9, humidity: 74, co2: 1100, ventilationSpeed: 0.3, batteryLevel: 0.45, isOnline: true, lastUpdated: Date())
        let coop2 = Coop(name: "Layer House", size: "Medium", sizeM2: 16, sensors: [s3])

        let s4 = Sensor(name: "Temp Sensor", type: .humidity, temperature: 14.2, humidity: 55, co2: 700, ventilationSpeed: 0.9, batteryLevel: 0.95, isOnline: true, lastUpdated: Date())
        let coop3 = Coop(name: "Broiler Unit", size: "Small", sizeM2: 10, sensors: [s4])

        coops = [coop1, coop2, coop3]

        // Alerts
        let a1 = ClimateAlert(coopName: "Layer House", type: .tempHigh, message: "Temperature reached 28.9°C — ventilate immediately", value: 28.9, timestamp: Date().addingTimeInterval(-600), severity: .warning)
        let a2 = ClimateAlert(coopName: "Layer House", type: .humidityHigh, message: "Humidity at 74% — check ventilation system", value: 74, timestamp: Date().addingTimeInterval(-1800), severity: .warning)
        alerts = [a1, a2]

        // History (last 24h)
        historyEntries = (0..<24).map { i in
            HistoryEntry(coopId: coop1.id, temperature: 19 + Double.random(in: -2...4),
                         humidity: 58 + Double.random(in: -5...10),
                         ventilationSpeed: 0.7 + Double.random(in: -0.2...0.5),
                         timestamp: Date().addingTimeInterval(-Double(23 - i) * 3600))
        }

        // Tasks
        tasks = [
            CoopTask(title: "Ventilate Layer House", notes: "Open top vents for 30 min", coopName: "Layer House", isCompleted: false, dueDate: Date().addingTimeInterval(3600), priority: .high),
            CoopTask(title: "Check sensor battery", notes: "Climate A battery at 45%", coopName: "Layer House", isCompleted: false, dueDate: Date().addingTimeInterval(86400), priority: .medium),
            CoopTask(title: "Clean water lines", notes: "Monthly maintenance", coopName: "Main Coop", isCompleted: true, dueDate: Date().addingTimeInterval(-3600), priority: .low)
        ]

        // Reports
        reports = [
            ReportData(coopId: coop1.id, coopName: "Main Coop", period: "Last 7 days", avgTemperature: 21.2, avgHumidity: 61, alertCount: 0, taskCompletedCount: 3, generatedAt: Date()),
            ReportData(coopId: coop2.id, coopName: "Layer House", period: "Last 7 days", avgTemperature: 27.1, avgHumidity: 72, alertCount: 2, taskCompletedCount: 1, generatedAt: Date())
        ]

        save()
    }

    // MARK: - CRUD Coops
    func addCoop(_ coop: Coop) {
        coops.append(coop)
        save()
    }

    func deleteCoop(_ coop: Coop) {
        coops.removeAll { $0.id == coop.id }
        save()
    }

    func updateCoop(_ coop: Coop) {
        if let idx = coops.firstIndex(where: { $0.id == coop.id }) {
            coops[idx] = coop
            save()
        }
    }

    // MARK: - Manual Input
    func addManualReading(coopId: UUID, temperature: Double, humidity: Double, ventilation: Double, appState: AppState) {
        guard let idx = coops.firstIndex(where: { $0.id == coopId }) else { return }
        let sensorIdx = coops[idx].sensors.firstIndex(where: { $0.type == .climate }) ?? 0
        if coops[idx].sensors.indices.contains(sensorIdx) {
            coops[idx].sensors[sensorIdx].temperature = temperature
            coops[idx].sensors[sensorIdx].humidity = humidity
            coops[idx].sensors[sensorIdx].ventilationSpeed = ventilation
            coops[idx].sensors[sensorIdx].lastUpdated = Date()
        } else {
            let s = Sensor(name: "Manual", type: .climate, temperature: temperature, humidity: humidity, co2: nil, ventilationSpeed: ventilation, batteryLevel: 1.0, isOnline: true, lastUpdated: Date())
            coops[idx].sensors.append(s)
        }
        let entry = HistoryEntry(coopId: coopId, temperature: temperature, humidity: humidity, ventilationSpeed: ventilation, timestamp: Date())
        historyEntries.append(entry)
        checkAlerts(coopId: coopId, temperature: temperature, humidity: humidity, appState: appState)
        save()
    }

    // MARK: - Alerts
    func checkAlerts(coopId: UUID, temperature: Double, humidity: Double, appState: AppState) {
        guard let coop = coops.first(where: { $0.id == coopId }) else { return }
        if temperature > 27 {
            let a = ClimateAlert(coopName: coop.name, type: .tempHigh, message: "Temperature \(String(format: "%.1f", temperature))°C in \(coop.name)", value: temperature, timestamp: Date(), severity: temperature > 32 ? .danger : .warning)
            alerts.insert(a, at: 0)
            appState.scheduleAlert(a)
        } else if temperature < 10 {
            let a = ClimateAlert(coopName: coop.name, type: .tempLow, message: "Temperature \(String(format: "%.1f", temperature))°C — too cold in \(coop.name)", value: temperature, timestamp: Date(), severity: temperature < 5 ? .danger : .warning)
            alerts.insert(a, at: 0)
            appState.scheduleAlert(a)
        }
        if humidity > 70 {
            let a = ClimateAlert(coopName: coop.name, type: .humidityHigh, message: "Humidity \(String(format: "%.0f", humidity))% in \(coop.name)", value: humidity, timestamp: Date(), severity: humidity > 80 ? .danger : .warning)
            alerts.insert(a, at: 0)
            appState.scheduleAlert(a)
        }
        save()
    }

    func markAlertRead(_ alert: ClimateAlert) {
        if let i = alerts.firstIndex(where: { $0.id == alert.id }) {
            alerts[i].isRead = true
            save()
        }
    }

    func deleteAlert(_ alert: ClimateAlert) {
        alerts.removeAll { $0.id == alert.id }
        save()
    }

    func markAllAlertsRead() {
        for i in alerts.indices { alerts[i].isRead = true }
        save()
    }

    var unreadAlertCount: Int { alerts.filter { !$0.isRead }.count }

    // MARK: - Tasks
    func addTask(_ task: CoopTask) {
        tasks.insert(task, at: 0)
        save()
    }

    func toggleTask(_ task: CoopTask) {
        if let i = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[i].isCompleted.toggle()
            save()
        }
    }

    func deleteTask(_ task: CoopTask) {
        tasks.removeAll { $0.id == task.id }
        save()
    }

    // MARK: - Reports
    func generateReport(for coop: Coop) -> ReportData {
        let entries = historyEntries.filter { $0.coopId == coop.id }
        let avgTemp = entries.isEmpty ? coop.latestTemperature ?? 0 : entries.map(\.temperature).reduce(0,+) / Double(entries.count)
        let avgHum = entries.isEmpty ? coop.latestHumidity ?? 0 : entries.map(\.humidity).reduce(0,+) / Double(entries.count)
        let alertCount = alerts.filter { $0.coopName == coop.name }.count
        let tasksDone = tasks.filter { $0.coopName == coop.name && $0.isCompleted }.count
        let r = ReportData(coopId: coop.id, coopName: coop.name, period: "Last 7 days",
                           avgTemperature: avgTemp, avgHumidity: avgHum,
                           alertCount: alertCount, taskCompletedCount: tasksDone, generatedAt: Date())
        if let i = reports.firstIndex(where: { $0.coopId == coop.id }) { reports[i] = r }
        else { reports.append(r) }
        save()
        return r
    }

    // MARK: - History for coop
    func history(for coopId: UUID) -> [HistoryEntry] {
        historyEntries.filter { $0.coopId == coopId }.sorted { $0.timestamp < $1.timestamp }
    }

    // MARK: - Recommendations
    func recommendations(for coop: Coop) -> [Recommendation] {
        var recs: [Recommendation] = []
        if let t = coop.latestTemperature {
            if t > 27 {
                recs.append(Recommendation(icon: "wind", title: "Increase Ventilation", description: "Temperature is above optimal range. Open vents or increase fan speed.", action: "Open Vents", color: .accentBlue, priority: .warning))
            } else if t < 10 {
                recs.append(Recommendation(icon: "flame.fill", title: "Add Heating", description: "Temperature is too low. Birds need 15–24°C for optimal production.", action: "Check Heater", color: .tempWarm, priority: .warning))
            }
        }
        if let h = coop.latestHumidity {
            if h > 70 {
                recs.append(Recommendation(icon: "drop.triangle.fill", title: "Reduce Humidity", description: "High humidity can cause respiratory disease. Improve air circulation.", action: "Ventilate", color: .accentBlueActive, priority: h > 80 ? .danger : .warning))
            } else if h < 40 {
                recs.append(Recommendation(icon: "drop.fill", title: "Increase Moisture", description: "Air is too dry. Consider a misting system or water drinkers.", action: "Check Drinkers", color: .tempCold, priority: .warning))
            }
        }
        if recs.isEmpty {
            recs.append(Recommendation(icon: "checkmark.seal.fill", title: "All Conditions Optimal", description: "Climate is within ideal range for your flock. Keep monitoring!", action: "View Details", color: .accentGreen, priority: .normal))
        }
        return recs
    }

    // MARK: - Simulation (updates sensors periodically)
    func startSimulation() {
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.simulateUpdate()
        }
    }

    func simulateUpdate() {
        for i in coops.indices {
            for j in coops[i].sensors.indices {
                if var t = coops[i].sensors[j].temperature {
                    t += Double.random(in: -0.3...0.3)
                    coops[i].sensors[j].temperature = t
                }
                if var h = coops[i].sensors[j].humidity {
                    h += Double.random(in: -1...1)
                    h = max(20, min(100, h))
                    coops[i].sensors[j].humidity = h
                }
                coops[i].sensors[j].lastUpdated = Date()
            }
        }
        save()
    }
}
