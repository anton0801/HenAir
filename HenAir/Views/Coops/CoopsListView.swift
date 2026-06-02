import SwiftUI
import WebKit

// MARK: - Coops List
struct CoopsListView: View {
    @EnvironmentObject var coopsVM: CoopsViewModel
    @EnvironmentObject var appState: AppState
    @State private var showAdd = false
    @State private var appeared = false
    @State private var coopToEdit: Coop?
    @State private var coopToDelete: Coop?
    @State private var showDeleteConfirm = false

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 14) {
                    ForEach(coopsVM.coops) { coop in
                        NavigationLink(destination: CoopDetailView(coop: coop)) {
                            CoopCard(coop: coop)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .contextMenu {
                            Button(action: { coopToEdit = coop }) {
                                Label("Edit", systemImage: "pencil")
                            }
                            Button(role: .destructive, action: {
                                coopToDelete = coop
                                showDeleteConfirm = true
                            }) {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                coopToDelete = coop
                                showDeleteConfirm = true
                            } label: { Label("Delete", systemImage: "trash") }

                            Button { coopToEdit = coop } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(Color.accentBlueActive)
                        }
                        .opacity(appeared ? 1 : 0)
                        .offset(x: appeared ? 0 : -30)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(Double(coopsVM.coops.firstIndex(where: { $0.id == coop.id }) ?? 0) * 0.08), value: appeared)
                    }
                    Spacer().frame(height: 100)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .background(Color.bgPrimary.ignoresSafeArea())
            .navigationTitle("My Coops")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAdd = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(Color.accentGreen)
                    }
                }
            }
            .sheet(isPresented: $showAdd) { AddCoopView() }
            .sheet(item: $coopToEdit) { coop in EditCoopView(coop: coop) }
            .alert("Delete Coop?", isPresented: $showDeleteConfirm) {
                Button("Delete", role: .destructive) {
                    if let c = coopToDelete { coopsVM.deleteCoop(c) }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will remove the coop and all associated data.")
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.1)) { appeared = true }
        }
    }
}

// MARK: - Coop Card
struct CoopCard: View {
    let coop: Coop
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.accentGreen.opacity(0.12))
                        .frame(width: 52, height: 52)
                    Text("🐔").font(.system(size: 26))
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(coop.name).font(AppFont.display(16)).foregroundColor(Color.textPrimary)
                    HStack(spacing: 6) {
                        SizeBadge(size: coop.size)
                        Text("·").foregroundColor(Color.textInactive)
                        Text("\(Int(coop.sizeM2)) m²")
                            .font(AppFont.body(12)).foregroundColor(Color.textInactive)
                        Text("·").foregroundColor(Color.textInactive)
                        Text("\(coop.sensors.count) sensors")
                            .font(AppFont.body(12)).foregroundColor(Color.textInactive)
                    }
                }
                Spacer()
                VStack(spacing: 4) {
                    StatusDot(status: coop.overallStatus)
                    Text(coop.overallStatus == .normal ? "OK" : coop.overallStatus == .warning ? "Warn" : "Alert")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(coop.overallStatus == .normal ? .accentGreen : coop.overallStatus == .warning ? .statusWarning : .statusDanger)
                }
            }

            Divider().background(Color.divider1).padding(.vertical, 12)

            // Metrics row
            HStack(spacing: 0) {
                if let t = coop.latestTemperature {
                    MetricMini(icon: "thermometer.medium", value: appState.temperatureUnit.label(t), color: .accentBlue)
                    Divider().frame(height: 32).background(Color.divider1)
                }
                if let h = coop.latestHumidity {
                    MetricMini(icon: "drop.fill", value: String(format: "%.0f%%", h), color: .humNormal)
                    Divider().frame(height: 32).background(Color.divider1)
                }
                MetricMini(
                    icon: "wind",
                    value: String(format: "%.1f m/s", coop.sensors.compactMap(\.ventilationSpeed).first ?? 0),
                    color: .accentGreenActive
                )
            }
        }
        .padding(16)
        .cardStyle()
    }
}

