import SwiftUI

/// Shared dark + neon design system: colors, backgrounds, and reusable
/// "frosted glass" building blocks used across every screen.
enum TrekTheme {
    static let accent = Color(red: 0.37, green: 0.92, blue: 0.83)   // teal neon
    static let accent2 = Color(red: 0.45, green: 0.55, blue: 1.0)   // indigo glow
    static let deep = Color(red: 0.09, green: 0.13, blue: 0.22)
    static let bg0 = Color(red: 0.04, green: 0.06, blue: 0.11)
    static let bg1 = Color(red: 0.07, green: 0.10, blue: 0.18)

    static let gradient = LinearGradient(
        colors: [bg1, bg0], startPoint: .top, endPoint: .bottom)
}

/// Subtly glowing background used behind every screen.
///
/// The two neon blobs are static — deliberately NOT animated with
/// `.repeatForever`. A perpetual animation would force the GPU to re-render
/// these large blurs every frame on every screen, which pins the iOS
/// Simulator's GPU and overheats the Mac. Being static, they render once and
/// the compositor caches them, so the cost is paid a single time.
struct ScreenBackground: View {
    var body: some View {
        ZStack {
            TrekTheme.gradient.ignoresSafeArea()
            Circle().fill(TrekTheme.accent.opacity(0.18))
                .frame(width: 320).blur(radius: 60)
                .offset(x: -110, y: -280)
            Circle().fill(TrekTheme.accent2.opacity(0.18))
                .frame(width: 300).blur(radius: 60)
                .offset(x: 120, y: 340)
        }
        .ignoresSafeArea()
    }
}

/// Frosted-glass card container.
struct GlassCard<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(0.10), lineWidth: 1))
            .shadow(color: .black.opacity(0.25), radius: 12, y: 6)
    }
}

extension View {
    /// Standard screen scaffold: dark animated background + content.
    func trekScreen() -> some View {
        self.background(ScreenBackground()).scrollContentBackground(.hidden)
    }
}

/// A neon primary button style.
struct NeonButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity).padding(.vertical, 14)
            .background(
                LinearGradient(colors: [TrekTheme.accent, TrekTheme.accent.opacity(0.8)],
                               startPoint: .leading, endPoint: .trailing),
                in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .foregroundStyle(.black)
            .shadow(color: TrekTheme.accent.opacity(0.5), radius: configuration.isPressed ? 4 : 12, y: 4)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

/// A custom medallion badge — a glossy gradient coin with a metallic rim and an
/// SF Symbol glyph, themed per achievement tier. Replaces emoji badge art.
struct BadgeMedallion: View {
    let badge: Badge
    var size: CGFloat = 64

    var body: some View {
        let (c1, c2) = Self.tier(badge.id)
        ZStack {
            Circle().fill(.white.opacity(0.30))                     // bright outer rim
            ZStack {
                Circle().fill(RadialGradient(
                    colors: [c1, c2],
                    center: UnitPoint(x: 0.38, y: 0.30),
                    startRadius: 1, endRadius: size * 0.85))
                Ellipse().fill(.white.opacity(0.30))                // glossy highlight
                    .frame(width: size * 0.52, height: size * 0.34)
                    .offset(x: -size * 0.07, y: -size * 0.18)
                    .blur(radius: 1)
            }
            .padding(size * 0.045)
            .clipShape(Circle())
            Image(systemName: Self.symbol(badge))
                .font(.system(size: size * 0.40, weight: .bold))
                .foregroundStyle(Color(red: 0.03, green: 0.13, blue: 0.10).opacity(0.92))
        }
        .frame(width: size, height: size)
        .overlay(Circle().stroke(.black.opacity(0.16), lineWidth: 1).padding(size * 0.045))
        .shadow(color: .black.opacity(0.40), radius: size * 0.12, y: size * 0.07)
        .grayscale(badge.earned ? 0 : 1)
        .opacity(badge.earned ? 1 : 0.45)
    }

    // Tier palette — gold for prestige, indigo for distance, ice for polar, teal default.
    static func tier(_ id: String) -> (Color, Color) {
        let teal   = (Color(red: 0.37, green: 0.92, blue: 0.83), Color(red: 0.14, green: 0.72, blue: 0.62))
        let gold   = (Color(red: 1.00, green: 0.85, blue: 0.48), Color(red: 0.92, green: 0.63, blue: 0.12))
        let indigo = (Color(red: 0.54, green: 0.63, blue: 1.00), Color(red: 0.33, green: 0.40, blue: 0.88))
        let ice    = (Color(red: 0.80, green: 0.93, blue: 1.00), Color(red: 0.45, green: 0.70, blue: 0.90))
        switch id {
        case "twenty_five", "fifty_countries", "all_continents", "fifty_cities": return gold
        case "fifty_k_km", "ten_k_km", "north_america", "europe", "asia", "visited_eu": return indigo
        case "visited_an", "visited_oc": return ice
        default: return teal
        }
    }

    // Glyph per badge (SF Symbols, widely available on iOS 15+).
    static func symbol(_ badge: Badge) -> String {
        switch badge.id {
        case "first_trip":       return "map.fill"
        case "five_countries":   return "globe.americas.fill"
        case "ten_countries":    return "globe.europe.africa.fill"
        case "twenty_five":      return "trophy.fill"
        case "fifty_countries":  return "crown.fill"
        case "ten_cities":       return "building.2.fill"
        case "fifty_cities":     return "building.columns.fill"
        case "ten_k_km":         return "rosette"
        case "fifty_k_km":       return "map.fill"
        case "north_america":    return "flag.fill"
        case "europe":           return "building.columns.fill"
        case "asia":             return "flag.checkered"
        case "first_flight":     return "airplane"
        case "train_lover":      return "tram.fill"
        case "road_warrior":     return "car.fill"
        case "weekend_warrior":  return "calendar"
        case "photographer":     return "camera.fill"
        case "visited_af":       return "pawprint.fill"
        case "visited_as":       return "globe.asia.australia.fill"
        case "visited_eu":       return "building.columns.fill"
        case "visited_na":       return "star.fill"
        case "visited_sa":       return "leaf.fill"
        case "visited_oc":       return "globe.asia.australia.fill"
        case "visited_an":       return "snowflake"
        case "all_continents":   return "globe"
        default:
            switch badge.category {
            case "transport": return "airplane"
            case "continent": return "globe"
            default:          return "rosette"
            }
        }
    }
}

/// A number that counts up when it appears — adds life to stats.
struct CountUpText: View {
    let value: Double
    var suffix: String = ""
    var format: (Double) -> String = { String(Int($0)) }

    @State private var shown: Double = 0
    var body: some View {
        Text(format(shown) + suffix)
            .monospacedDigit()
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) { shown = value }
            }
            .onChange(of: value) { _, new in
                withAnimation(.easeOut(duration: 0.6)) { shown = new }
            }
    }
}
