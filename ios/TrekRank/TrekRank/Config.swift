import Foundation

enum Config {
    /// Base URL of the TrekRank API.
    ///
    /// Production points at the deployed Railway backend (used for App Store
    /// builds). For local development against a backend on this machine, switch
    /// to the localhost URL below (works on the iOS Simulator; use your LAN IP
    /// on a physical device).
    // Production (Railway) — used for device/TestFlight builds; reachable on any network.
    static let apiBaseURL = URL(string: "https://trekrank-production.up.railway.app/api/v1")!

    // Local development (Simulator on this Mac):
    // static let apiBaseURL = URL(string: "http://127.0.0.1:8001/api/v1")!
}
