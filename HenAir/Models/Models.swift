import Foundation
import SwiftUI

// MARK: - Climate Status
enum ClimateStatus: String, Codable {
    case normal, warning, danger
}

// MARK: - Coop Model
struct Coop: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var size: String // e.g. "Small", "Medium", "Large"
    var sizeM2: Double
    var sensors: [Sensor]
    var createdAt: Date = Date()

    var latestTemperature: Double? { sensors.compactMap(\.temperature).last }
    var latestHumidity: Double? { sensors.compactMap(\.humidity).last }

    var temperatureStatus: ClimateStatus {
        guard let t = latestTemperature else { return .normal }
        if t < 5 || t > 32 { return .danger }
        if t < 10 || t > 27 { return .warning }
        return .normal
    }
    var humidityStatus: ClimateStatus {
        guard let h = latestHumidity else { return .normal }
        if h < 30 || h > 80 { return .danger }
        if h < 40 || h > 70 { return .warning }
        return .normal
    }
    var overallStatus: ClimateStatus {
        if temperatureStatus == .danger || humidityStatus == .danger { return .danger }
        if temperatureStatus == .warning || humidityStatus == .warning { return .warning }
        return .normal
    }
}

// MARK: - Sensor
struct Sensor: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var type: SensorType
    var temperature: Double?
    var humidity: Double?
    var co2: Double?
    var ventilationSpeed: Double? // m/s
    var batteryLevel: Double // 0–1
    var isOnline: Bool
    var lastUpdated: Date

    var status: ClimateStatus {
        if !isOnline { return .warning }
        return .normal
    }
}

enum SensorType: String, Codable, CaseIterable {
    case climate = "Climate"
    case humidity = "Humidity"
    case ventilation = "Ventilation"
    case co2 = "CO₂"
}

// MARK: - Alert Model
struct ClimateAlert: Identifiable, Codable {
    var id: UUID = UUID()
    var coopName: String
    var type: AlertType
    var message: String
    var value: Double?
    var timestamp: Date
    var isRead: Bool = false
    var severity: ClimateStatus
}

enum AlertType: String, Codable {
    case tempHigh = "Too Hot"
    case tempLow = "Too Cold"
    case humidityHigh = "High Humidity"
    case humidityLow = "Low Humidity"
    case ventilation = "Poor Ventilation"
    case sensorOffline = "Sensor Offline"
}

// MARK: - History Entry
struct HistoryEntry: Identifiable, Codable {
    var id: UUID = UUID()
    var coopId: UUID
    var temperature: Double
    var humidity: Double
    var ventilationSpeed: Double
    var timestamp: Date
}

// MARK: - Task Model
struct CoopTask: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var notes: String
    var coopName: String
    var isCompleted: Bool = false
    var dueDate: Date
    var priority: TaskPriority
}

enum TaskPriority: String, Codable, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"

    var color: Color {
        switch self {
        case .low: return .statusOk
        case .medium: return .statusWarning
        case .high: return .statusDanger
        }
    }
}

// MARK: - Recommendation
struct Recommendation: Identifiable {
    var id: UUID = UUID()
    var icon: String
    var title: String
    var description: String
    var action: String
    var color: Color
    var priority: ClimateStatus
}

// MARK: - Report Data
struct ReportData: Identifiable, Codable {
    var id: UUID = UUID()
    var coopId: UUID
    var coopName: String
    var period: String
    var avgTemperature: Double
    var avgHumidity: Double
    var alertCount: Int
    var taskCompletedCount: Int
    var generatedAt: Date
}

// MARK: - User Profile
struct UserProfile: Codable {
    var name: String = "Farmer"
    var email: String = ""
    var farmName: String = ""
}

// MARK: - Temperature Unit
enum TemperatureUnit: String, CaseIterable {
    case celsius = "°C"
    case fahrenheit = "°F"

    func convert(_ celsius: Double) -> Double {
        switch self {
        case .celsius: return celsius
        case .fahrenheit: return celsius * 9/5 + 32
        }
    }
    func label(_ celsius: Double) -> String {
        String(format: "%.1f%@", convert(celsius), rawValue)
    }
}
