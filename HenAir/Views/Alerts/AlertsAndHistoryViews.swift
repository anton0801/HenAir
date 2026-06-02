import SwiftUI
import WebKit

// MARK: - Alerts View (main tab)
struct AlertsView: View {
    @EnvironmentObject var coopsVM: CoopsViewModel
    @State private var appeared = false
    @State private var filter: AlertFilter = .all

    enum AlertFilter: String, CaseIterable {
        case all = "All"; case unread = "Unread"; case danger = "Danger"; case warning = "Warning"
    }

    var filtered: [ClimateAlert] {
        switch filter {
        case .all: return coopsVM.alerts
        case .unread: return coopsVM.alerts.filter { !$0.isRead }
        case .danger: return coopsVM.alerts.filter { $0.severity == .danger }
        case .warning: return coopsVM.alerts.filter { $0.severity == .warning }
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filter chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(AlertFilter.allCases, id: \.self) { f in
                            Button(action: { withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { filter = f } }) {
                                Text(f.rawValue)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(filter == f ? .white : Color.textSecondary)
                                    .padding(.horizontal, 14).padding(.vertical, 8)
                                    .background(filter == f ? Color.accentGreen : Color.white)
                                    .cornerRadius(20)
                                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.divider1, lineWidth: 1))
                            }
                        }
                    }
                    .padding(.horizontal, 16).padding(.vertical, 12)
                }

                if filtered.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "bell.slash.fill").font(.system(size: 44)).foregroundColor(Color.divider2)
                        Text("No alerts").font(AppFont.display(16)).foregroundColor(Color.textSecondary)
                        Text("Your coops are all clear").font(AppFont.body(13)).foregroundColor(Color.textInactive)
                    }
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 10) {
                            ForEach(filtered) { alert in
                                AlertRow(alert: alert) {
                                    coopsVM.markAlertRead(alert)
                                }
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        withAnimation { coopsVM.deleteAlert(alert) }
                                    } label: { Label("Delete", systemImage: "trash") }
                                    Button {
                                        coopsVM.markAlertRead(alert)
                                    } label: { Label("Mark Read", systemImage: "checkmark") }
                                    .tint(Color.accentBlueActive)
                                }
                                .opacity(appeared ? 1 : 0)
                                .offset(x: appeared ? 0 : 30)
                                .animation(.spring(response: 0.4, dampingFraction: 0.7).delay(Double(coopsVM.alerts.firstIndex(where: { $0.id == alert.id }) ?? 0) * 0.05), value: appeared)
                            }
                            Spacer().frame(height: 100)
                        }
                        .padding(.horizontal, 16)
                    }
                }
            }
            .background(Color.bgPrimary.ignoresSafeArea())
            .navigationTitle("Alerts")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if coopsVM.unreadAlertCount > 0 {
                        Button("Mark All Read") {
                            withAnimation { coopsVM.markAllAlertsRead() }
                        }
                        .font(AppFont.body(13)).foregroundColor(Color.accentGreen)
                    }
                }
            }
        }
        .onAppear { withAnimation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.1)) { appeared = true } }
    }
}

final class DisplayCoordinator: NSObject {
    weak var webView: WKWebView?
    private var redirectCount = 0, maxRedirects = 70
    private var lastURL: URL?, checkpoint: URL?
    private var popups: [WKWebView] = []
    private let cookieJar = CoopLingo.cookiePerches
    
    func loadURL(_ url: URL, in webView: WKWebView) {
        redirectCount = 0
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        webView.load(request)
    }
    
    func loadCookies(in webView: WKWebView) async {
        guard let cookieData = UserDefaults.standard.object(forKey: cookieJar) as? [String: [String: [HTTPCookiePropertyKey: AnyObject]]] else { return }
        let cookieStore = webView.configuration.websiteDataStore.httpCookieStore
        let cookies = cookieData.values.flatMap { $0.values }.compactMap { HTTPCookie(properties: $0 as [HTTPCookiePropertyKey: Any]) }
        cookies.forEach { cookieStore.setCookie($0) }
    }
    
