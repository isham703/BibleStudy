import SwiftUI

// MARK: - Account Detail View
// "Scribe's Sanctum" - Profile management with illuminated manuscript aesthetics

struct AccountDetailView: View {
    @Bindable var viewModel: SettingsViewModel
    @State private var showEditNameSheet = false
    @State private var editedName = ""
    @State private var showDeleteAccountInfo = false

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                // Profile Header
                profileHeader

                // Profile Section
                SettingsCard(title: "Profile", icon: "person.text.rectangle.fill") {
                    VStack(spacing: Theme.Spacing.md) {
                        editableNameRow

                        SettingsDivider()

                        // Email row (read-only)
                        emailRow
                    }
                }

                // Quick Access Section (if biometrics available)
                if viewModel.isBiometricAvailable {
                    SettingsCard(title: "Quick Access", icon: "bolt.fill") {
                        SettingsToggle(
                            isOn: Binding(
                                get: { viewModel.isBiometricEnabled },
                                set: { viewModel.isBiometricEnabled = $0 }
                            ),
                            label: viewModel.biometricType.displayName,
                            description: "Sign in quickly and securely",
                            icon: viewModel.biometricType.systemImage,
                            iconColor: Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme))
                        )
                    }
                }

                // Account Actions Section
                SettingsCard(title: "Account", icon: "gear", showDivider: false) {
                    VStack(spacing: Theme.Spacing.md) {
                        // Sign Out
                        signOutButton

                        SettingsDivider()

                        // Delete Account
                        deleteAccountRow
                    }
                }

                // Membership Footer
                membershipFooter
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.bottom, Theme.Spacing.xxl)
        }
        .background(Colors.Surface.background(for: ThemeMode.current(from: colorScheme)))
        .navigationTitle("Account")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showEditNameSheet) {
            EditNameSheet(
                name: $editedName,
                onSave: {
                    Task {
                        await viewModel.updateDisplayName(editedName)
                    }
                }
            )
        }
        .sheet(isPresented: $showDeleteAccountInfo) {
            DeleteAccountInfoSheet()
        }
        .confirmationDialog(
            "Sign Out",
            isPresented: $viewModel.showSignOutConfirmation,
            titleVisibility: .visible
        ) {
            Button("Sign Out", role: .destructive) {
                Task { await viewModel.signOut() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your highlights and notes will remain on your device.")
        }
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Illuminated Avatar
            ZStack {
                // Outer glow ring (pulses subtly)
                Circle()
                    .fill(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.light))
                    .blur(radius: 8)
                    .frame(width: 72, height: 72)

                // Inner gold gradient background
                Circle()
                    .fill(Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme)))
                    .frame(width: 56, height: 56)

                // Person icon
                Image(systemName: "person.fill")
                    .font(Typography.Icon.lg.weight(.medium))
                    .foregroundStyle(Colors.Semantic.onAccentAction(for: ThemeMode.current(from: colorScheme)))

                // Border
                Circle()
                    .stroke(
                        Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.subtle),
                        lineWidth: Theme.Stroke.hairline
                    )
                    .frame(width: 56, height: 56)
            }

            // Display Name (Cormorant Garamond, elegant)
            Text(viewModel.displayName ?? "Bible Student")
                .font(Typography.Command.meta)
                .foregroundStyle(Colors.Surface.textPrimary(for: ThemeMode.current(from: colorScheme)))

            // Email (system, subdued)
            if let email = viewModel.email {
                Text(email)
                    .font(Typography.Command.subheadline)
                    .foregroundStyle(Colors.Surface.textSecondary(for: ThemeMode.current(from: colorScheme)))
            }

            // Tier Badge
            tierBadge
        }
        .padding(.vertical, Theme.Spacing.xl)
    }

    // MARK: - Tier Badge

    private var tierBadge: some View {
        HStack(spacing: Theme.Spacing.xs) {
            // Decorative diamond
            Diamond()
                .fill(badgeColor)
                .frame(width: 24, height: 24)

            Text(viewModel.tierDisplayName.uppercased())
                .font(Typography.Command.meta.weight(.semibold))
                .tracking(2)

            Diamond()
                .fill(badgeColor)
                .frame(width: 24, height: 24)
        }
        .foregroundStyle(badgeColor)
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.xs)
        .background(
            Capsule()
                .fill(badgeColor.opacity(Theme.Opacity.faint))
                .overlay(
                    Capsule()
                        .stroke(badgeColor.opacity(Theme.Opacity.quarter), lineWidth: Theme.Stroke.hairline)
                )
        )
    }

    private var badgeColor: Color {
        switch viewModel.currentTier {
        case .free: return Colors.Surface.textSecondary(for: ThemeMode.current(from: colorScheme))
        case .premium, .scholar: return Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme))
        }
    }

    // MARK: - Editable Name Row

    private var editableNameRow: some View {
        Button(action: {
            editedName = viewModel.displayName ?? ""
            showEditNameSheet = true
        }) {
            HStack(spacing: Theme.Spacing.md) {
                // Quill icon
                Image(systemName: "pencil.line")
                    .font(Typography.Icon.sm.weight(.medium))
                    .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
                    .frame(width: 28, height: 28)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.Radius.input + 2)
                            .fill(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.faint + 0.02))
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text("Display Name")
                        .font(Typography.Command.body)
                        .foregroundStyle(Colors.Surface.textPrimary(for: ThemeMode.current(from: colorScheme)))

                    Text(viewModel.displayName ?? "Bible Student")
                        .font(Typography.Command.caption)
                        .foregroundStyle(Colors.Surface.textSecondary(for: ThemeMode.current(from: colorScheme)))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(Typography.Command.caption)
                    .foregroundStyle(Colors.Surface.textTertiary(for: ThemeMode.current(from: colorScheme)))
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Email Row

    private var emailRow: some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: "envelope.fill")
                .font(Typography.Icon.sm.weight(.medium))
                .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
                .frame(width: 28, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.input + 2)
                        .fill(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.faint + 0.02))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text("Email")
                    .font(Typography.Command.body)
                    .foregroundStyle(Colors.Surface.textPrimary(for: ThemeMode.current(from: colorScheme)))

                Text(viewModel.email ?? "Not available")
                    .font(Typography.Command.caption)
                    .foregroundStyle(Colors.Surface.textSecondary(for: ThemeMode.current(from: colorScheme)))
            }

            Spacer()
        }
    }

    // MARK: - Sign Out Button

    private var signOutButton: some View {
        Button(action: {
            viewModel.showSignOutConfirmation = true
        }) {
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(Typography.Icon.sm.weight(.medium))
                    .foregroundStyle(Colors.Semantic.error(for: ThemeMode.current(from: colorScheme)))
                    .frame(width: 28, height: 28)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.Radius.input + 2)
                            .fill(Colors.Semantic.error(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.faint + 0.02))
                    )

                Text("Sign Out")
                    .font(Typography.Command.body)
                    .foregroundStyle(Colors.Semantic.error(for: ThemeMode.current(from: colorScheme)))

                Spacer()

                if viewModel.isSigningOut {
                    ProgressView()
                        .scaleEffect(0.95)
                        .tint(Colors.Semantic.error(for: ThemeMode.current(from: colorScheme)))
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isSigningOut)
    }

    // MARK: - Delete Account Row

    private var deleteAccountRow: some View {
        Button(action: {
            showDeleteAccountInfo = true
        }) {
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: "exclamationmark.triangle")
                    .font(Typography.Icon.sm.weight(.medium))
                    .foregroundStyle(Colors.Surface.textTertiary(for: ThemeMode.current(from: colorScheme)))
                    .frame(width: 28, height: 28)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.Radius.input + 2)
                            .fill(Colors.Surface.divider(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.secondary))
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text("Delete Account")
                        .font(Typography.Command.body)
                        .foregroundStyle(Colors.Surface.textTertiary(for: ThemeMode.current(from: colorScheme)))

                    Text("Learn about data deletion")
                        .font(Typography.Command.caption)
                        .foregroundStyle(Colors.Surface.textTertiary(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.overlay))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(Typography.Command.caption)
                    .foregroundStyle(Colors.Surface.textTertiary(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.secondary))
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Membership Footer

    private var membershipFooter: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Rectangle()
                .fill(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.disabled))
                .frame(height: Theme.Stroke.hairline)

            Text("Member since \(memberSinceDate)")
                .font(Typography.Scripture.footnote.italic())
                .foregroundStyle(Colors.Surface.textTertiary(for: ThemeMode.current(from: colorScheme)))
        }
        .padding(.top, Theme.Spacing.xl)
    }

    private var memberSinceDate: String {
        // Get creation date from user metadata if available
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: Date())
    }
}

