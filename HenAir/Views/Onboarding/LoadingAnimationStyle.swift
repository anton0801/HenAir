import SwiftUI

enum LoadingAnimationStyle {
    case arcRing    // Spinning arc with colour trail (recommended)
    case dotsWave   // Three pulsing dots in a row
    case waveform   // Five vertical bars
    case orbit      // Three dots orbiting a centre core
}

// MARK: - LoadingAnimationView
/// Drop-in infinite loading animation.
/// Automatically stops all timers/animations on onDisappear.
///
/// Usage in SplashView:
///   LoadingAnimationView(style: .arcRing, color: Color(hex: "#22C55E"))
///
struct LoadingAnimationView: View {

    var style: LoadingAnimationStyle = .arcRing
    var color: Color = Color(red: 0.133, green: 0.773, blue: 0.369)   // #22C55E
    var accentColor: Color = Color(red: 0.133, green: 0.827, blue: 0.933) // #22D3EE
    var size: CGFloat = 56

    @State private var isAnimating = false

    var body: some View {
        Group {
            switch style {
            case .arcRing:  ArcRingAnimation(isAnimating: $isAnimating, color: color, accentColor: accentColor, size: size)
            case .dotsWave: DotsWaveAnimation(isAnimating: $isAnimating, color: color, size: size)
            case .waveform: WaveformAnimation(isAnimating: $isAnimating, color: color, size: size)
            case .orbit:    OrbitAnimation(isAnimating: $isAnimating, color: color, accentColor: accentColor, size: size)
            }
        }
        .onAppear    { isAnimating = true  }
        .onDisappear { isAnimating = false }
    }
}

// MARK: - Arc Ring
private struct ArcRingAnimation: View {
    @Binding var isAnimating: Bool
    let color: Color
    let accentColor: Color
    let size: CGFloat

    @State private var rotation: Double = 0
    @State private var trailRotation: Double = -20

    private let trackOpacity: Double = 0.15
    private let arcLength: CGFloat = 0.55   // fraction of circumference
    private let trailLength: CGFloat = 0.28
    private let strokeWidth: CGFloat = 3.5

    var body: some View {
        ZStack {
            // Track
            Circle()
                .stroke(color.opacity(trackOpacity), lineWidth: strokeWidth)
                .frame(width: size, height: size)

            // Trail arc
            Circle()
                .trim(from: 0, to: trailLength)
                .stroke(
                    accentColor.opacity(0.55),
                    style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(trailRotation - 90))

            // Main arc
            Circle()
                .trim(from: 0, to: arcLength)
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(rotation - 90))

            // Leading dot
            leadingDot
        }
        .onChange(of: isAnimating) { animating in
            if animating { startAnimation() }
        }
        .onAppear {
            if isAnimating { startAnimation() }
        }
    }

    private var leadingDot: some View {
        let radius = size / 2
        let angle = Angle(degrees: rotation + Double(arcLength) * 360 - 90)
        let x = radius * CGFloat(cos(angle.radians))
        let y = radius * CGFloat(sin(angle.radians))
        return Circle()
            .fill(color)
            .frame(width: strokeWidth + 1.5, height: strokeWidth + 1.5)
            .offset(x: x, y: y)
    }

    private func startAnimation() {
        rotation = 0
        trailRotation = -20
        withAnimation(
            .linear(duration: 1.2).repeatForever(autoreverses: false)
        ) {
            rotation = 360
        }
        withAnimation(
            .linear(duration: 1.2).repeatForever(autoreverses: false)
            .delay(0.15)
        ) {
            trailRotation = 340
        }
    }
}

// MARK: - Dots Wave
private struct DotsWaveAnimation: View {
    @Binding var isAnimating: Bool
    let color: Color
    let size: CGFloat

    @State private var scales: [CGFloat] = [1, 1, 1]
    @State private var opacities: [Double] = [0.35, 0.35, 0.35]

    private let delays: [Double] = [0, 0.18, 0.36]
    private let dotSize: CGFloat = 9
    private let spacing: CGFloat = 11

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(color)
                    .frame(width: dotSize, height: dotSize)
                    .scaleEffect(scales[i])
                    .opacity(opacities[i])
            }
        }
        .frame(width: size, height: size)
        .onChange(of: isAnimating) { animating in
            if animating { startAnimation() } else { stopAnimation() }
        }
        .onAppear {
            if isAnimating { startAnimation() }
        }
    }

    private func startAnimation() {
        for i in 0..<3 {
            let delay = delays[i]
            withAnimation(
                .easeInOut(duration: 0.5)
                .repeatForever(autoreverses: true)
                .delay(delay)
            ) {
                scales[i] = 1.6
                opacities[i] = 1.0
            }
        }
    }

    private func stopAnimation() {
        withAnimation(.easeOut(duration: 0.2)) {
            scales = [1, 1, 1]
            opacities = [0.35, 0.35, 0.35]
        }
    }
}