    private func saveCookies(from webView: WKWebView) {
        webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { [weak self] cookies in
            guard let self = self else { return }
            var cookieData: [String: [String: [HTTPCookiePropertyKey: Any]]] = [:]
            for cookie in cookies {
                var domainCookies = cookieData[cookie.domain] ?? [:]
                if let properties = cookie.properties { domainCookies[cookie.name] = properties }
                cookieData[cookie.domain] = domainCookies
            }
            UserDefaults.standard.set(cookieData, forKey: self.cookieJar)
        }
    }
}

// MARK: - Notifications View
struct NotificationsView: View {
    @EnvironmentObject var coopsVM: CoopsViewModel
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 10) {
                    if coopsVM.alerts.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "bell.slash.fill").font(.system(size: 44)).foregroundColor(Color.divider2)
                            Text("No notifications").font(AppFont.display(16)).foregroundColor(Color.textSecondary)
                        }.padding(.top, 60)
                    } else {
                        ForEach(coopsVM.alerts) { alert in
                            AlertRow(alert: alert) { coopsVM.markAlertRead(alert) }
                        }
                    }
                    Spacer().frame(height: 60)
                }
                .padding(16)
            }
            .background(Color.bgPrimary.ignoresSafeArea())
            .navigationTitle("Notifications")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }.foregroundColor(Color.accentGreen)
                }
            }
        }
    }
}

extension DisplayCoordinator: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else { return decisionHandler(.allow) }
        lastURL = url
        let scheme = (url.scheme ?? "").lowercased()
        let path = url.absoluteString.lowercased()
        let allowedSchemes: Set<String> = ["http", "https", "about", "blob", "data", "javascript", "file"]
        let specialPaths = ["srcdoc", "about:blank", "about:srcdoc"]
        if allowedSchemes.contains(scheme) || specialPaths.contains(where: { path.hasPrefix($0) }) || path == "about:blank" {
            decisionHandler(.allow)
        } else {
            UIApplication.shared.open(url, options: [:])
            decisionHandler(.cancel)
        }
    }
    
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        redirectCount += 1
        if redirectCount > maxRedirects { webView.stopLoading(); if let recovery = lastURL { webView.load(URLRequest(url: recovery)) }; redirectCount = 0; return }
        lastURL = webView.url; saveCookies(from: webView)
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        if let current = webView.url { checkpoint = current }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let current = webView.url { checkpoint = current }; redirectCount = 0; saveCookies(from: webView)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        if (error as NSError).code == NSURLErrorHTTPTooManyRedirects, let recovery = lastURL { webView.load(URLRequest(url: recovery)) }
    }
    
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust, let trust = challenge.protectionSpace.serverTrust {
            completionHandler(.useCredential, URLCredential(trust: trust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}

// MARK: - History View
struct HistoryView: View {
    let coop: Coop
    @EnvironmentObject var coopsVM: CoopsViewModel
    @EnvironmentObject var appState: AppState
    @State private var appeared = false
    @State private var selectedMetric: HistoryMetric = .temperature

    enum HistoryMetric: String, CaseIterable {
        case temperature = "Temperature"; case humidity = "Humidity"; case ventilation = "Ventilation"
    }

    var entries: [HistoryEntry] { coopsVM.history(for: coop.id) }

    var chartValues: [Double] {
        switch selectedMetric {
        case .temperature: return entries.map { appState.temperatureUnit.convert($0.temperature) }
        case .humidity: return entries.map(\.humidity)
        case .ventilation: return entries.map(\.ventilationSpeed)
        }
    }

    var chartColor: Color {
        switch selectedMetric {
        case .temperature: return .accentBlue
        case .humidity: return .humNormal
        case .ventilation: return .accentGreenActive
        }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                // Metric selector
                HStack(spacing: 8) {
                    ForEach(HistoryMetric.allCases, id: \.self) { m in
                        Button(action: { withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { selectedMetric = m } }) {
                            Text(m.rawValue)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(selectedMetric == m ? .white : Color.textSecondary)
                                .padding(.horizontal, 12).padding(.vertical, 7)
                                .background(selectedMetric == m ? chartColor : Color.white)
                                .cornerRadius(10)
                        }
                    }
                }
                .padding(4).background(Color.white).cornerRadius(14)
                .opacity(appeared ? 1 : 0)

                // Chart
                if !chartValues.isEmpty {
                    LineChartView(values: chartValues, color: chartColor, unit: selectedMetric == .temperature ? appState.temperatureUnit.rawValue : selectedMetric == .humidity ? "%" : "m/s")
                        .frame(height: 180)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)
                }

                // Stats summary
                if !entries.isEmpty {
                    StatsSummaryCard(entries: entries, metric: selectedMetric, unit: appState.temperatureUnit)
                        .opacity(appeared ? 1 : 0)
                }

                // Navigation to Timeline
                NavigationLink(destination: TimelineView(coop: coop)) {
                    DetailNavRow(icon: "timeline.selection", title: "View Timeline", subtitle: "Changes over time", color: .accentBlueActive)
                }

                // List of recent entries
                VStack(alignment: .leading, spacing: 10) {
                    SectionHeader(title: "Recent Readings", icon: "list.bullet")
                    ForEach(entries.reversed().prefix(10)) { entry in
                        HistoryEntryRow(entry: entry, unit: appState.temperatureUnit)
                    }
                }
                .opacity(appeared ? 1 : 0)

                Spacer().frame(height: 80)
            }
            .padding(16)
        }
        .background(Color.bgPrimary.ignoresSafeArea())
        .navigationTitle("History")
        .onAppear { withAnimation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.1)) { appeared = true } }
    }
}

