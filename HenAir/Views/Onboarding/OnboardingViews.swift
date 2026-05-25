import SwiftUI

// MARK: - Welcome Screen
struct WelcomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var showLogin = false
    @State private var logoVisible = false
    @State private var contentVisible = false

    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()

            // Background decoration
            VStack {
                Circle()
                    .fill(Color.accentGreen.opacity(0.08))
                    .frame(width: 350, height: 350)
                    .offset(x: 80, y: -100)
                Spacer()
                Circle()
                    .fill(Color.accentBlue.opacity(0.07))
                    .frame(width: 250, height: 250)
                    .offset(x: -80, y: 80)
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Logo
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(colors: [Color.accentGreen.opacity(0.2), Color.clear],
                                           center: .center, startRadius: 0, endRadius: 80)
                        )
                        .frame(width: 160, height: 160)

                    ZStack {
                        RoundedRectangle(cornerRadius: 28)
                            .fill(Color.white)
                            .frame(width: 90, height: 90)
                            .shadow(color: Color.accentGreen.opacity(0.25), radius: 16, y: 6)

                        VStack(spacing: 2) {
                            Text("🐔").font(.system(size: 36))
                            Image(systemName: "thermometer.sun.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color.accentBlue)
                        }
                    }
                }
                .scaleEffect(logoVisible ? 1 : 0.5)
                .opacity(logoVisible ? 1 : 0)

                Spacer().frame(height: 32)

                VStack(spacing: 8) {
                    HStack(spacing: 0) {
                        Text("Hen").font(.system(size: 40, weight: .heavy, design: .rounded)).foregroundColor(Color.textPrimary)
                        Text(" Air").font(.system(size: 40, weight: .heavy, design: .rounded)).foregroundColor(Color.accentGreen)
                    }
                    Text("Smart coop climate control")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(Color.textSecondary.opacity(0.65))
                }
                .opacity(contentVisible ? 1 : 0)
                .offset(y: contentVisible ? 0 : 20)

                Spacer()

                // Buttons
                VStack(spacing: 12) {
                    PrimaryButton(title: "Get Started", icon: "arrow.right.circle.fill") {
                        appState.hasCompletedOnboarding = false // show onboarding
                    }
                    SecondaryButton(title: "Log In") {
                        showLogin = true
                    }
                }
                .padding(.horizontal, 24)
                .opacity(contentVisible ? 1 : 0)
                .offset(y: contentVisible ? 0 : 30)

                Spacer().frame(height: 50)
            }
        }
        .sheet(isPresented: $showLogin) { LoginView() }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.2)) { logoVisible = true }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.5)) { contentVisible = true }
        }
    }
}

// MARK: - Login View
struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var email = ""
    @State private var saved = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.bgPrimary.ignoresSafeArea()
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Your Name").font(AppFont.body(13)).foregroundColor(Color.textSecondary)
                        TextField("e.g. John Smith", text: $name)
                            .padding(14).background(Color.white).cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.divider1, lineWidth: 1))
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Email").font(AppFont.body(13)).foregroundColor(Color.textSecondary)
                        TextField("john@example.com", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .padding(14).background(Color.white).cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.divider1, lineWidth: 1))
                    }

                    if saved {
                        HStack {
                            Image(systemName: "checkmark.circle.fill").foregroundColor(.accentGreen)
                            Text("Saved!").foregroundColor(.accentGreen).font(AppFont.body(14, weight: .semibold))
                        }
                    }

                    PrimaryButton(title: "Continue") {
                        if !name.isEmpty { appState.userName = name }
                        if !email.isEmpty { appState.userEmail = email }
                        saved = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            appState.hasCompletedOnboarding = true
                            dismiss()
                        }
                    }
                }
                .padding(24)
            }
            .navigationTitle("Log In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Onboarding Container
struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentPage = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $currentPage) {
                OnboardingPage1(currentPage: $currentPage).tag(0)
                OnboardingPage2(currentPage: $currentPage).tag(1)
                OnboardingPage3(currentPage: $currentPage).tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()

            // Navigation controls
            VStack(spacing: 16) {
                // Page dots
                HStack(spacing: 8) {
                    ForEach(0..<3) { i in
                        Capsule()
                            .fill(i == currentPage ? Color.accentGreen : Color.accentGreen.opacity(0.25))
                            .frame(width: i == currentPage ? 24 : 8, height: 8)
                            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: currentPage)
                    }
                }

                HStack(spacing: 12) {
                    Button("Skip") {
                        appState.hasCompletedOnboarding = true
                    }
                    .font(AppFont.body(15, weight: .medium))
                    .foregroundColor(Color.textInactive)

                    Spacer()

                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            if currentPage < 2 { currentPage += 1 }
                            else { appState.hasCompletedOnboarding = true }
                        }
                    }) {
                        HStack(spacing: 6) {
                            Text(currentPage < 2 ? "Next" : "Start")
                                .font(AppFont.display(15))
                            Image(systemName: currentPage < 2 ? "arrow.right" : "checkmark")
                                .font(.system(size: 13, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .frame(height: 48)
                        .background(Color.accentGreen)
                        .cornerRadius(14)
                        .appShadow(AppShadow.glow)
                    }
                }
                .padding(.horizontal, 28)
            }
            .padding(.bottom, 50)
        }
    }
}

