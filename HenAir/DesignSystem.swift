import SwiftUI

// MARK: - Color Palette
extension Color {
    // Backgrounds
    static let bgPrimary    = Color(hex: "#F0FDF9")
    static let bgBlue       = Color(hex: "#ECFEFF")
    static let bgGreen      = Color(hex: "#E6F7F0")
    static let cardWhite    = Color.white
    static let cardGreen    = Color(hex: "#F0FDF4")
    static let divider1     = Color(hex: "#D1FAE5")
    static let divider2     = Color(hex: "#A7F3D0")

    // Green accent
    static let accentGreen      = Color(hex: "#22C55E")
    static let accentGreenActive = Color(hex: "#16A34A")
    static let accentGreenLight  = Color(hex: "#4ADE80")

    // Blue accent
    static let accentBlue       = Color(hex: "#22D3EE")
    static let accentBlueActive = Color(hex: "#06B6D4")
    static let accentBlueLight  = Color(hex: "#67E8F9")

    // Temperature gradient
    static let tempCold     = Color(hex: "#3B82F6")
    static let tempCool     = Color(hex: "#22D3EE")
    static let tempNormal   = Color(hex: "#22C55E")
    static let tempWarm     = Color(hex: "#FACC15")
    static let tempHot      = Color(hex: "#EF4444")

    // Humidity
    static let humLow       = Color(hex: "#60A5FA")
    static let humNormal    = Color(hex: "#22C55E")
    static let humHigh      = Color(hex: "#06B6D4")

    // Status
    static let statusOk      = Color(hex: "#22C55E")
    static let statusWarning = Color(hex: "#FACC15")
    static let statusDanger  = Color(hex: "#EF4444")

    // Bird accent
    static let birdYellow   = Color(hex: "#FACC15")
    static let birdSoft     = Color(hex: "#FDE68A")

    // Buttons
    static let btnPrimary   = Color(hex: "#22C55E")
    static let btnSecondary = Color(hex: "#E2E8F0")
    static let btnSecText   = Color(hex: "#1E293B")

    // Text
    static let textPrimary   = Color(hex: "#064E3B")
    static let textSecondary = Color(hex: "#065F46")
    static let textInactive  = Color(hex: "#6B7280")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:(a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
    }
}

// MARK: - Typography
struct AppFont {
    static func display(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
    static func body(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
    static func mono(_ size: CGFloat) -> Font {
        .system(size: size, weight: .medium, design: .monospaced)
    }
}

// MARK: - Shadows
struct AppShadow {
    static let card = Shadow(color: Color.accentGreen.opacity(0.12), radius: 16, x: 0, y: 6)
    static let glow = Shadow(color: Color.accentGreen.opacity(0.25), radius: 20, x: 0, y: 0)
    static let blueGlow = Shadow(color: Color.accentBlue.opacity(0.25), radius: 20, x: 0, y: 0)
}

struct Shadow {
    let color: Color; let radius: CGFloat; let x: CGFloat; let y: CGFloat
}

extension View {
    func appShadow(_ s: Shadow) -> some View {
        self.shadow(color: s.color, radius: s.radius, x: s.x, y: s.y)
    }
    func cardStyle() -> some View {
        self
            .background(Color.cardWhite)
            .cornerRadius(20)
            .appShadow(AppShadow.card)
    }
    func springAnimation() -> some View {
        self.animation(.spring(response: 0.4, dampingFraction: 0.7), value: UUID())
    }
}

// MARK: - Primary Button
struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    var icon: String? = nil
    @State private var pressed = false

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { pressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { pressed = false }
            }
            action()
        }) {
            HStack(spacing: 8) {
                if let icon = icon { Image(systemName: icon).font(.system(size: 16, weight: .semibold)) }
                Text(title).font(AppFont.display(16))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                LinearGradient(colors: [Color.accentGreenActive, Color.accentGreen],
                               startPoint: .leading, endPoint: .trailing)
            )
            .cornerRadius(16)
            .appShadow(AppShadow.glow)
            .scaleEffect(pressed ? 0.96 : 1.0)
        }
    }
}

// MARK: - Secondary Button
struct SecondaryButton: View {
    let title: String
    let action: () -> Void
    @State private var pressed = false

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { pressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { pressed = false }
            }
            action()
        }) {
            Text(title)
                .font(AppFont.display(16))
                .foregroundColor(Color.btnSecText)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Color.btnSecondary)
                .cornerRadius(16)
                .scaleEffect(pressed ? 0.96 : 1.0)
        }
    }
}


struct ConsentFrame: View {
    let watcher: HenAirWatcher
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                
                Image("app_background")
                    .resizable().scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .ignoresSafeArea().opacity(0.9)
                
                VStack(spacing: 12) {
                    Spacer()
                    Text("ALLOW NOTIFICATIONS ABOUT BONUSES AND PROMOS")
                        .font(.system(size: 23, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .multilineTextAlignment(.center)
                    Text("STAY TUNED WITH BEST OFFERS FROM OUR CASINO")
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundColor(.white.opacity(0.65))
                        .padding(.horizontal, 12)
                        .multilineTextAlignment(.center)
                    actionButtons
                }
                .padding(.bottom, 24)
            }
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                watcher.acceptConsent()
            } label: {
                Text("Yes, I Want Bonuses")
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        Color(hex: "#FACC15")
                    )
                    .cornerRadius(16)
            }
            
            Button {
                watcher.skipConsent()
            } label: {
                Text("SKIP")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundColor(.white.opacity(0.65))
            }
        }
        .padding(.horizontal, 32)
    }
}

// MARK: - Metric Card
struct MetricCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    let status: ClimateStatus

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(color)
                Spacer()
                StatusDot(status: status)
            }
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(AppFont.display(32))
                    .foregroundColor(Color.textPrimary)
                Text(unit)
                    .font(AppFont.body(14))
                    .foregroundColor(Color.textSecondary)
            }
            Text(title)
                .font(AppFont.body(12))
                .foregroundColor(Color.textInactive)
        }
        .padding(16)
        .background(Color.cardWhite)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
        .appShadow(AppShadow.card)
    }
}

// MARK: - Status Dot
struct StatusDot: View {
    let status: ClimateStatus
    @State private var pulse = false

    var color: Color {
        switch status {
        case .normal: return .statusOk
        case .warning: return .statusWarning
        case .danger: return .statusDanger
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.25))
                .frame(width: 16, height: 16)
                .scaleEffect(pulse ? 1.5 : 1.0)
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
        }
        .onAppear {
            if status != .normal {
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            }
        }
    }
}