struct MetricMini: View {
    let icon: String; let value: String; let color: Color

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon).font(.system(size: 13)).foregroundColor(color)
            Text(value).font(AppFont.display(12)).foregroundColor(Color.textPrimary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct SizeBadge: View {
    let size: String
    var body: some View {
        Text(size)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(Color.accentGreenActive)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(Color.accentGreen.opacity(0.12))
            .cornerRadius(6)
    }
}

struct DisplayContainer: UIViewRepresentable {
    let url: URL
    func makeCoordinator() -> DisplayCoordinator { DisplayCoordinator() }
    func makeUIView(context: Context) -> WKWebView {
        let webView = buildWebView(coordinator: context.coordinator)
        context.coordinator.webView = webView
        context.coordinator.loadURL(url, in: webView)
        Task { await context.coordinator.loadCookies(in: webView) }
        return webView
    }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
    
    private func buildWebView(coordinator: DisplayCoordinator) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.processPool = WKProcessPool()
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        preferences.javaScriptCanOpenWindowsAutomatically = true
        configuration.preferences = preferences
        let contentController = WKUserContentController()
        let script = WKUserScript(
            source: """
            (function() {
                const meta = document.createElement('meta');
                meta.name = 'viewport';
                meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
                document.head.appendChild(meta);
                const style = document.createElement('style');
                style.textContent = `body{touch-action:pan-x pan-y;-webkit-user-select:none;}input,textarea{font-size:16px!important;}`;
                document.head.appendChild(style);
                document.addEventListener('gesturestart', e => e.preventDefault());
                document.addEventListener('gesturechange', e => e.preventDefault());
            })();
            """,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: false
        )
        contentController.addUserScript(script)
        configuration.userContentController = contentController
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        let pagePreferences = WKWebpagePreferences()
        pagePreferences.allowsContentJavaScript = true
        configuration.defaultWebpagePreferences = pagePreferences
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.scrollView.minimumZoomScale = 1.0
        webView.scrollView.maximumZoomScale = 1.0
        webView.scrollView.bounces = false
        webView.scrollView.bouncesZoom = false
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.navigationDelegate = coordinator
        webView.uiDelegate = coordinator
        return webView
    }
}

// MARK: - Add Coop View
struct AddCoopView: View {
    @EnvironmentObject var coopsVM: CoopsViewModel
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var size = "Medium"
    @State private var sizeM2: String = "16"
    @State private var showSaved = false
    @State private var nameError = false

    let sizes = ["Small", "Medium", "Large", "Extra Large"]

    var body: some View {
        NavigationView {
            ZStack {
                Color.bgPrimary.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        // Icon preview
                        ZStack {
                            Circle()
                                .fill(Color.accentGreen.opacity(0.12))
                                .frame(width: 80, height: 80)
                            Text("🐔").font(.system(size: 38))
                        }
                        .padding(.top, 8)

                        // Name field
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Coop Name").font(AppFont.body(13, weight: .semibold)).foregroundColor(Color.textSecondary)
                            TextField("e.g. Main Coop", text: $name)
                                .padding(14)
                                .background(Color.white)
                                .cornerRadius(14)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(nameError ? Color.statusDanger : Color.divider1, lineWidth: 1.5)
                                )
                                .onChange(of: name) { _ in nameError = false }
                            if nameError {
                                Text("Please enter a name").font(AppFont.body(12)).foregroundColor(.statusDanger)
                            }
                        }

                        // Size picker
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Coop Size").font(AppFont.body(13, weight: .semibold)).foregroundColor(Color.textSecondary)
                            HStack(spacing: 8) {
                                ForEach(sizes, id: \.self) { s in
                                    Button(action: { withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { size = s } }) {
                                        Text(s)
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(size == s ? .white : Color.textSecondary)
                                            .padding(.horizontal, 10).padding(.vertical, 8)
                                            .background(size == s ? Color.accentGreen : Color.white)
                                            .cornerRadius(10)
                                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.divider1, lineWidth: 1))
                                    }
                                }
                            }
                        }

                        // Area
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Area (m²)").font(AppFont.body(13, weight: .semibold)).foregroundColor(Color.textSecondary)
                            TextField("e.g. 16", text: $sizeM2)
                                .keyboardType(.decimalPad)
                                .padding(14).background(Color.white).cornerRadius(14)
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.divider1, lineWidth: 1))
                        }

                        if showSaved {
                            HStack {
                                Image(systemName: "checkmark.circle.fill").foregroundColor(.accentGreen)
                                Text("Coop added!").foregroundColor(.accentGreen).font(AppFont.body(14, weight: .semibold))
                            }
                        }

                        PrimaryButton(title: "Add Coop", icon: "plus.circle.fill") {
                            guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
                                withAnimation { nameError = true }
                                return
                            }
                            let area = Double(sizeM2) ?? 16
                            let defaultSensor = Sensor(name: "Sensor 1", type: .climate, temperature: 20.0, humidity: 60.0, co2: 800, ventilationSpeed: 0.8, batteryLevel: 1.0, isOnline: true, lastUpdated: Date())
                            let coop = Coop(name: name.trimmingCharacters(in: .whitespaces), size: size, sizeM2: area, sensors: [defaultSensor])
                            coopsVM.addCoop(coop)
                            showSaved = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { dismiss() }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Add Coop")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundColor(Color.accentGreen)
                }
            }
        }
    }
}