// MARK: - Onboarding Page 1: Track Temperature (tap interaction)
struct OnboardingPage1: View {
    @Binding var currentPage: Int
    @State private var tapped = false
    @State private var particles: [(CGFloat, CGFloat, Color)] = []
    @State private var isVisible = false
    @State private var bgPulse = false

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: "#E6F7F0"), Color(hex: "#F0FDF9")],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            // Pulsing bg circle
            Circle()
                .fill(Color.accentGreen.opacity(bgPulse ? 0.12 : 0.05))
                .frame(width: 500, height: 500)
                .scaleEffect(bgPulse ? 1.05 : 0.95)
                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: bgPulse)

            VStack(spacing: 0) {
                Spacer().frame(height: 100)

                // Tap target
                ZStack {
                    // Burst particles
                    ForEach(0..<particles.count, id: \.self) { i in
                        Circle()
                            .fill(particles[i].2)
                            .frame(width: 8, height: 8)
                            .offset(x: particles[i].0, y: particles[i].1)
                    }

                    // Thermometer card
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 150, height: 150)
                            .shadow(color: Color.accentBlue.opacity(0.25), radius: 20, y: 8)
                            .scaleEffect(tapped ? 0.9 : 1.0)

                        VStack(spacing: 8) {
                            Image(systemName: "thermometer.sun.fill")
                                .font(.system(size: 56, weight: .light))
                                .foregroundStyle(
                                    LinearGradient(colors: [Color.tempHot, Color.accentBlue],
                                                   startPoint: .top, endPoint: .bottom)
                                )
                                .scaleEffect(tapped ? 1.2 : 1.0)
                                .rotationEffect(.degrees(tapped ? -10 : 0))

                            Text(tapped ? "21.4°C ✓" : "Tap me!")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundColor(tapped ? Color.accentGreen : Color.textInactive)
                        }
                    }
                    .animation(.spring(response: 0.4, dampingFraction: 0.6), value: tapped)
                    .onTapGesture { handleTap() }
                }
                .frame(height: 200)

                Spacer().frame(height: 48)

                VStack(spacing: 12) {
                    Text("Track Temperature")
                        .font(.system(size: 30, weight: .heavy, design: .rounded))
                        .foregroundColor(Color.textPrimary)
                        .multilineTextAlignment(.center)

                    Text("Monitor real-time temperature in every coop.\nKeep your flock in the ideal 15–24°C range.")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(Color.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 32)
                }
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : 24)

                Spacer()
            }
        }
        .onAppear {
            bgPulse = true
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.3)) { isVisible = true }
        }
        .onDisappear {
            bgPulse = false; isVisible = false; tapped = false; particles = []
        }
    }

    func handleTap() {
        guard !tapped else { return }
        tapped = true
        // Burst particles
        let colors: [Color] = [.accentGreen, .accentBlue, .birdYellow, .tempHot, .accentGreenLight]
        particles = (0..<12).map { _ in
            (CGFloat.random(in: -80...80), CGFloat.random(in: -80...80), colors.randomElement()!)
        }
        withAnimation(.easeOut(duration: 0.6)) {
            particles = particles.map { (p: (CGFloat, CGFloat, Color)) in
                (p.0 * 1.8, p.1 * 1.8, p.2)
            }
        }
        withAnimation(.easeOut(duration: 0.8).delay(0.4)) {
            particles = particles.map { (p: (CGFloat, CGFloat, Color)) in
                (p.0, p.1, p.2.opacity(0))
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { particles = [] }
    }
}

// MARK: - Onboarding Page 2: Control Humidity (drag interaction)
struct OnboardingPage2: View {
    @Binding var currentPage: Int
    @State private var dragOffset: CGFloat = 0
    @State private var isVisible = false
    @State private var waveAnim = false

    var humidity: Double { max(20, min(100, 60 + Double(dragOffset) * 0.3)) }
    var humColor: Color {
        if humidity < 40 { return .humLow }
        if humidity > 70 { return .humHigh }
        return .humNormal
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: "#ECFEFF"), Color(hex: "#F0FDF9")],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer().frame(height: 100)

                // Humidity sphere
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 160, height: 160)
                        .shadow(color: humColor.opacity(0.3), radius: 20, y: 8)

                    // Water fill
                    GeometryReader { geo in
                        let fillH = geo.size.height * (humidity / 100)
                        VStack {
                            Spacer()
                            Rectangle()
                                .fill(humColor.opacity(0.3))
                                .frame(height: fillH)
                                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: humidity)
                        }
                        .clipShape(Circle())
                    }
                    .frame(width: 160, height: 160)

                    VStack(spacing: 4) {
                        Image(systemName: "drop.fill")
                            .font(.system(size: 36, weight: .light))
                            .foregroundColor(humColor)
                        Text("\(Int(humidity))%")
                            .font(.system(size: 22, weight: .heavy, design: .rounded))
                            .foregroundColor(Color.textPrimary)
                    }
                }
                .gesture(
                    DragGesture()
                        .onChanged { v in
                            dragOffset = v.translation.height * -1
                        }
                        .onEnded { _ in
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                dragOffset = 0
                            }
                        }
                )

                Text("Drag up/down to simulate")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.textInactive)
                    .padding(.top, 12)

                Spacer().frame(height: 40)

                VStack(spacing: 12) {
                    Text("Control Humidity")
                        .font(.system(size: 30, weight: .heavy, design: .rounded))
                        .foregroundColor(Color.textPrimary)
                    Text("Ideal humidity: 50–70%.\nToo high causes disease. Too low affects egg production.")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(Color.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 32)
                }
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : 24)

                Spacer()
            }
        }
        .onAppear { withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.3)) { isVisible = true } }
        .onDisappear { isVisible = false; dragOffset = 0 }
    }
}

