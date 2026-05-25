import SwiftUI

// MARK: - Sensors View
struct SensorsView: View {
    let coop: Coop
    @EnvironmentObject var coopsVM: CoopsViewModel
    @EnvironmentObject var appState: AppState
    @State private var appeared = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                ForEach(coop.sensors) { sensor in
                    SensorCard(sensor: sensor)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)
                        .animation(.spring(response: 0.4, dampingFraction: 0.7).delay(Double(coop.sensors.firstIndex(where: { $0.id == sensor.id }) ?? 0) * 0.08), value: appeared)
                }
                Spacer().frame(height: 80)
            }
            .padding(16)
        }
        .background(Color.bgPrimary.ignoresSafeArea())
        .navigationTitle("Sensors")
        .onAppear { withAnimation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.1)) { appeared = true } }
    }
}

struct SensorCard: View {
    let sensor: Sensor
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 12).fill(Color.accentBlue.opacity(0.12)).frame(width: 44, height: 44)
                    Image(systemName: sensor.type == .climate ? "thermometer.medium" :
                          sensor.type == .ventilation ? "wind" :
                          sensor.type == .humidity ? "drop.fill" : "aqi.medium")
                        .font(.system(size: 18, weight: .semibold)).foregroundColor(Color.accentBlue)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(sensor.name).font(AppFont.display(14)).foregroundColor(Color.textPrimary)
                    Text(sensor.type.rawValue).font(AppFont.body(12)).foregroundColor(Color.textInactive)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    StatusDot(status: sensor.status)
                    Text(sensor.isOnline ? "Online" : "Offline")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(sensor.isOnline ? .accentGreen : .statusDanger)
                }
            }

            Divider().background(Color.divider1)

            HStack(spacing: 0) {
                if let t = sensor.temperature {
                    SensorMetric(icon: "thermometer.medium", value: appState.temperatureUnit.label(t), label: "Temperature", color: .accentBlue)
                }
                if let h = sensor.humidity {
                    Divider().frame(height: 40).background(Color.divider1)
                    SensorMetric(icon: "drop.fill", value: String(format: "%.0f%%", h), label: "Humidity", color: .humNormal)
                }
                if let v = sensor.ventilationSpeed {
                    Divider().frame(height: 40).background(Color.divider1)
                    SensorMetric(icon: "wind", value: String(format: "%.1f m/s", v), label: "Airflow", color: .accentGreenActive)
                }
            }

            // Battery
            HStack(spacing: 8) {
                Image(systemName: batteryIcon(sensor.batteryLevel)).font(.system(size: 14)).foregroundColor(batteryColor(sensor.batteryLevel))
                Text("Battery: \(Int(sensor.batteryLevel * 100))%").font(AppFont.body(12)).foregroundColor(Color.textSecondary)
                Spacer()
                Text("Updated: \(sensor.lastUpdated, style: .relative) ago").font(AppFont.body(11)).foregroundColor(Color.textInactive)
            }
        }
        .padding(16).cardStyle()
    }

    func batteryIcon(_ l: Double) -> String {
        if l > 0.75 { return "battery.100" }
        if l > 0.5 { return "battery.75" }
        if l > 0.25 { return "battery.25" }
        return "battery.0"
    }
    func batteryColor(_ l: Double) -> Color { l < 0.2 ? .statusDanger : l < 0.4 ? .statusWarning : .accentGreen }
}

