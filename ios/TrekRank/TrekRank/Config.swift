import Foundation

enum Config {
    /// Base URL of the TrekRank API.
    ///
    /// Production points at the deployed Railway backend (used for App Store
    /// builds). For local development against a backend on this machine, switch
    /// to the localhost URL below (works on the iOS Simulator; use your LAN IP
    /// on a physical device).
    // Local development (talks to the backend on this Mac — has the seeded demo
    // users + 100-user leaderboard). Simulator reaches the Mac via 127.0.0.1.
    static let apiBaseURL = URL(string: "http://127.0.0.1:8001/api/v1")!

    // Production (Railway) — switch back to this for real/App Store builds:
    // static let apiBaseURL = URL(string: "https://trekrank-production.up.railway.app/api/v1")!
}