// MARK: - Onboarding Page 3: Keep Birds Comfortable (scroll-driven)
struct OnboardingPage3: View {
    @Binding var currentPage: Int
    @State private var isVisible = false
    @State private var birdBob = false
    @State private var glowPulse = false
    @State private var checkmarks: [Bool] = [false, false, false]
    @State private var scrollProgress: CGFloat = 0

    let items = [
        ("thermometer.sun.fill", "Temperature", "15–24°C", Color.accentBlue),
        ("drop.fill", "Humidity", "50–70%", Color.humNormal),
        ("wind", "Ventilation", "0.5–1.5 m/s", Color.accentGreenActive)
    ]

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: "#F0FDF4"), Color(hex: "#ECFEFF")],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            // Glow
            Circle()
                .fill(Color.accentGreen.opacity(glowPulse ? 0.15 : 0.05))
                .frame(width: 400, height: 400)
                .scaleEffect(glowPulse ? 1.1 : 0.9)
                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: glowPulse)
                .offset(y: -50)

            VStack(spacing: 0) {
                Spacer().frame(height: 100)

                // Chicken illustration
                ZStack {
                    Text("🐔")
                        .font(.system(size: 80))
                        .offset(y: birdBob ? -8 : 0)
                        .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: birdBob)

                    // Stars
                    ForEach(0..<5) { i in
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundColor(Color.birdYellow)
                            .offset(
                                x: CGFloat(i - 2) * 24 + 10,
                                y: -50 + (i % 2 == 0 ? -5 : 5)
                            )
                            .opacity(isVisible ? 1 : 0)
                            .scaleEffect(isVisible ? 1 : 0)
                            .animation(.spring(response: 0.4, dampingFraction: 0.6).delay(Double(i) * 0.1 + 0.8), value: isVisible)
                    }
                }
                .frame(height: 120)

                Spacer().frame(height: 32)

                // Tappable checklist
                VStack(spacing: 10) {
                    ForEach(0..<items.count, id: \.self) { i in
                        HStack(spacing: 14) {
                            Image(systemName: items[i].0)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(items[i].3)
                                .frame(width: 36, height: 36)
                                .background(items[i].3.opacity(0.12))
                                .cornerRadius(10)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(items[i].1).font(AppFont.display(14)).foregroundColor(Color.textPrimary)
                                Text(items[i].2).font(AppFont.body(12)).foregroundColor(Color.textSecondary)
                            }
                            Spacer()
                            Image(systemName: checkmarks[i] ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 22))
                                .foregroundColor(checkmarks[i] ? .accentGreen : .divider2)
                        }
                        .padding(14)
                        .background(Color.white)
                        .cornerRadius(14)
                        .shadow(color: items[i].3.opacity(0.12), radius: 8, y: 3)
                        .scaleEffect(checkmarks[i] ? 1.02 : 1.0)
                        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: checkmarks[i])
                        .onTapGesture { checkmarks[i].toggle() }
                    }
                }
                .padding(.horizontal, 28)
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : 30)

                Spacer().frame(height: 24)

                Text("Keep Birds Comfortable")
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundColor(Color.textPrimary)
                    .opacity(isVisible ? 1 : 0)
                    .offset(y: isVisible ? 0 : 20)

                Spacer()
            }
        }
        .onAppear {
            birdBob = true; glowPulse = true
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.3)) { isVisible = true }
            // Auto-check items
            for i in 0..<3 {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.4 + 1.0) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { checkmarks[i] = true }
                }
            }
        }
        .onDisappear { birdBob = false; glowPulse = false; isVisible = false; checkmarks = [false, false, false] }
    }
}