struct SensorMetric: View {
    let icon: String; let value: String; let label: String; let color: Color
    var body: some View {
        VStack(spacing: 3) {
            Image(systemName: icon).font(.system(size: 13)).foregroundColor(color)
            Text(value).font(AppFont.display(13)).foregroundColor(Color.textPrimary)
            Text(label).font(.system(size: 9)).foregroundColor(Color.textInactive)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Manual Input View
struct ManualInputView: View {
    let coop: Coop
    @EnvironmentObject var coopsVM: CoopsViewModel
    @EnvironmentObject var appState: AppState
    @State private var temperature: Double = 20
    @State private var humidity: Double = 60
    @State private var ventilation: Double = 0.8
    @State private var saved = false
    @State private var appeared = false

    var tempColor: Color {
        if temperature < 10 { return .tempCold }
        if temperature < 15 { return .tempCool }
        if temperature < 25 { return .tempNormal }
        if temperature < 30 { return .tempWarm }
        return .tempHot
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // Temperature slider
                SliderCard(
                    title: "Temperature",
                    icon: "thermometer.medium",
                    value: $temperature,
                    range: -10...45,
                    step: 0.1,
                    displayValue: appState.temperatureUnit.label(temperature),
                    color: tempColor
                )
                .opacity(appeared ? 1 : 0).offset(y: appeared ? 0 : 20)

                // Humidity slider
                SliderCard(
                    title: "Humidity",
                    icon: "drop.fill",
                    value: $humidity,
                    range: 0...100,
                    step: 1,
                    displayValue: String(format: "%.0f%%", humidity),
                    color: humidity < 40 ? .humLow : humidity > 70 ? .humHigh : .humNormal
                )
                .opacity(appeared ? 1 : 0).offset(y: appeared ? 0 : 24)

                // Ventilation slider
                SliderCard(
                    title: "Ventilation Speed",
                    icon: "wind",
                    value: $ventilation,
                    range: 0...3,
                    step: 0.1,
                    displayValue: String(format: "%.1f m/s", ventilation),
                    color: .accentBlueActive
                )
                .opacity(appeared ? 1 : 0).offset(y: appeared ? 0 : 28)

                // Preview status
                VStack(alignment: .leading, spacing: 10) {
                    SectionHeader(title: "Preview Status", icon: "eye.fill")
                    HStack(spacing: 12) {
                        PreviewStatusItem(label: "Temperature", status: temperature < 5 || temperature > 32 ? .danger : temperature < 10 || temperature > 27 ? .warning : .normal)
                        PreviewStatusItem(label: "Humidity", status: humidity < 30 || humidity > 80 ? .danger : humidity < 40 || humidity > 70 ? .warning : .normal)
                        PreviewStatusItem(label: "Airflow", status: ventilation < 0.2 ? .warning : .normal)
                    }
                }
                .padding(16).cardStyle()
                .opacity(appeared ? 1 : 0)

                if saved {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill").foregroundColor(.accentGreen).font(.system(size: 20))
                        Text("Reading saved successfully!").font(AppFont.display(14)).foregroundColor(.accentGreen)
                    }
                    .padding(14)
                    .background(Color.accentGreen.opacity(0.1))
                    .cornerRadius(14)
                    .transition(.scale.combined(with: .opacity))
                }

                PrimaryButton(title: "Save Reading", icon: "checkmark.circle.fill") {
                    coopsVM.addManualReading(coopId: coop.id, temperature: temperature, humidity: humidity, ventilation: ventilation, appState: appState)
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { saved = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        withAnimation { saved = false }
                    }
                }
                .opacity(appeared ? 1 : 0)

                Spacer().frame(height: 80)
            }
            .padding(16)
        }
        .background(Color.bgPrimary.ignoresSafeArea())
        .navigationTitle("Manual Input")
        .onAppear { withAnimation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.1)) { appeared = true } }
    }
}

struct SliderCard: View {
    let title: String; let icon: String
    @Binding var value: Double
    let range: ClosedRange<Double>; let step: Double
    let displayValue: String; let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon).font(.system(size: 16, weight: .semibold)).foregroundColor(color)
                Text(title).font(AppFont.display(14)).foregroundColor(Color.textPrimary)
                Spacer()
                Text(displayValue)
                    .font(AppFont.display(18))
                    .foregroundColor(color)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: value)
            }
            Slider(value: $value, in: range, step: step)
                .tint(color)
        }
        .padding(16).cardStyle()
    }
}