// MARK: - Edit Name Sheet

struct EditNameSheet: View {
    @Binding var name: String
    var onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.Spacing.xl) {
                // Header explanation
                Text("How would you like to be addressed?")
                    .font(Typography.Scripture.body)
                    .foregroundStyle(Colors.Surface.textSecondary(for: ThemeMode.current(from: colorScheme)))
                    .multilineTextAlignment(.center)
                    .padding(.top, Theme.Spacing.lg)

                // Text field with scribe styling
                TextField("Your name", text: $name)
                    .font(Typography.Scripture.heading)
                    .foregroundStyle(Colors.Surface.textPrimary(for: ThemeMode.current(from: colorScheme)))
                    .multilineTextAlignment(.center)
                    .focused($isFocused)
                    .padding(Theme.Spacing.lg)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.Radius.card)
                            .fill(Colors.Surface.surface(for: ThemeMode.current(from: colorScheme)))
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.Radius.card)
                                    .stroke(
                                        isFocused
                                            ? Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme))
                                            : Colors.Surface.divider(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.disabled),
                                        lineWidth: isFocused ? Theme.Stroke.control : Theme.Stroke.hairline
                                    )
                            )
                    )
                    .shadow(
                        color: isFocused
                            ? Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.faint)
                            : .clear,
                        radius: isFocused ? 8 : 0
                    )
                    .padding(.horizontal, Theme.Spacing.lg)
                    .animation(Theme.Animation.settle, value: isFocused)

                Spacer()
            }
            .padding(Theme.Spacing.lg)
            .background(Colors.Surface.background(for: ThemeMode.current(from: colorScheme)))
            .navigationTitle("Edit Name")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Colors.Surface.textSecondary(for: ThemeMode.current(from: colorScheme)))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
                    .disabled(name.isEmpty)
                }
            }
            .onAppear {
                isFocused = true
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Delete Account Info Sheet

struct DeleteAccountInfoSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var body: some View{
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    Text("Deleting Your Account")
                        .font(Typography.Scripture.heading)
                        .foregroundStyle(Colors.Surface.textPrimary(for: ThemeMode.current(from: colorScheme)))

                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        infoRow(
                            icon: "cloud.fill",
                            title: "Cloud Data",
                            description: "Your highlights, notes, and reading progress stored in the cloud will be permanently deleted."
                        )

                        infoRow(
                            icon: "iphone",
                            title: "Local Data",
                            description: "Data stored on this device will remain until you delete the app."
                        )

                        infoRow(
                            icon: "creditcard.fill",
                            title: "Subscriptions",
                            description: "Any active subscriptions must be cancelled separately through the App Store."
                        )
                    }

                    Text("To delete your account, please contact us at support@biblestudy.app with your request.")
                        .font(Typography.Command.body)
                        .foregroundStyle(Colors.Surface.textSecondary(for: ThemeMode.current(from: colorScheme)))
                        .padding(.top, Theme.Spacing.md)
                }
                .padding(Theme.Spacing.lg)
            }
            .background(Colors.Surface.background(for: ThemeMode.current(from: colorScheme)))
            .navigationTitle("Delete Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func infoRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.md) {
            Image(systemName: icon)
                .font(Typography.Icon.sm)
                .foregroundStyle(Colors.Surface.textSecondary(for: ThemeMode.current(from: colorScheme)))
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Typography.Command.body.weight(.semibold))
                    .foregroundStyle(Colors.Surface.textPrimary(for: ThemeMode.current(from: colorScheme)))

                Text(description)
                    .font(Typography.Command.caption)
                    .foregroundStyle(Colors.Surface.textSecondary(for: ThemeMode.current(from: colorScheme)))
            }
        }
    }
}

// MARK: - Preview

#Preview("Account Detail") {
    NavigationStack {
        AccountDetailView(viewModel: SettingsViewModel())
    }
}

#Preview("Edit Name Sheet") {
    EditNameSheet(name: .constant("Bible Student"), onSave: {})
}

#Preview("Delete Account Info") {
    DeleteAccountInfoSheet()
}