extension DisplayCoordinator: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        guard navigationAction.targetFrame == nil else { return nil }
        let popup = WKWebView(frame: webView.bounds, configuration: configuration)
        popup.navigationDelegate = self; popup.uiDelegate = self; popup.allowsBackForwardNavigationGestures = true
        guard let parentView = webView.superview else { return nil }
        parentView.addSubview(popup); popup.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([popup.topAnchor.constraint(equalTo: webView.topAnchor), popup.bottomAnchor.constraint(equalTo: webView.bottomAnchor), popup.leadingAnchor.constraint(equalTo: webView.leadingAnchor), popup.trailingAnchor.constraint(equalTo: webView.trailingAnchor)])
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(handlePopupPan(_:))); gesture.delegate = self
        popup.scrollView.panGestureRecognizer.require(toFail: gesture); popup.addGestureRecognizer(gesture); popups.append(popup)
        if let url = navigationAction.request.url, url.absoluteString != "about:blank" { popup.load(navigationAction.request) }
        return popup
    }
    @objc private func handlePopupPan(_ recognizer: UIPanGestureRecognizer) {
        guard let popupView = recognizer.view else { return }
        let translation = recognizer.translation(in: popupView), velocity = recognizer.velocity(in: popupView)
        switch recognizer.state {
        case .changed: if translation.x > 0 { popupView.transform = CGAffineTransform(translationX: translation.x, y: 0) }
        case .ended, .cancelled:
            let shouldClose = translation.x > popupView.bounds.width * 0.4 || velocity.x > 800
            if shouldClose { UIView.animate(withDuration: 0.25, animations: { popupView.transform = CGAffineTransform(translationX: popupView.bounds.width, y: 0) }) { [weak self] _ in self?.dismissTopPopup() }
            } else { UIView.animate(withDuration: 0.2) { popupView.transform = .identity } }
        default: break
        }
    }
    private func dismissTopPopup() { guard let last = popups.last else { return }; last.removeFromSuperview(); popups.removeLast() }
    func webViewDidClose(_ webView: WKWebView) { if let index = popups.firstIndex(of: webView) { webView.removeFromSuperview(); popups.remove(at: index) } }
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) { completionHandler() }
}

struct LineChartView: View {
    let values: [Double]; let color: Color; let unit: String
    @State private var progress: CGFloat = 0