struct PreviewStatusItem: View {
    let label: String; let status: ClimateStatus
    var body: some View {
        VStack(spacing: 4) {
            StatusDot(status: status)
            Text(label).font(.system(size: 10, weight: .medium)).foregroundColor(Color.textInactive).lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Ventilation View
struct VentilationView: View {
    let coop: Coop
    @EnvironmentObject var coopsVM: CoopsViewModel
    @State private var appeared = false

    var ventSensor: Sensor? { coop.sensors.first(where: { $0.type == .ventilation }) ?? coop.sensors.first }
    var speed: Double { ventSensor?.ventilationSpeed ?? 0 }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                // Big vent gauge
                VStack(spacing: 16) {
                    Text("Air Circulation").font(AppFont.body(13)).foregroundColor(Color.textSecondary)
                    ZStack {
                        Circle().stroke(Color.divider1, lineWidth: 16).frame(width: 180, height: 180)
                        Circle()
                            .trim(from: 0, to: appeared ? CGFloat(min(speed / 3.0, 1.0)) : 0)
                            .stroke(LinearGradient(colors: [.accentBlue, .accentGreen], startPoint: .leading, endPoint: .trailing),
                                    style: StrokeStyle(lineWidth: 16, lineCap: .round))
                            .frame(width: 180, height: 180).rotationEffect(.degrees(-90))
                        VStack(spacing: 4) {
                            Text(String(format: "%.1f", speed)).font(.system(size: 44, weight: .heavy, design: .rounded)).foregroundColor(Color.textPrimary)
                            Text("m/s").font(AppFont.body(14)).foregroundColor(Color.textSecondary)
                            Text(speed < 0.3 ? "⚠️ Poor" : speed > 2 ? "⚠️ Strong" : "✓ Good")
                                .font(.system(size: 12, weight: .bold)).foregroundColor(speed < 0.3 || speed > 2 ? .statusWarning : .accentGreen)
                        }
                    }
                }
                .padding(24).cardStyle()
                .opacity(appeared ? 1 : 0)

                // Ventilation levels
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Airflow Zones", icon: "wind")
                    VentZoneRow(label: "Stagnant", range: "< 0.3 m/s", status: .danger, active: speed < 0.3)
                    VentZoneRow(label: "Low", range: "0.3 – 0.5 m/s", status: .warning, active: speed >= 0.3 && speed < 0.5)
                    VentZoneRow(label: "Optimal", range: "0.5 – 1.5 m/s", status: .normal, active: speed >= 0.5 && speed <= 1.5)
                    VentZoneRow(label: "High", range: "1.5 – 2.5 m/s", status: .warning, active: speed > 1.5 && speed <= 2.5)
                    VentZoneRow(label: "Excessive", range: "> 2.5 m/s", status: .danger, active: speed > 2.5)
                }
                .padding(16).cardStyle()
                .opacity(appeared ? 1 : 0)

                // CO2 if available
                if let co2 = ventSensor?.co2 {
                    CO2Card(co2: co2)
                        .opacity(appeared ? 1 : 0)
                }

                Spacer().frame(height: 80)
            }
            .padding(16)
        }
        .background(Color.bgPrimary.ignoresSafeArea())
        .navigationTitle("Ventilation")
        .onAppear {
            withAnimation(.easeOut(duration: 1.0).delay(0.2)) { appeared = true }
        }
    }
}

struct VentZoneRow: View {
    let label: String; let range: String; let status: ClimateStatus; let active: Bool
    var color: Color { switch status { case .normal: return .accentGreen; case .warning: return .statusWarning; case .danger: return .statusDanger } }
    var body: some View {
        HStack(spacing: 10) {
            Circle().fill(active ? color : Color.divider2).frame(width: 8, height: 8)
            Text(label).font(AppFont.body(13, weight: active ? .semibold : .regular)).foregroundColor(active ? Color.textPrimary : Color.textInactive)
            Spacer()
            Text(range).font(AppFont.body(12)).foregroundColor(active ? color : Color.textInactive)
            if active { Image(systemName: "arrow.left").font(.system(size: 10)).foregroundColor(color) }
        }
    }
}

struct CO2Card: View {
    let co2: Double
    var status: ClimateStatus { co2 > 3000 ? .danger : co2 > 2000 ? .warning : .normal }
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(Color.birdYellow.opacity(0.12)).frame(width: 52, height: 52)
                Image(systemName: "aqi.medium").font(.system(size: 22)).foregroundColor(Color.birdYellow)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text("CO₂ Level").font(AppFont.display(14)).foregroundColor(Color.textPrimary)
                Text(status == .normal ? "Safe range" : "Elevated — ventilate").font(AppFont.body(12)).foregroundColor(Color.textSecondary)
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text(String(format: "%.0f", co2)).font(AppFont.display(20)).foregroundColor(Color.textPrimary)
                Text("ppm").font(AppFont.body(11)).foregroundColor(Color.textInactive)
            }
            StatusDot(status: status)
        }
        .padding(16).cardStyle()
    }
}

