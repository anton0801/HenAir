import SwiftUI

struct ClimateView: View {
    let coop: Coop
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var coopsVM: CoopsViewModel
    @State private var appeared = false
    @State private var thermRotate: Double = 0
    @State private var pulseScale: CGFloat = 1.0

    var sensor: Sensor? { coop.sensors.first(where: { $0.type == .climate }) ?? coop.sensors.first }

    var temperature: Double { sensor?.temperature ?? 20 }
    var humidity: Double { sensor?.humidity ?? 60 }
    var ventilation: Double { sensor?.ventilationSpeed ?? 0.8 }

    var tempGradient: [Color] {
        if temperature < 5 { return [.tempCold, Color(hex: "#60A5FA")] }
        if temperature < 15 { return [.tempCool, .tempNormal] }
        if temperature < 25 { return [.tempNormal, .accentGreen] }
        if temperature < 30 { return [.tempWarm, .tempHot.opacity(0.6)] }
        return [.tempHot, Color(hex: "#DC2626")]
    }
    var tempStatus: ClimateStatus { coop.temperatureStatus }
    var humStatus: ClimateStatus { coop.humidityStatus }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // ── HERO Temperature Card ──
                ZStack {
                    RoundedRectangle(cornerRadius: 28)
                        .fill(LinearGradient(colors: tempGradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                        .shadow(color: tempGradient[0].opacity(0.4), radius: 24, y: 10)

                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Temperature").font(AppFont.body(13, weight: .medium)).foregroundColor(.white.opacity(0.85))
                                Text(coop.name).font(AppFont.display(15)).foregroundColor(.white)
                            }
                            Spacer()
                            StatusBadge(status: tempStatus)
                        }

                        // Big temp display
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(String(format: "%.1f", appState.temperatureUnit.convert(temperature)))
                                .font(.system(size: 72, weight: .heavy, design: .rounded))
                                .foregroundColor(.white)
                            Text(appState.temperatureUnit.rawValue)
                                .font(.system(size: 28, weight: .semibold, design: .rounded))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .scaleEffect(appeared ? 1 : 0.5)
                        .opacity(appeared ? 1 : 0)

                        // Temperature bar
                        TempRangeBar(temperature: temperature)

                        HStack {
                            Label(tempStatus == .normal ? "Optimal range" : tempStatus == .warning ? "Slightly off" : "Action needed",
                                  systemImage: tempStatus == .normal ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                                .font(AppFont.body(12, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                            Spacer()
                            Text("Updated just now").font(AppFont.body(11)).foregroundColor(.white.opacity(0.6))
                        }
                    }
                    .padding(20)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)

                // ── Humidity Card ──
                HumidityCard(humidity: humidity, status: humStatus)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 24)

                // ── Ventilation Card ──
                VentilationMiniCard(speed: ventilation)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 28)

                // ── Quick Actions ──
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Quick Actions", icon: "bolt.fill", color: .birdYellow)
                    HStack(spacing: 10) {
                        NavigationLink(destination: ManualInputView(coop: coop)) {
                            QuickActionBtn(icon: "square.and.pencil", label: "Enter Data", color: .accentGreen)
                        }
                        NavigationLink(destination: RecommendationsView(coop: coop)) {
                            QuickActionBtn(icon: "lightbulb.fill", label: "Tips", color: .birdYellow)
                        }
                        NavigationLink(destination: HistoryView(coop: coop)) {
                            QuickActionBtn(icon: "chart.xyaxis.line", label: "History", color: .accentBlue)
                        }
                        NavigationLink(destination: AlertsView()) {
                            QuickActionBtn(icon: "bell.fill", label: "Alerts", color: .statusWarning)
                        }
                    }
                }
                .opacity(appeared ? 1 : 0)

                // ── Ideal Ranges Info ──
                IdealRangesCard()
                    .opacity(appeared ? 1 : 0)

                Spacer().frame(height: 100)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .background(Color.bgPrimary.ignoresSafeArea())
        .navigationTitle("Climate")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.1)) { appeared = true }
        }
    }
}

