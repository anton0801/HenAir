import SwiftUI

struct SplashView: View {
    var onComplete: () -> Void

    // Phase flags
    @State private var isVisible = false
    @State private var bgShift = false
    @State private var particlesVisible = false
    @State private var iconScale: CGFloat = 0.3
    @State private var iconOpacity: Double = 0
    @State private var titleOpacity: Double = 0
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
    @State private var thermScale: CGFloat = 0.5
    @State private var thermOpacity: Double = 0
    @State private var waveOffset: CGFloat = 0
    @State private var leafRot1: Double = 0
    @State private var leafRot2: Double = 0
    @State private var leafRot3: Double = 0

    var body: some View {
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
            ZStack {
                Circle()
                    .fill(Color.accentBlue.opacity(0.12))
                    .frame(width: 120, height: 120)
                    .offset(y: -30)

                Image(systemName: "thermometer.medium")
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(Color.accentBlue)
                    .offset(x: 40, y: -20)
                    .scaleEffect(thermScale)
                    .opacity(thermOpacity)
            }

            // LAYER 3: Main content
            VStack(spacing: 0) {
                Spacer()

                // Icon cluster
                ZStack {
                    // Glow ring
                    Circle()
                        .fill(
                            RadialGradient(colors: [Color.accentGreen.opacity(0.3), Color.clear],
                                           center: .center, startRadius: 20, endRadius: 80)
                        )
                        .frame(width: 160, height: 160)
                        .scaleEffect(iconScale)

                    // Icon card
                    ZStack {
                        RoundedRectangle(cornerRadius: 32)
                            .fill(
                                LinearGradient(colors: [Color.white, Color(hex: "#F0FDF4")],
                                               startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .frame(width: 110, height: 110)
                            .shadow(color: Color.accentGreen.opacity(0.3), radius: 20, y: 8)

                        // Chicken + climate icons
                        VStack(spacing: 4) {
                            HStack(spacing: 6) {
                                Text("🐔")
                                    .font(.system(size: 34))
                                Image(systemName: "thermometer.sun.fill")
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundColor(Color.accentBlue)
                            }
                            HStack(spacing: 3) {
                                Image(systemName: "drop.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(Color.humNormal)
                                Image(systemName: "wind")
                                    .font(.system(size: 10))
                                    .foregroundColor(Color.accentBlue)
                            }
                        }
                    }
                    .scaleEffect(iconScale)
                    .opacity(iconOpacity)
                }

                Spacer().frame(height: 36)

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

                    Text("Control your coop climate")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(Color.textSecondary.opacity(0.7))
                        .opacity(subtitleOpacity)
                        .offset(y: titleOffset * 0.5)
                }

                Spacer()

                // Wave / loading indicator
                WaveIndicator(offset: $waveOffset)
                    .opacity(subtitleOpacity)
                    .padding(.bottom, 60)
            }
        }
        .scaleEffect(exitScale)
        .opacity(exitOpacity)
        .onAppear { startAnimations() }
        .onDisappear { stopAnimations() }
    }

    private func startAnimations() {
        isVisible = true
        // Phase 1: BG builds in (0–0.6s)
        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
            bgShift = true
        }

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

        // Phase 4: Exit (2.8s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
            guard isVisible else { return }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                exitScale = 1.08
                exitOpacity = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                onComplete()
            }
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

// MARK: - Wave Indicator
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
