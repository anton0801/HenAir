import SwiftUI
import Combine
import Network

struct SplashView: View {

    // Phase flags
    @State private var isVisible = false
    @State private var bgShift = false
    @State private var particlesVisible = false
    @State private var iconScale: CGFloat = 0.3
    @State private var iconOpacity: Double = 0
    @State private var titleOpacity: Double = 0
    @StateObject private var watcher = HenAirWatcher()
    @State private var titleOffset: CGFloat = 30
    @State private var subtitleOpacity: Double = 0
    @State private var exitScale: CGFloat = 1.0
    @State private var exitOpacity: Double = 1.0

    // Particle animations
    @State private var p1Offset: CGFloat = 0
    @State private var p2Offset: CGFloat = 0
    @State private var p3Offset: CGFloat = 0
    @State private var p1Opacity: Double = 0
    @State private var p2Opacity: Double = 0
    @State private var p3Opacity: Double = 0
    @State private var networkMonitor = NWPathMonitor()
    @State private var cancellables = Set<AnyCancellable>()
    @State private var thermScale: CGFloat = 0.5
    @State private var thermOpacity: Double = 0
    @State private var waveOffset: CGFloat = 0
    @State private var leafRot1: Double = 0
    @State private var leafRot2: Double = 0
    @State private var leafRot3: Double = 0

    var body: some View {
        NavigationView {
            ZStack {
                // LAYER 1: Animated background gradient
                LinearGradient(
                    colors: bgShift
                        ? [Color(hex: "#E6F7F0"), Color(hex: "#ECFEFF"), Color(hex: "#F0FDF9")]
                        : [Color(hex: "#F0FDF9"), Color(hex: "#E6F7F0"), Color(hex: "#D1FAE5")],
                    startPoint: bgShift ? .topLeading : .bottomTrailing,
                    endPoint: bgShift ? .bottomTrailing : .topLeading
                )
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: bgShift)
                
                GeometryReader { geo in
                    Image("hen_air_load_bg")
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .ignoresSafeArea()
                        .opacity(0.3)
                }
                .ignoresSafeArea()

                // Ambient circles
                Circle()
                    .fill(Color.accentGreen.opacity(0.08))
                    .frame(width: 400, height: 400)
                    .offset(x: -80, y: -200)
                    .scaleEffect(bgShift ? 1.1 : 0.95)
                    .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: bgShift)

                Circle()
                    .fill(Color.accentBlue.opacity(0.07))
                    .frame(width: 300, height: 300)
                    .offset(x: 100, y: 250)
                    .scaleEffect(bgShift ? 0.9 : 1.05)
                    .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: bgShift)
                
                NavigationLink(
                      destination: HenAirDisplay().navigationBarHidden(true),
                      isActive: $watcher.navigateToWeb
                  ) { EmptyView() }
                  
                  NavigationLink(
                      destination: RootView().navigationBarBackButtonHidden(true),
                      isActive: $watcher.navigateToMain
                  ) { EmptyView() }

                // LAYER 2: Floating climate particles
                FloatingParticles(isVisible: $isVisible)

                // Floating leaf elements
                Group {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color.accentGreen.opacity(0.35))
                        .rotationEffect(.degrees(leafRot1))
                        .offset(x: -130, y: p1Offset - 60)
                        .opacity(p1Opacity)