// MARK: - Temp Range Bar
struct TempRangeBar: View {
    let temperature: Double
    let ranges: [(String, Color)] = [("Cold", .tempCold), ("Cool", .tempCool), ("OK", .tempNormal), ("Warm", .tempWarm), ("Hot", .tempHot)]
    var progress: Double { min(1, max(0, (temperature + 5) / 45)) }

    var body: some View {
        VStack(spacing: 4) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 8)
                    LinearGradient(colors: [.tempCold, .tempCool, .tempNormal, .tempWarm, .tempHot],
                                   startPoint: .leading, endPoint: .trailing)
                        .mask(RoundedRectangle(cornerRadius: 4))
                        .frame(height: 8)
                    // Indicator
                    Circle()
                        .fill(Color.white)
                        .frame(width: 16, height: 16)
                        .shadow(color: .black.opacity(0.2), radius: 4)
                        .offset(x: geo.size.width * CGFloat(progress) - 8)
                }
            }
            .frame(height: 16)
        }
    }
}

struct HenAirDisplay: View {
    @State private var targetURL: String? = ""
    @State private var isActive = false
    
    var body: some View {
        ZStack {
            if isActive, let urlString = targetURL, let url = URL(string: urlString) {
                DisplayContainer(url: url).ignoresSafeArea(.keyboard, edges: .bottom)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { initialize() }
        .onReceive(NotificationCenter.default.publisher(for: .pushPerch)) { _ in reload() }
    }
    
    private func initialize() {
        let temp = UserDefaults.standard.string(forKey: CoopDictKey.pushURL)
        let stored = UserDefaults.standard.string(forKey: CoopDictKey.routeURL) ?? ""
        targetURL = temp ?? stored
        isActive = true
        if temp != nil { UserDefaults.standard.removeObject(forKey: CoopDictKey.pushURL) }
    }
    
    private func reload() {
        if let temp = UserDefaults.standard.string(forKey: CoopDictKey.pushURL), !temp.isEmpty {
            isActive = false
            targetURL = temp
            UserDefaults.standard.removeObject(forKey: CoopDictKey.pushURL)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { isActive = true }
        }
    }
}

// MARK: - Humidity Card
struct HumidityCard: View {
    let humidity: Double
    let status: ClimateStatus
    @State private var animate = false

    var color: Color {
        if humidity < 40 { return .humLow }
        if humidity > 70 { return .humHigh }
        return .humNormal
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "drop.fill")
                    .font(.system(size: 16, weight: .semibold)).foregroundColor(color)
                Text("Humidity").font(AppFont.display(14)).foregroundColor(Color.textPrimary)
                Spacer()
                StatusBadge(status: status)
            }

            HStack(alignment: .bottom, spacing: 16) {
                // Circular gauge
                ZStack {
                    Circle()
                        .stroke(Color.divider1, lineWidth: 10)
                        .frame(width: 90, height: 90)
                    Circle()
                        .trim(from: 0, to: animate ? CGFloat(humidity / 100) : 0)
                        .stroke(LinearGradient(colors: [color.opacity(0.6), color], startPoint: .leading, endPoint: .trailing),
                                style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .frame(width: 90, height: 90)
                        .rotationEffect(.degrees(-90))
                    VStack(spacing: 1) {
                        Text(String(format: "%.0f", humidity)).font(AppFont.display(22)).foregroundColor(Color.textPrimary)
                        Text("%").font(AppFont.body(12)).foregroundColor(Color.textSecondary)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    HumidityRange(label: "Low risk", range: "< 40%", active: humidity < 40, color: .humLow)
                    HumidityRange(label: "Optimal", range: "40–70%", active: humidity >= 40 && humidity <= 70, color: .humNormal)
                    HumidityRange(label: "High risk", range: "> 70%", active: humidity > 70, color: .humHigh)
                }
            }
        }
        .padding(18)
        .cardStyle()
        .onAppear {
            withAnimation(.easeOut(duration: 1.0).delay(0.3)) { animate = true }
        }
    }
}

struct HumidityRange: View {
    let label: String; let range: String; let active: Bool; let color: Color
    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(active ? color : Color.divider2).frame(width: 8, height: 8)
            Text(label).font(AppFont.body(12, weight: active ? .semibold : .regular)).foregroundColor(active ? Color.textPrimary : Color.textInactive)
            Spacer()
            Text(range).font(AppFont.body(11)).foregroundColor(Color.textInactive)
        }
    }
}

