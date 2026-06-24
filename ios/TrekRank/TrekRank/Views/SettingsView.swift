import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var session: SessionStore
    @Environment(\.dismiss) private var dismiss
    @AppStorage(Units.storageKey) private var useMiles = false
    @State private var showDeleteConfirm = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Account") {
                    NavigationLink {
                        EditEmailView().environmentObject(session)
                    } label: {
                        row("envelope", "Email", value: session.profile?.email ?? "—")
                    }
                    NavigationLink {
                        ChangePasswordView().environmentObject(session)
                    } label: {
                        row("lock", "Change password")
                    }
                }

                Section("Preferences") {
                    Picker(selection: $useMiles) {
                        Text("Kilometers").tag(false)
                        Text("Miles").tag(true)
                    } label: {
                        Label("Distance units", systemImage: "ruler")
                    }
                    .pickerStyle(.menu)
                }

                Section {
                    Button(role: .destructive) { showDeleteConfirm = true } label: {
                        HStack {
                            if session.isLoading { ProgressView() }
                            Label("Delete account", systemImage: "trash")
                        }
                    }
                } header: {
                    Text("Danger zone")
                } footer: {
                    Text("Permanently deletes your account and all trips, photos, badges, and stats. This cannot be undone.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(ScreenBackground())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
            .alert("Delete account?", isPresented: $showDeleteConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Delete permanently", role: .destructive) {
                    Task { await session.deleteAccount() }
                }
            } message: {
                Text("This permanently erases your account and all associated data. This cannot be undone.")
            }
        }
    }

    private func row(_ icon: String, _ title: String, value: String? = nil) -> some View {
        HStack {
            Label(title, systemImage: icon)
            Spacer()
            if let value { Text(value).foregroundStyle(.secondary).lineLimit(1) }
        }
    }
}

struct EditEmailView: View {
    @EnvironmentObject var session: SessionStore
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var saved = false

    var body: some View {
        Form {
            Section("Email address") {
                TextField("you@email.com", text: $email)
                    .textInputAutocapitalization(.never).autocorrectionDisabled()
                    .keyboardType(.emailAddress)
            }
            Section {
                Button {
                    Task {
                        if await session.updateEmail(email.trimmingCharacters(in: .whitespaces)) {
                            saved = true; dismiss()
                        }
                    }
                } label: {
                    HStack { if session.isLoading { ProgressView() }; Text("Save email") }
                }
                .disabled(email.isEmpty || session.isLoading)
            }
            if let err = session.errorMessage {
                Section { Text(err).font(.footnote).foregroundStyle(.red) }
            }
        }
        .scrollContentBackground(.hidden)
        .background(ScreenBackground())
        .navigationTitle("Email")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { email = session.profile?.email ?? ""; session.errorMessage = nil }
    }
}

struct ChangePasswordView: View {
    @EnvironmentObject var session: SessionStore
    @Environment(\.dismiss) private var dismiss
    @State private var current = ""
    @State private var newPassword = ""
    @State private var confirm = ""

    private var valid: Bool {
        !current.isEmpty && newPassword.count >= 6 && newPassword == confirm
    }

    var body: some View {
        Form {
            Section("Current password") {
                SecureField("Current password", text: $current)
            }
            Section("New password") {
                SecureField("New password (min 6 chars)", text: $newPassword)
                SecureField("Confirm new password", text: $confirm)
            }
            if !confirm.isEmpty && newPassword != confirm {
                Section { Text("Passwords don't match.").font(.footnote).foregroundStyle(.red) }
            }
            Section {
                Button {
                    Task {
                        if await session.changePassword(current: current, newPassword: newPassword) {
                            dismiss()
                        }
                    }
                } label: {
                    HStack { if session.isLoading { ProgressView() }; Text("Update password") }
                }
                .disabled(!valid || session.isLoading)
            }
            if let err = session.errorMessage {
                Section { Text(err).font(.footnote).foregroundStyle(.red) }
            }
        }
        .scrollContentBackground(.hidden)
        .background(ScreenBackground())
        .navigationTitle("Password")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { session.errorMessage = nil }
    }
}