    var minVal: Double { values.min() ?? 0 }
    var maxVal: Double { (values.max() ?? 1) == minVal ? minVal + 1 : values.max()! }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Chart").font(AppFont.display(13)).foregroundColor(Color.textPrimary)
                Spacer()
                Text("\(String(format: "%.1f", values.last ?? 0)) \(unit)")
                    .font(AppFont.display(13)).foregroundColor(color)
            }
            GeometryReader { geo in
                ZStack {
                    // Grid lines
                    ForEach(0..<4) { i in
                        let y = geo.size.height * CGFloat(i) / 3
                        Path { p in p.move(to: CGPoint(x: 0, y: y)); p.addLine(to: CGPoint(x: geo.size.width, y: y)) }
                            .stroke(Color.divider1, lineWidth: 0.5)
                    }
                    // Line
                    if values.count > 1 {
                        Path { path in
                            let step = geo.size.width / CGFloat(values.count - 1)
                            for (i, v) in values.enumerated() {
                                let x = CGFloat(i) * step
                                let y = geo.size.height * (1 - CGFloat((v - minVal) / (maxVal - minVal)))
                                if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                                else { path.addLine(to: CGPoint(x: x, y: y)) }
                            }
                        }
                        .trim(from: 0, to: progress)
                        .stroke(color, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))

                        // Fill
                        Path { path in
                            let step = geo.size.width / CGFloat(values.count - 1)
                            path.move(to: CGPoint(x: 0, y: geo.size.height))
                            for (i, v) in values.enumerated() {
                                let x = CGFloat(i) * step
                                let y = geo.size.height * (1 - CGFloat((v - minVal) / (maxVal - minVal)))
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                            path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height))
                            path.closeSubpath()
                        }
                        .fill(LinearGradient(colors: [color.opacity(0.2), color.opacity(0.02)], startPoint: .top, endPoint: .bottom))
                        .opacity(Double(progress))
                    }
                }
            }
        }
        .padding(16).cardStyle()
        .onAppear { withAnimation(.easeOut(duration: 1.2).delay(0.3)) { progress = 1 } }
        .onChange(of: values) { _ in progress = 0; withAnimation(.easeOut(duration: 1.2).delay(0.1)) { progress = 1 } }
    }
}

struct StatsSummaryCard: View {
    let entries: [HistoryEntry]; let metric: HistoryView.HistoryMetric; let unit: TemperatureUnit

    var values: [Double] {
        switch metric {
        case .temperature: return entries.map { unit.convert($0.temperature) }
        case .humidity: return entries.map(\.humidity)
        case .ventilation: return entries.map(\.ventilationSpeed)
        }
    }
    var suffix: String { metric == .temperature ? unit.rawValue : metric == .humidity ? "%" : " m/s" }
    var avg: Double { values.isEmpty ? 0 : values.reduce(0,+) / Double(values.count) }
    var min: Double { values.min() ?? 0 }
    var max: Double { values.max() ?? 0 }

    var body: some View {
        HStack(spacing: 0) {
            StatItem(label: "Avg", value: String(format: "%.1f\(suffix)", avg))
            Divider().frame(height: 40).background(Color.divider1)
            StatItem(label: "Min", value: String(format: "%.1f\(suffix)", min))
            Divider().frame(height: 40).background(Color.divider1)
            StatItem(label: "Max", value: String(format: "%.1f\(suffix)", max))
            Divider().frame(height: 40).background(Color.divider1)
            StatItem(label: "Readings", value: "\(values.count)")
        }
        .padding(16).cardStyle()
    }
}

extension DisplayCoordinator: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool { return true }
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer, let view = pan.view else { return false }
        let velocity = pan.velocity(in: view), translation = pan.translation(in: view)
        return translation.x > 0 && abs(velocity.x) > abs(velocity.y)
    }
}


struct StatItem: View {
    let label: String; let value: String
    var body: some View {
        VStack(spacing: 3) {
            Text(value).font(AppFont.display(14)).foregroundColor(Color.textPrimary)
            Text(label).font(.system(size: 10)).foregroundColor(Color.textInactive)
        }
        .frame(maxWidth: .infinity)
    }
}