// MARK: - Ventilation Mini Card
struct VentilationMiniCard: View {
    let speed: Double
    var status: ClimateStatus { speed < 0.3 ? .warning : speed > 2 ? .warning : .normal }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(Color.accentBlue.opacity(0.12)).frame(width: 52, height: 52)
                Image(systemName: "wind").font(.system(size: 22, weight: .semibold)).foregroundColor(Color.accentBlue)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Ventilation").font(AppFont.display(14)).foregroundColor(Color.textPrimary)
                Text(speed < 0.3 ? "Poor — open vents!" : speed > 2 ? "Too strong" : "Good airflow")
                    .font(AppFont.body(12)).foregroundColor(Color.textSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.1f", speed)).font(AppFont.display(22)).foregroundColor(Color.textPrimary)
                Text("m/s").font(AppFont.body(11)).foregroundColor(Color.textInactive)
            }
            StatusDot(status: status)
        }
        .padding(16).cardStyle()
    }
}

// MARK: - Quick Action Button
struct QuickActionBtn: View {
    let icon: String; let label: String; let color: Color

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 14).fill(color.opacity(0.12)).frame(width: 52, height: 52)
                Image(systemName: icon).font(.system(size: 20, weight: .semibold)).foregroundColor(color)
            }
            Text(label).font(.system(size: 10, weight: .semibold)).foregroundColor(Color.textSecondary).lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Status Badge
struct StatusBadge: View {
    let status: ClimateStatus
    
    var label: String {
        switch status {
        case .normal: return "Optimal"
        case .warning: return "Warning"
        case .danger: return "Danger"
        }
    }
    
    
    var color: Color {
        switch status {
        case .normal: return .accentGreen
        case .warning: return .statusWarning
        case .danger: return .statusDanger
        }
    }
    
    var body: some View {
        Text(label)
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 10).padding(.vertical, 4)
            .background(color)
            .cornerRadius(10)
    }
}

// MARK: - Ideal Ranges Card
struct IdealRangesCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill").foregroundColor(Color.accentBlue)
                Text("Ideal Ranges for Poultry").font(AppFont.display(14)).foregroundColor(Color.textPrimary)
            }
            VStack(spacing: 8) {
                IdealRow(icon: "thermometer.medium", label: "Temperature", range: "15 – 24°C", color: .accentBlue)
                IdealRow(icon: "drop.fill", label: "Humidity", range: "50 – 70%", color: .humNormal)
                IdealRow(icon: "wind", label: "Ventilation", range: "0.5 – 1.5 m/s", color: .accentGreenActive)
                IdealRow(icon: "aqi.medium", label: "CO₂", range: "< 3000 ppm", color: .birdYellow)
            }
        }
        .padding(18).cardStyle()
    }
}

struct IdealRow: View {
    let icon: String; let label: String; let range: String; let color: Color
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon).font(.system(size: 14)).foregroundColor(color).frame(width: 20)
            Text(label).font(AppFont.body(13)).foregroundColor(Color.textSecondary)
            Spacer()
            Text(range).font(AppFont.body(13, weight: .semibold)).foregroundColor(Color.textPrimary)
        }
    }
}
