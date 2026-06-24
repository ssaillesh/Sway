import SwiftUI

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var badges: [Badge] = []
    @Published var shareURL: URL?
    @Published var generatingCard = false

    func load() async {
        badges = (try? await APIClient.shared.badges()) ?? []
    }

    func makeShareCard() async {
        generatingCard = true
        if let resp = try? await APIClient.shared.shareCard(year: Calendar.current.component(.year, from: Date())) {
            shareURL = URL(string: resp.imageUrl)
        }
        generatingCard = false
    }
}

struct ProfileView: View {
    @EnvironmentObject var session: SessionStore
    @StateObject private var vm = ProfileViewModel()
    @State private var showSettings = false
    @AppStorage(Units.storageKey) private var useMiles = false  // re-render on unit change

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    header
                    statsGrid
                    shareSection
                    badgesSection
                }
                .padding()
            }
            .trekScreen()
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape.fill").foregroundStyle(TrekTheme.accent)
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView().environmentObject(session)
            }
            .task { await session.refreshProfile(); await vm.load() }
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Circle()
                .fill(LinearGradient(colors: [TrekTheme.accent, TrekTheme.accent2],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 86, height: 86)
                .overlay(Text(String((session.profile?.username ?? "?").prefix(1)).uppercased())
                    .font(.largeTitle.bold()).foregroundStyle(.black))
                .shadow(color: TrekTheme.accent.opacity(0.5), radius: 16)
            Text(session.profile?.displayName ?? "").font(.title2.bold())
            Text("@\(session.profile?.username ?? "")").foregroundStyle(.secondary)
        }
    }

    private var statsGrid: some View {
        let p = session.profile
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCard(value: Double(p?.totalCountries ?? 0), label: "Countries", icon: "globe")
            StatCard(value: Double(p?.totalCities ?? 0), label: "Cities", icon: "building.2")
            StatCard(value: Units.value(km: p?.totalKm ?? 0), suffix: Units.suffix,
                     label: "Distance", icon: "ruler")
            StatCard(value: Double(p?.totalTrips ?? 0), label: "Trips", icon: "airplane")
            StatCard(value: Double(p?.currentStreak ?? 0), label: "Current streak", icon: "flame")
            StatCard(value: Double(p?.longestStreak ?? 0), label: "Longest streak", icon: "crown")
        }
    }

    private var shareSection: some View {
        VStack(spacing: 10) {
            Button {
                Task { await vm.makeShareCard() }
            } label: {
                HStack {
                    if vm.generatingCard { ProgressView().tint(.black) }
                    Label("Generate share card", systemImage: "square.and.arrow.up")
                }
            }
            .buttonStyle(NeonButtonStyle())
            if let url = vm.shareURL {
                AsyncImage(url: url) { img in
                    img.resizable().scaledToFit().clipShape(RoundedRectangle(cornerRadius: 16))
                } placeholder: { ProgressView() }
                .frame(maxHeight: 360)
            }
        }
    }

    private var badgesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Badges").font(.title3.bold())
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(vm.badges) { badge in
                    HStack {
                        Image(systemName: badge.earned ? "rosette" : "lock.fill")
                            .foregroundStyle(badge.earned ? TrekTheme.accent : .secondary)
                        VStack(alignment: .leading) {
                            Text(badge.name).font(.subheadline.bold())
                            Text(badge.description).font(.caption2).foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                        Spacer()
                    }
                    .padding(10)
                    .background(.gray.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .opacity(badge.earned ? 1 : 0.5)
                }
            }
        }
    }
}

struct StatCard: View {
    let value: Double
    var suffix: String = ""
    let label: String
    let icon: String
    var body: some View {
        GlassCard {
            VStack(spacing: 6) {
                Image(systemName: icon).foregroundStyle(TrekTheme.accent).font(.title3)
                CountUpText(value: value, suffix: suffix).font(.title2.bold())
                Text(label).font(.caption).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
    }
}