                    Image(systemName: "leaf.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Color.accentBlue.opacity(0.3))
                        .rotationEffect(.degrees(leafRot2))
                        .offset(x: 120, y: p2Offset - 120)
                        .opacity(p2Opacity)

                    Image(systemName: "drop.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Color.accentBlueActive.opacity(0.4))
                        .offset(x: 90, y: p3Offset + 80)
                        .opacity(p3Opacity)
                }

                // Thermometer floating element (midground)
//                ZStack {
//                    Circle()
//                        .fill(Color.accentBlue.opacity(0.12))
//                        .frame(width: 120, height: 120)
//                        .offset(y: -30)
//
//                    Image(systemName: "thermometer.medium")
//                        .font(.system(size: 48, weight: .light))
//                        .foregroundColor(Color.accentBlue)
//                        .offset(x: 40, y: -20)
//                        .scaleEffect(thermScale)
//                        .opacity(thermOpacity)
//                }

                // LAYER 3: Main content
                VStack(spacing: 0) {
                    Spacer()

                    // App name
                    VStack(spacing: 8) {
                        HStack(spacing: 0) {
                            Text("Hen")
                                .font(.system(size: 44, weight: .heavy, design: .rounded))
                                .foregroundColor(Color.textPrimary)
                            Text(" Air")
                                .font(.system(size: 44, weight: .heavy, design: .rounded))
                                .foregroundColor(Color.accentGreen)
                        }
                        .opacity(titleOpacity)
                        .offset(y: titleOffset)

                        Text("Loading ...")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(Color.textSecondary.opacity(0.7))
                            .opacity(subtitleOpacity)
                            .offset(y: titleOffset * 0.5)
                        
                        LoadingAnimationView(style: .arcRing)
                    }

                    Spacer()

                    // Wave / loading indicator
                    WaveIndicator(offset: $waveOffset)
                        .opacity(subtitleOpacity)
                        .padding(.bottom, 60)
                }
                
                if watcher.showOfflineView {
                    ZStack {
                        Color.black
                            .ignoresSafeArea()
                            .opacity(0.8)
                        
                        Image("error_in_app")
                            .resizable()
                            .frame(width: 240, height: 180)
                    }
                }
            }
            .scaleEffect(exitScale)
            .opacity(exitOpacity)
            .fullScreenCover(isPresented: $watcher.showPermissionPrompt) {
                ConsentFrame(watcher: watcher)
            }
            .onAppear { startAnimations() }
            .onDisappear { stopAnimations() }
            .ignoresSafeArea()
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .ignoresSafeArea()
    }

    private func startAnimations() {
        isVisible = true
        // Phase 1: BG builds in (0–0.6s)
        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
            bgShift = true
        }
        
        NotificationCenter.default.publisher(for: .attributionRoost)
            .compactMap { $0.userInfo?["conversionData"] as? [String: Any] }
            .sink { data in
                watcher.ingestAttribution(data)
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: .deeplinksRoost)
            .compactMap { $0.userInfo?["deeplinksData"] as? [String: Any] }
            .sink { data in
                watcher.ingestDeeplinks(data)
            }
            .store(in: &cancellables)
        
        setupNetworkMonitoring()
        watcher.ignite()

        // Phase 2: Particles & thematic elements (0.6–1.4s)
        withAnimation(.easeOut(duration: 0.8).delay(0.5)) {
            thermScale = 1.0; thermOpacity = 1.0
            p1Opacity = 0.8; p2Opacity = 0.7; p3Opacity = 0.9
        }
        withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true).delay(0.5)) {
            p1Offset = -30; p2Offset = 20; p3Offset = -20
        }
        withAnimation(.linear(duration: 6).repeatForever(autoreverses: false).delay(0.5)) {
            leafRot1 = 360; leafRot2 = -360; leafRot3 = 180
        }

        // Phase 3: Logo + title (1.4–2.2s)
        withAnimation(.spring(response: 0.5, dampingFraction: 0.65).delay(1.2)) {
            iconScale = 1.0; iconOpacity = 1.0
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(1.5)) {
            titleOpacity = 1.0; titleOffset = 0
        }
        withAnimation(.easeOut(duration: 0.6).delay(1.9)) {
            subtitleOpacity = 1.0
        }
        withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false).delay(2.0)) {
            waveOffset = 1.0
        }
    }

    private func stopAnimations() {
        isVisible = false
        bgShift = false
        particlesVisible = false
        iconScale = 0.3; iconOpacity = 0
        titleOpacity = 0; titleOffset = 30; subtitleOpacity = 0
        thermScale = 0.5; thermOpacity = 0
        p1Offset = 0; p2Offset = 0; p3Offset = 0
        p1Opacity = 0; p2Opacity = 0; p3Opacity = 0
        leafRot1 = 0; leafRot2 = 0; leafRot3 = 0
        waveOffset = 0
        exitScale = 1.0; exitOpacity = 1.0
    }
    
    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { path in
            Task { @MainActor in
                watcher.networkConnectivityChanged(path.status == .satisfied)
            }
        }
        networkMonitor.start(queue: .global(qos: .background))
    }
}

// MARK: - Floating Particles
struct FloatingParticles: View {
    @Binding var isVisible: Bool
    let particles: [ParticleData] = (0..<12).map { _ in ParticleData() }

    var body: some View {
        ZStack {
            ForEach(particles) { p in
                FloatingParticle(data: p, isVisible: isVisible)
            }
        }
    }
}


struct ParticleData: Identifiable {
    let id = UUID()
    let x: CGFloat = CGFloat.random(in: -180...180)
    let y: CGFloat = CGFloat.random(in: -380...380)
    let size: CGFloat = CGFloat.random(in: 4...10)
    let duration: Double = Double.random(in: 3...6)
    let delay: Double = Double.random(in: 0...2)
    let isGreen: Bool = Bool.random()
}

struct FloatingParticle: View {
    let data: ParticleData
    let isVisible: Bool
    @State private var yOffset: CGFloat = 0
    @State private var opacity: Double = 0

    var body: some View {
        Circle()
            .fill(data.isGreen ? Color.accentGreen.opacity(0.35) : Color.accentBlue.opacity(0.3))
            .frame(width: data.size, height: data.size)
            .offset(x: data.x, y: data.y + yOffset)
            .opacity(opacity)
            .onAppear {
                if isVisible {
                    withAnimation(.easeIn(duration: 0.5).delay(data.delay)) { opacity = 1.0 }
                    withAnimation(.easeInOut(duration: data.duration).repeatForever(autoreverses: true).delay(data.delay)) {
                        yOffset = CGFloat.random(in: -25...25)
                    }
                }
            }
            .onChange(of: isVisible) { v in
                if !v { opacity = 0; yOffset = 0 }
            }
    }
}

struct WaveIndicator: View {
    @Binding var offset: CGFloat

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<5) { i in
                Capsule()
                    .fill(Color.accentGreen.opacity(0.6))
                    .frame(width: 4, height: 8 + CGFloat(sin((offset + Double(i) * 0.5) * .pi * 2)) * 8)
                    .animation(.easeInOut(duration: 0.5).delay(Double(i) * 0.08).repeatForever(autoreverses: true), value: offset)
            }
        }
    }
}

#Preview {
    SplashView()
}