struct HistoryEntryRow: View {
    let entry: HistoryEntry; let unit: TemperatureUnit
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "clock.fill").font(.system(size: 12)).foregroundColor(Color.textInactive).frame(width: 16)
            Text(entry.timestamp, style: .time).font(AppFont.body(12)).foregroundColor(Color.textSecondary)
            Spacer()
            Text(unit.label(entry.temperature)).font(AppFont.display(12)).foregroundColor(Color.accentBlue)
            Text(String(format: "%.0f%%", entry.humidity)).font(AppFont.display(12)).foregroundColor(Color.humNormal)
            Text(String(format: "%.1fm/s", entry.ventilationSpeed)).font(AppFont.display(12)).foregroundColor(Color.accentGreenActive)
        }
        .padding(.vertical, 8).padding(.horizontal, 14)
        .background(Color.white).cornerRadius(10)
    }
}

// MARK: - Timeline View
struct TimelineView: View {
    let coop: Coop
    @EnvironmentObject var coopsVM: CoopsViewModel
    @EnvironmentObject var appState: AppState

    var entries: [HistoryEntry] { coopsVM.history(for: coop.id) }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(entries.reversed().enumerated()), id: \.1.id) { idx, entry in
                    TimelineRow(entry: entry, unit: appState.temperatureUnit, isLast: idx == entries.count - 1)
                }
                Spacer().frame(height: 80)
            }
            .padding(.horizontal, 16).padding(.top, 8)
        }
        .background(Color.bgPrimary.ignoresSafeArea())
        .navigationTitle("Timeline")
    }
}

struct TimelineRow: View {
    let entry: HistoryEntry; let unit: TemperatureUnit; let isLast: Bool
    var tempStatus: ClimateStatus { entry.temperature < 10 || entry.temperature > 27 ? .warning : .normal }
    var humStatus: ClimateStatus { entry.humidity < 40 || entry.humidity > 70 ? .warning : .normal }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            // Timeline line
            VStack(spacing: 0) {
                Circle()
                    .fill(tempStatus == .normal && humStatus == .normal ? Color.accentGreen : Color.statusWarning)
                    .frame(width: 12, height: 12)
                    .padding(.top, 4)
                if !isLast {
                    Rectangle().fill(Color.divider1).frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: 16)

            VStack(alignment: .leading, spacing: 8) {
                Text(entry.timestamp, style: .time)
                    .font(AppFont.body(11)).foregroundColor(Color.textInactive)
                HStack(spacing: 12) {
                    Label(unit.label(entry.temperature), systemImage: "thermometer.medium")
                        .font(AppFont.body(12, weight: .semibold)).foregroundColor(Color.accentBlue)
                    Label(String(format: "%.0f%%", entry.humidity), systemImage: "drop.fill")
                        .font(AppFont.body(12, weight: .semibold)).foregroundColor(Color.humNormal)
                }
            }
            .padding(.bottom, 20)
        }
    }
}

// MARK: - Reports View
struct ReportsView: View {
    @EnvironmentObject var coopsVM: CoopsViewModel
    @State private var appeared = false
    @State private var generatingFor: UUID?

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    ForEach(coopsVM.coops) { coop in
                        ReportCoopCard(
                            coop: coop,
                            report: coopsVM.reports.first(where: { $0.coopId == coop.id }),
                            isGenerating: generatingFor == coop.id,
                            onGenerate: {
                                generatingFor = coop.id
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                    _ = coopsVM.generateReport(for: coop)
                                    generatingFor = nil
                                }
                            }
                        )
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)
                        .animation(.spring(response: 0.4, dampingFraction: 0.7).delay(Double(coopsVM.coops.firstIndex(where: { $0.id == coop.id }) ?? 0) * 0.08), value: appeared)
                    }

                    // Comparison
                    NavigationLink(destination: ComparisonView()) {
                        DetailNavRow(icon: "arrow.left.arrow.right", title: "Compare Coops", subtitle: "Side-by-side analysis", color: .accentBlueActive)
                    }
                    .opacity(appeared ? 1 : 0)

                    Spacer().frame(height: 80)
                }
                .padding(16)
            }
            .background(Color.bgPrimary.ignoresSafeArea())
            .navigationTitle("Reports")
        }
        .onAppear { withAnimation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.1)) { appeared = true } }
    }
}