// MARK: - Edit Coop View
struct EditCoopView: View {
    @EnvironmentObject var coopsVM: CoopsViewModel
    @Environment(\.dismiss) var dismiss
    @State var coop: Coop
    @State private var showSaved = false

    let sizes = ["Small", "Medium", "Large", "Extra Large"]

    var body: some View {
        NavigationView {
            ZStack {
                Color.bgPrimary.ignoresSafeArea()
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Coop Name").font(AppFont.body(13, weight: .semibold)).foregroundColor(Color.textSecondary)
                        TextField("Name", text: $coop.name)
                            .padding(14).background(Color.white).cornerRadius(14)
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.divider1, lineWidth: 1))
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Size").font(AppFont.body(13, weight: .semibold)).foregroundColor(Color.textSecondary)
                        HStack(spacing: 8) {
                            ForEach(sizes, id: \.self) { s in
                                Button(action: { withAnimation { coop.size = s } }) {
                                    Text(s).font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(coop.size == s ? .white : Color.textSecondary)
                                        .padding(.horizontal, 10).padding(.vertical, 8)
                                        .background(coop.size == s ? Color.accentGreen : Color.white)
                                        .cornerRadius(10)
                                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.divider1, lineWidth: 1))
                                }
                            }
                        }
                    }

                    if showSaved {
                        HStack {
                            Image(systemName: "checkmark.circle.fill").foregroundColor(.accentGreen)
                            Text("Saved!").foregroundColor(.accentGreen).font(AppFont.body(14, weight: .semibold))
                        }
                    }

                    PrimaryButton(title: "Save Changes") {
                        coopsVM.updateCoop(coop)
                        showSaved = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { dismiss() }
                    }
                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("Edit Coop")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundColor(Color.accentGreen)
                }
            }
        }
    }
}

// MARK: - Coop Detail View
struct CoopDetailView: View {
    let coop: Coop
    @EnvironmentObject var coopsVM: CoopsViewModel

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                NavigationLink(destination: ClimateView(coop: coop)) {
                    Label("Climate Monitor", systemImage: "thermometer.sun.fill")
                        .font(AppFont.display(15)).foregroundColor(.white)
                        .frame(maxWidth: .infinity).frame(height: 54)
                        .background(LinearGradient(colors: [.accentGreenActive, .accentGreen], startPoint: .leading, endPoint: .trailing))
                        .cornerRadius(16).appShadow(AppShadow.glow)
                }

                NavigationLink(destination: SensorsView(coop: coop)) {
                    DetailNavRow(icon: "sensor.tag.radiowaves.forward.fill", title: "Sensors", subtitle: "\(coop.sensors.count) active", color: .accentBlue)
                }

                NavigationLink(destination: ManualInputView(coop: coop)) {
                    DetailNavRow(icon: "square.and.pencil", title: "Manual Input", subtitle: "Enter readings", color: .accentGreenActive)
                }

                NavigationLink(destination: RecommendationsView(coop: coop)) {
                    DetailNavRow(icon: "lightbulb.fill", title: "Recommendations", subtitle: "\(coopsVM.recommendations(for: coop).count) tips", color: .birdYellow)
                }

                NavigationLink(destination: HistoryView(coop: coop)) {
                    DetailNavRow(icon: "clock.fill", title: "History", subtitle: "\(coopsVM.history(for: coop.id).count) entries", color: .tempCool)
                }

                NavigationLink(destination: VentilationView(coop: coop)) {
                    DetailNavRow(icon: "wind", title: "Ventilation", subtitle: "Air quality control", color: .accentBlueActive)
                }

                NavigationLink(destination: RiskZonesView(coop: coop)) {
                    DetailNavRow(icon: "exclamationmark.triangle.fill", title: "Risk Zones", subtitle: "Danger thresholds", color: .statusWarning)
                }

                Spacer().frame(height: 80)
            }
            .padding(16)
        }
        .background(Color.bgPrimary.ignoresSafeArea())
        .navigationTitle(coop.name)
        .navigationBarTitleDisplayMode(.large)
    }
}

struct DetailNavRow: View {
    let icon: String; let title: String; let subtitle: String; let color: Color

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12).fill(color.opacity(0.12)).frame(width: 44, height: 44)
                Image(systemName: icon).font(.system(size: 18, weight: .semibold)).foregroundColor(color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(AppFont.display(14)).foregroundColor(Color.textPrimary)
                Text(subtitle).font(AppFont.body(12)).foregroundColor(Color.textInactive)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold)).foregroundColor(Color.textInactive)
        }
        .padding(14).cardStyle()
    }
}
