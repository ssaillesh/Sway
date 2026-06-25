import SwiftUI
import CoreLocation

struct AddTripView: View {
    @Environment(\.dismiss) private var dismiss
    var onSaved: () async -> Void

    @State private var title = ""
    @State private var originCity = ""
    @State private var originCountry = ""
    @State private var destCity = ""
    @State private var destCountry = ""
    @State private var transport = "flight"
    @State private var startDate = Date()
    @State private var saving = false
    @State private var error: String?

    private let transports = ["flight", "train", "car", "bus", "boat", "bike", "walk", "other"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Trip") {
                    TextField("Title (optional)", text: $title)
                    Picker("Transport", selection: $transport) {
                        ForEach(transports, id: \.self) { Text($0.capitalized).tag($0) }
                    }
                    DatePicker("Start date", selection: $startDate, displayedComponents: .date)
                }
                Section("From (optional)") {
                    TextField("Origin city", text: $originCity)
                    TextField("Origin country (ISO-2, e.g. CA)", text: $originCountry)
                        .textInputAutocapitalization(.characters)
                }
                Section("To") {
                    TextField("Destination city", text: $destCity)
                    TextField("Destination country (ISO-2, e.g. JP)", text: $destCountry)
                        .textInputAutocapitalization(.characters)
                }
                if let error { Text(error).foregroundStyle(.red).font(.caption) }
            }
            .scrollContentBackground(.hidden)
            .background(ScreenBackground())
            .navigationTitle("New Trip")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(destCity.isEmpty || destCountry.count != 2 || saving)
                }
            }
        }
    }

    private func save() {
        saving = true; error = nil
        let fmt = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd"
        Task {
            // Resolve coordinates on-device so the server can skip its slow
            // geocoding and compute the distance immediately. If a lookup
            // fails, we just omit the coords and the server falls back to its
            // own geocoding — no worse than before.
            let dest = await Self.geocode(city: destCity, country: destCountry.uppercased())
            let origin = originCity.isEmpty
                ? nil
                : await Self.geocode(city: originCity, country: originCountry.uppercased())

            let body = CreateTripBody(
                title: title.isEmpty ? nil : title,
                originCity: originCity.isEmpty ? nil : originCity,
                originCountry: originCountry.isEmpty ? nil : originCountry.uppercased(),
                destCity: destCity, destCountry: destCountry.uppercased(),
                transportMode: transport, startDate: fmt.string(from: startDate),
                endDate: nil, notes: nil,
                originLat: origin?.latitude, originLng: origin?.longitude,
                destLat: dest?.latitude, destLng: dest?.longitude)
            do {
                _ = try await APIClient.shared.createTrip(body)
                await onSaved()
                dismiss()
            } catch {
                self.error = (error as? APIError)?.errorDescription ?? error.localizedDescription
            }
            saving = false
        }
    }

    /// Resolve a "City, COUNTRY" string to coordinates using Apple's on-device
    /// geocoder. Returns nil if it can't be resolved (caller then lets the
    /// server geocode instead).
    private static func geocode(city: String, country: String) async -> CLLocationCoordinate2D? {
        let query = country.isEmpty ? city : "\(city), \(country)"
        let coder = CLGeocoder()
        return await withCheckedContinuation { cont in
            coder.geocodeAddressString(query) { placemarks, _ in
                _ = coder // keep the geocoder alive until completion
                cont.resume(returning: placemarks?.first?.location?.coordinate)
            }
        }
    }
}