// MARK: - Risk Zones View
struct RiskZonesView: View {
    let coop: Coop
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                RiskZoneCard(title: "Too Cold", icon: "thermometer.low", threshold: "< 5°C", effect: "Hypothermia risk, severe drop in egg production", color: .tempCold, status: (coop.latestTemperature ?? 20) < 5 ? .danger : .normal)
                RiskZoneCard(title: "Cool Stress", icon: "thermometer.medium", threshold: "5 – 10°C", effect: "Reduced activity, lower feed conversion", color: .tempCool, status: (coop.latestTemperature ?? 20) < 10 ? .warning : .normal)
                RiskZoneCard(title: "Heat Stress", icon: "thermometer.high", threshold: "> 27°C", effect: "Panting, reduced water intake, lower production", color: .tempWarm, status: (coop.latestTemperature ?? 20) > 27 ? .warning : .normal)
                RiskZoneCard(title: "Danger Heat", icon: "flame.fill", threshold: "> 32°C", effect: "Heat stroke risk, mortality possible", color: .tempHot, status: (coop.latestTemperature ?? 20) > 32 ? .danger : .normal)
                RiskZoneCard(title: "High Humidity", icon: "humidity.fill", threshold: "> 80%", effect: "Respiratory disease, coccidiosis risk", color: .humHigh, status: (coop.latestHumidity ?? 60) > 80 ? .danger : (coop.latestHumidity ?? 60) > 70 ? .warning : .normal)
                RiskZoneCard(title: "Poor Ventilation", icon: "wind", threshold: "< 0.3 m/s", effect: "CO₂ buildup, ammonia accumulation", color: .statusWarning, status: (coop.sensors.first?.ventilationSpeed ?? 0.8) < 0.3 ? .warning : .normal)
                Spacer().frame(height: 80)
            }
            .padding(16)
        }
        .background(Color.bgPrimary.ignoresSafeArea())
        .navigationTitle("Risk Zones")
    }
}

struct RiskZoneCard: View {
    let title: String; let icon: String; let threshold: String; let effect: String; let color: Color; let status: ClimateStatus
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12).fill(color.opacity(0.12)).frame(width: 48, height: 48)
                Image(systemName: icon).font(.system(size: 20, weight: .semibold)).foregroundColor(color)
            }
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title).font(AppFont.display(14)).foregroundColor(Color.textPrimary)
                    if status != .normal { StatusDot(status: status) }
                }
                Text(threshold).font(.system(size: 11, weight: .bold)).foregroundColor(color)
                Text(effect).font(AppFont.body(12)).foregroundColor(Color.textSecondary).lineLimit(2)
            }
            Spacer()
        }
        .padding(14)
        .background(status != .normal ? color.opacity(0.06) : Color.cardWhite)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(status != .normal ? color.opacity(0.3) : Color.clear, lineWidth: 1))
        .appShadow(AppShadow.card)
    }
}

// MARK: - Recommendations View
struct RecommendationsView: View {
    let coop: Coop
    @EnvironmentObject var coopsVM: CoopsViewModel
    @State private var appeared = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                let recs = coopsVM.recommendations(for: coop)
                ForEach(recs) { rec in
                    RecommendationCard(rec: rec)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)
                        .animation(.spring(response: 0.4, dampingFraction: 0.7).delay(Double(recs.firstIndex(where: { $0.id == rec.id }) ?? 0) * 0.1), value: appeared)
                }
                Spacer().frame(height: 80)
            }
            .padding(16)
        }
        .background(Color.bgPrimary.ignoresSafeArea())
        .navigationTitle("Recommendations")
        .onAppear { withAnimation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.1)) { appeared = true } }
    }
}

struct RecommendationCard: View {
    let rec: Recommendation
    @State private var expanded = false

    var body: some View {
        Button(action: { withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { expanded.toggle() } }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle().fill(rec.color.opacity(0.15)).frame(width: 50, height: 50)
                        Image(systemName: rec.icon).font(.system(size: 22, weight: .semibold)).foregroundColor(rec.color)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(rec.title).font(AppFont.display(14)).foregroundColor(Color.textPrimary)
                        Text(rec.action).font(.system(size: 11, weight: .bold)).foregroundColor(rec.color)
                    }
                    Spacer()
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold)).foregroundColor(Color.textInactive)
                }
                if expanded {
                    Text(rec.description)
                        .font(AppFont.body(13)).foregroundColor(Color.textSecondary).lineSpacing(3)
                        .padding(.top, 4)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(16)
            .background(Color.cardWhite)
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(rec.color.opacity(0.2), lineWidth: 1))
            .appShadow(AppShadow.card)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
