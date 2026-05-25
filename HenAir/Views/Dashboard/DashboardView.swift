import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var coopsVM: CoopsViewModel
    @State private var appeared = false
    @State private var showNotifications = false

    var overallStatus: ClimateStatus {
        if coopsVM.coops.contains(where: { $0.overallStatus == .danger }) { return .danger }
        if coopsVM.coops.contains(where: { $0.overallStatus == .warning }) { return .warning }
        return .normal
    }

    var avgTemp: Double? {
        let temps = coopsVM.coops.compactMap(\.latestTemperature)
        guard !temps.isEmpty else { return nil }
        return temps.reduce(0, +) / Double(temps.count)
    }
    var avgHum: Double? {
        let hums = coopsVM.coops.compactMap(\.latestHumidity)
        guard !hums.isEmpty else { return nil }
        return hums.reduce(0, +) / Double(hums.count)
    }

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Header banner
                    StatusBanner(status: overallStatus, coopCount: coopsVM.coops.count)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)

                    // Main metrics row
                    HStack(spacing: 12) {
                        if let t = avgTemp {
                            MetricCard(
                                title: "Avg Temperature",
                                value: appState.temperatureUnit.label(t).replacingOccurrences(of: appState.temperatureUnit.rawValue, with: ""),
                                unit: appState.temperatureUnit.rawValue,
                                icon: "thermometer.medium",
                                color: tempColor(t),
                                status: coopsVM.coops.map(\.temperatureStatus).worstStatus
                            )
                        }
                        if let h = avgHum {
                            MetricCard(
                                title: "Avg Humidity",
                                value: String(format: "%.0f", h),
                                unit: "%",
                                icon: "drop.fill",
                                color: humColor(h),
                                status: coopsVM.coops.map(\.humidityStatus).worstStatus
                            )
                        }
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 24)

                    // Coops quick status
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "Coops Overview", icon: "square.grid.2x2.fill")
                        ForEach(coopsVM.coops) { coop in
                            NavigationLink(destination: ClimateView(coop: coop)) {
                                CoopQuickRow(coop: coop)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 30)

                    // Recent alerts
                    if !coopsVM.alerts.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "Recent Alerts", icon: "exclamationmark.triangle.fill", color: .statusWarning)
                            ForEach(coopsVM.alerts.prefix(3)) { alert in
                                AlertRow(alert: alert) {
                                    coopsVM.markAlertRead(alert)
                                }
                            }
                        }
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 36)
                    }

                    // Pending tasks
                    let pendingTasks = coopsVM.tasks.filter { !$0.isCompleted }
                    if !pendingTasks.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "Pending Tasks", icon: "checkmark.circle.fill", color: .accentGreen)
                            ForEach(pendingTasks.prefix(3)) { task in
                                TaskQuickRow(task: task) {
                                    coopsVM.toggleTask(task)
                                }
                            }
                        }
                        .opacity(appeared ? 1 : 0)
                    }

                    Spacer().frame(height: 100)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .background(Color.bgPrimary.ignoresSafeArea())
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showNotifications = true }) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "bell.fill")
                                .foregroundColor(Color.textPrimary)
                            if coopsVM.unreadAlertCount > 0 {
                                Circle().fill(Color.statusDanger).frame(width: 8, height: 8).offset(x: 4, y: -2)
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showNotifications) {
                NotificationsView()
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.1)) { appeared = true }
        }
    }

    func tempColor(_ t: Double) -> Color {
        if t < 5 { return .tempCold }
        if t < 15 { return .tempCool }
        if t < 25 { return .tempNormal }
        if t < 30 { return .tempWarm }
        return .tempHot
    }
    func humColor(_ h: Double) -> Color {
        if h < 40 { return .humLow }
        if h > 70 { return .humHigh }
        return .humNormal
    }
}

// MARK: - Status Banner
struct StatusBanner: View {
    let status: ClimateStatus
    let coopCount: Int
    @State private var shimmer = false
    
    var icon: String {
        switch status {
        case .normal:   return "checkmark.shield.fill"
        case .warning:  return "exclamationmark.triangle.fill"
        case .danger:   return "xmark.shield.fill"
        }
    }
    
    var title: String {
        switch status {
        case .normal:   return "All coops optimal"
        case .warning:  return "Attention needed"
        case .danger:   return "Danger conditions!"
        }
    }
    
