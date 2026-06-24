import Foundation
import SwiftUI

/// User-selectable distance units. Persisted in UserDefaults via @AppStorage
/// (key "useMiles") so every screen reads the same preference.
enum DistanceUnit: String, CaseIterable, Identifiable {
    case kilometers, miles
    var id: String { rawValue }
    var label: String { self == .kilometers ? "Kilometers" : "Miles" }
    var short: String { self == .kilometers ? "km" : "mi" }
}

enum Units {
    static let storageKey = "useMiles"
    private static let kmToMiles = 0.621371

    static var current: DistanceUnit {
        UserDefaults.standard.bool(forKey: storageKey) ? .miles : .kilometers
    }

    /// Converts a value stored in km to the user's chosen unit.
    static func convert(km: Double) -> Double {
        current == .miles ? km * kmToMiles : km
    }

    /// "1,234 mi" / "1,234 km" — whole number with unit suffix.
    static func format(km: Double) -> String {
        "\(Int(convert(km: km).rounded())) \(current.short)"
    }

    /// Just the converted numeric value (for CountUpText), plus the unit suffix.
    static func value(km: Double) -> Double { convert(km: km) }
    static var suffix: String { " " + current.short }
}