// MARK: - Waveform
private struct WaveformAnimation: View {
    @Binding var isAnimating: Bool
    let color: Color
    let size: CGFloat

    @State private var scales: [CGFloat] = [0.35, 0.35, 0.35, 0.35, 0.35]
    @State private var opacities: [Double] = [0.4, 0.4, 0.4, 0.4, 0.4]

    // Relative heights
    private let heights: [CGFloat] = [0.30, 0.55, 1.0, 0.55, 0.30]
    private let delays: [Double]   = [0.00, 0.10, 0.20, 0.10, 0.00]
    private let barWidth: CGFloat = 4
    private let spacing: CGFloat  = 5

    var body: some View {
        HStack(alignment: .bottom, spacing: spacing) {
            ForEach(0..<5, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .frame(width: barWidth, height: (size * 0.6) * heights[i])
                    .scaleEffect(y: scales[i], anchor: .bottom)
                    .opacity(opacities[i])
            }
        }
        .frame(width: size, height: size)
        .onChange(of: isAnimating) { animating in
            if animating { startAnimation() } else { stopAnimation() }
        }
        .onAppear {
            if isAnimating { startAnimation() }
        }
    }

    private func startAnimation() {
        for i in 0..<5 {
            withAnimation(
                .easeInOut(duration: 0.55)
                .repeatForever(autoreverses: true)
                .delay(delays[i])
            ) {
                scales[i] = 1.0
                opacities[i] = 1.0
            }
        }
    }

    private func stopAnimation() {
        withAnimation(.easeOut(duration: 0.2)) {
            scales   = [0.35, 0.35, 0.35, 0.35, 0.35]
            opacities = [0.4, 0.4, 0.4, 0.4, 0.4]
        }
    }
}

// MARK: - Orbit
private struct OrbitAnimation: View {
    @Binding var isAnimating: Bool
    let color: Color
    let accentColor: Color
    let size: CGFloat

    @State private var rotations: [Double] = [0, 120, 240]
    @State private var coreScale: CGFloat = 1.0

    private let orbitRadius: CGFloat = 18
    private let dotSize: CGFloat = 7
    private let coreSize: CGFloat = 11
    private let orbitDuration: Double = 1.5

    var body: some View {
        ZStack {
            // Core
            Circle()
                .fill(color)
                .frame(width: coreSize, height: coreSize)
                .scaleEffect(coreScale)
                .opacity(0.85)

            // Orbit dots
            ForEach(0..<3, id: \.self) { i in
                orbitDot(index: i)
            }
        }
        .frame(width: size, height: size)
        .onChange(of: isAnimating) { animating in
            if animating { startAnimation() }
        }
        .onAppear {
            if isAnimating { startAnimation() }
        }
    }

    private func orbitDot(index: Int) -> some View {
        let angle = Angle(degrees: rotations[index])
        let x = orbitRadius * CGFloat(cos(angle.radians))
        let y = orbitRadius * CGFloat(sin(angle.radians))
        return Circle()
            .fill(accentColor)
            .frame(width: dotSize, height: dotSize)
            .offset(x: x, y: y)
            .opacity(0.8)
    }

    private func startAnimation() {
        // Core pulse
        withAnimation(
            .easeInOut(duration: 0.8).repeatForever(autoreverses: true)
        ) {
            coreScale = 1.2
        }

        // Orbit spin — each dot starts at its initial phase offset
        let baseDelay: [Double] = [0, orbitDuration / 3, orbitDuration * 2 / 3]
        for i in 0..<3 {
            // Use a Timer-driven approach via rotation for smooth orbit
            _ = baseDelay[i] // phase is baked into initial rotations
        }
        withAnimation(
            .linear(duration: orbitDuration).repeatForever(autoreverses: false)
        ) {
            rotations = rotations.map { $0 + 360 }
        }
    }
}

// MARK: - Preview
struct LoadingAnimationView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color(red: 0.05, green: 0.07, blue: 0.09).ignoresSafeArea()
            VStack(spacing: 40) {
                LoadingAnimationView(style: .arcRing)
                LoadingAnimationView(style: .dotsWave)
                LoadingAnimationView(style: .waveform)
                LoadingAnimationView(style: .orbit)
            }
        }
    }
}