    var color: Color {
        switch status {
        case .normal:   return .accentGreen
        case .warning:  return .statusWarning
        case .danger:   return .statusDanger
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(.white)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(AppFont.display(16)).foregroundColor(.white)
                Text("\(coopCount) coop\(coopCount == 1 ? "" : "s") monitored")
                    .font(AppFont.body(12)).foregroundColor(.white.opacity(0.8))
            }
            Spacer()
            Image(systemName: "arrow.right.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(18)
        .background(
            LinearGradient(colors: [color, color.opacity(0.7)],
                           startPoint: .leading, endPoint: .trailing)
        )
        .cornerRadius(20)
        .appShadow(Shadow(color: color.opacity(0.3), radius: 16, x: 0, y: 6))
    }
}

// MARK: - Coop Quick Row
struct CoopQuickRow: View {
    let coop: Coop
    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(coop.overallStatus == .normal ? Color.accentGreen.opacity(0.12) : Color.statusWarning.opacity(0.12))
                    .frame(width: 44, height: 44)
                Text("🐔").font(.system(size: 20))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(coop.name).font(AppFont.display(14)).foregroundColor(Color.textPrimary)
                Text(coop.size + " · \(coop.sensors.count) sensor\(coop.sensors.count == 1 ? "" : "s")")
                    .font(AppFont.body(12)).foregroundColor(Color.textInactive)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if let t = coop.latestTemperature {
                    Text(appState.temperatureUnit.label(t))
                        .font(AppFont.display(14))
                        .foregroundColor(Color.textPrimary)
                }
                if let h = coop.latestHumidity {
                    Text(String(format: "%.0f%%", h))
                        .font(AppFont.body(12))
                        .foregroundColor(Color.textSecondary)
                }
            }

            StatusDot(status: coop.overallStatus)
        }
        .padding(14)
        .cardStyle()
    }
}

// MARK: - Alert Row
struct AlertRow: View {
    let alert: ClimateAlert
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: alert.severity == .danger ? "xmark.circle.fill" : "exclamationmark.triangle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(alert.severity == .danger ? .statusDanger : .statusWarning)
                    .frame(width: 36)

                VStack(alignment: .leading, spacing: 3) {
                    Text(alert.type.rawValue).font(AppFont.display(13)).foregroundColor(Color.textPrimary)
                    Text(alert.message).font(AppFont.body(12)).foregroundColor(Color.textSecondary).lineLimit(2)
                    Text(alert.timestamp, style: .relative)
                        .font(AppFont.body(11)).foregroundColor(Color.textInactive) + Text(" ago")
                        .font(AppFont.body(11)).foregroundColor(Color.textInactive)
                }
                Spacer()
                if !alert.isRead {
                    Circle().fill(Color.accentBlue).frame(width: 8, height: 8)
                }
            }
            .padding(14)
            .background(alert.isRead ? Color.cardWhite : Color(hex: "#ECFEFF"))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(alert.severity == .danger ? Color.statusDanger.opacity(0.2) : Color.statusWarning.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Task Quick Row
struct TaskQuickRow: View {
    let task: CoopTask
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(task.isCompleted ? .accentGreen : .divider2)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(task.title).font(AppFont.display(13)).foregroundColor(Color.textPrimary)
                    .strikethrough(task.isCompleted, color: .textInactive)
                Text(task.coopName).font(AppFont.body(12)).foregroundColor(Color.textInactive)
            }
            Spacer()
            PriorityBadge(priority: task.priority)
        }
        .padding(14)
        .cardStyle()
    }
}

// MARK: - Priority Badge
struct PriorityBadge: View {
    let priority: TaskPriority
    var body: some View {
        Text(priority.rawValue)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(priority.color)
            .cornerRadius(8)
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    let title: String
    let icon: String
    var color: Color = .accentGreen

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon).font(.system(size: 14, weight: .semibold)).foregroundColor(color)
            Text(title).font(AppFont.display(15)).foregroundColor(Color.textPrimary)
        }
    }
}

// MARK: - Array extension for status
extension Array where Element == ClimateStatus {
    var worstStatus: ClimateStatus {
        if contains(.danger) { return .danger }
        if contains(.warning) { return .warning }
        return .normal
    }
}