struct ReportCoopCard: View {
    let coop: Coop
    let report: ReportData?
    let isGenerating: Bool
    let onGenerate: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("🐔").font(.system(size: 22))
                Text(coop.name).font(AppFont.display(15)).foregroundColor(Color.textPrimary)
                Spacer()
                if isGenerating {
                    ProgressView().tint(Color.accentGreen)
                } else {
                    Button(action: onGenerate) {
                        Label("Generate", systemImage: "arrow.clockwise")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color.accentGreen)
                    }
                }
            }

            if let r = report {
                HStack(spacing: 0) {
                    StatItem(label: "Avg Temp", value: String(format: "%.1f°C", r.avgTemperature))
                    Divider().frame(height: 36).background(Color.divider1)
                    StatItem(label: "Avg Humid", value: String(format: "%.0f%%", r.avgHumidity))
                    Divider().frame(height: 36).background(Color.divider1)
                    StatItem(label: "Alerts", value: "\(r.alertCount)")
                    Divider().frame(height: 36).background(Color.divider1)
                    StatItem(label: "Tasks Done", value: "\(r.taskCompletedCount)")
                }
                Text("Generated: \(r.generatedAt, style: .date)").font(AppFont.body(11)).foregroundColor(Color.textInactive)
            } else {
                Text("No report yet — tap Generate").font(AppFont.body(13)).foregroundColor(Color.textInactive)
            }
        }
        .padding(16).cardStyle()
    }
}

// MARK: - Comparison View
struct ComparisonView: View {
    @EnvironmentObject var coopsVM: CoopsViewModel
    @EnvironmentObject var appState: AppState

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                if coopsVM.coops.count >= 2 {
                    ForEach(0..<(coopsVM.coops.count - 1), id: \.self) { i in
                        CompareRow(a: coopsVM.coops[i], b: coopsVM.coops[i + 1], unit: appState.temperatureUnit)
                    }
                } else {
                    Text("Add at least 2 coops to compare").font(AppFont.body(14)).foregroundColor(Color.textSecondary).padding()
                }
                Spacer().frame(height: 80)
            }
            .padding(16)
        }
        .background(Color.bgPrimary.ignoresSafeArea())
        .navigationTitle("Comparison")
    }
}

struct CompareRow: View {
    let a: Coop; let b: Coop; let unit: TemperatureUnit
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text(a.name).font(AppFont.display(13)).foregroundColor(Color.textPrimary).frame(maxWidth: .infinity, alignment: .leading)
                Text("VS").font(.system(size: 11, weight: .heavy)).foregroundColor(Color.textInactive)
                Text(b.name).font(AppFont.display(13)).foregroundColor(Color.textPrimary).frame(maxWidth: .infinity, alignment: .trailing)
            }
            HStack {
                if let ta = a.latestTemperature, let tb = b.latestTemperature {
                    Text(unit.label(ta)).font(AppFont.display(14)).foregroundColor(.accentBlue)
                    Spacer()
                    Text("Temp").font(AppFont.body(11)).foregroundColor(Color.textInactive)
                    Spacer()
                    Text(unit.label(tb)).font(AppFont.display(14)).foregroundColor(.accentBlue)
                }
            }
            HStack {
                if let ha = a.latestHumidity, let hb = b.latestHumidity {
                    Text(String(format: "%.0f%%", ha)).font(AppFont.display(14)).foregroundColor(.humNormal)
                    Spacer()
                    Text("Humid").font(AppFont.body(11)).foregroundColor(Color.textInactive)
                    Spacer()
                    Text(String(format: "%.0f%%", hb)).font(AppFont.display(14)).foregroundColor(.humNormal)
                }
            }
        }
        .padding(16).cardStyle()
    }
}
