import SwiftUI

// MARK: - Account Detail View
// "Scribe's Sanctum" - Profile management with illuminated manuscript aesthetics

struct AccountDetailView: View {
    @Bindable var viewModel: SettingsViewModel
    @State private var showEditNameSheet = false
    @State private var editedName = ""
    @State private var showDeleteAccountInfo = false

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.lg) {
                // Profile Header
                profileHeader

                // Profile Section
                IlluminatedSettingsCard(title: "Profile", icon: "person.text.rectangle.fill") {
                    VStack(spacing: AppTheme.Spacing.md) {
                        editableNameRow

                        SettingsDivider()

                        // Email row (read-only)
                        emailRow
                    }
                }

                // Quick Access Section (if biometrics available)
                if viewModel.isBiometricAvailable {
                    IlluminatedSettingsCard(title: "Quick Access", icon: "bolt.fill") {
                        IlluminatedToggle(
                            isOn: Binding(
                                get: { viewModel.isBiometricEnabled },
                                set: { viewModel.isBiometricEnabled = $0 }
                            ),
                            label: viewModel.biometricType.displayName,
                            description: "Sign in quickly and securely",
                            icon: viewModel.biometricType.systemImage,
                            iconColor: .scholarAccent
                        )
                    }
                }

                // Account Actions Section
                IlluminatedSettingsCard(title: "Account", icon: "gear", showDivider: false) {
                    VStack(spacing: AppTheme.Spacing.md) {
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
            .padding(.horizontal, AppTheme.Spacing.lg)
            .padding(.bottom, AppTheme.Spacing.xxl)
        }
        .background(Color.appBackground)
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
        VStack(spacing: AppTheme.Spacing.md) {
            // Illuminated Avatar
            ZStack {
                // Outer glow ring (pulses subtly)
                Circle()
                    .fill(Color.scholarAccent.opacity(AppTheme.Opacity.light))
                    .blur(radius: AppTheme.Blur.medium)
                    .frame(width: 72, height: 72)

                // Inner gold gradient background
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.illuminatedGold,
                                Color.divineGold,
                                Color.burnishedGold
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)

                // Person icon
                Image(systemName: "person.fill")
                    .font(Typography.UI.iconLg.weight(.medium))
                    .foregroundStyle(.white)

                // Gold border with shimmer
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.illuminatedGold,
                                Color.divineGold.opacity(AppTheme.Opacity.strong),
                                Color.illuminatedGold
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: AppTheme.Border.regular
                    )
                    .frame(width: 56, height: 56)
            }

            // Display Name (Cormorant Garamond, elegant)
            Text(viewModel.displayName ?? "Bible Student")
                .font(Typography.Codex.verseReference)
                .foregroundStyle(Color.primaryText)

            // Email (system, subdued)
            if let email = viewModel.email {
                Text(email)
                    .font(Typography.UI.subheadline)
                    .foregroundStyle(Color.secondaryText)
            }

            // Tier Badge
            tierBadge
        }
        .padding(.vertical, AppTheme.Spacing.xl)
    }

    // MARK: - Tier Badge

    private var tierBadge: some View {
        HStack(spacing: AppTheme.Spacing.xs) {
            // Decorative diamond
            Diamond()
                .fill(badgeColor)
                .frame(width: AppTheme.ComponentSize.dotSmall, height: AppTheme.ComponentSize.dotSmall)

            Text(viewModel.tierDisplayName.uppercased())
                .font(Typography.UI.caption2.weight(.semibold))
                .tracking(2)

            Diamond()
                .fill(badgeColor)
                .frame(width: AppTheme.ComponentSize.dotSmall, height: AppTheme.ComponentSize.dotSmall)
        }
        .foregroundStyle(badgeColor)
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.xs)
        .background(
            Capsule()
                .fill(badgeColor.opacity(AppTheme.Opacity.subtle))
                .overlay(
                    Capsule()
                        .stroke(badgeColor.opacity(AppTheme.Opacity.quarter), lineWidth: AppTheme.Border.thin)
                )
        )
    }

    private var badgeColor: Color {
        switch viewModel.currentTier {
        case .free: return Color.secondaryText
        case .premium, .scholar: return Color.scholarAccent
        }
    }

    // MARK: - Editable Name Row

    private var editableNameRow: some View {
        Button(action: {
            editedName = viewModel.displayName ?? ""
            showEditNameSheet = true
        }) {
            HStack(spacing: AppTheme.Spacing.md) {
                // Quill icon
                Image(systemName: "pencil.line")
                    .font(Typography.UI.iconSm.weight(.medium))
                    .foregroundStyle(Color.scholarAccent)
                    .frame(width: 28, height: 28)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small + 2)
                            .fill(Color.scholarAccent.opacity(AppTheme.Opacity.subtle + 0.02))
                    )

                VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                    Text("Display Name")
                        .font(Typography.UI.body)
                        .foregroundStyle(Color.primaryText)

                    Text(viewModel.displayName ?? "Bible Student")
                        .font(Typography.UI.caption1)
                        .foregroundStyle(Color.secondaryText)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(Typography.UI.caption1)
                    .foregroundStyle(Color.tertiaryText)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Email Row

    private var emailRow: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: "envelope.fill")
                .font(Typography.UI.iconSm.weight(.medium))
                .foregroundStyle(Color.lapisLazuli)
                .frame(width: 28, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small + 2)
                        .fill(Color.lapisLazuli.opacity(AppTheme.Opacity.subtle + 0.02))
                )

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                Text("Email")
                    .font(Typography.UI.body)
                    .foregroundStyle(Color.primaryText)

                Text(viewModel.email ?? "Not available")
                    .font(Typography.UI.caption1)
                    .foregroundStyle(Color.secondaryText)
            }

            Spacer()
        }
    }

    // MARK: - Sign Out Button

    private var signOutButton: some View {
        Button(action: {
            viewModel.showSignOutConfirmation = true
        }) {
            HStack(spacing: AppTheme.Spacing.md) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(Typography.UI.iconSm.weight(.medium))
                    .foregroundStyle(Color.vermillion)
                    .frame(width: 28, height: 28)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small + 2)
                            .fill(Color.vermillion.opacity(AppTheme.Opacity.subtle + 0.02))
                    )

                Text("Sign Out")
                    .font(Typography.UI.body)
                    .foregroundStyle(Color.vermillion)

                Spacer()

                if viewModel.isSigningOut {
                    ProgressView()
                        .scaleEffect(AppTheme.Scale.reduced)
                        .tint(Color.vermillion)
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
            HStack(spacing: AppTheme.Spacing.md) {
                Image(systemName: "exclamationmark.triangle")
                    .font(Typography.UI.iconSm.weight(.medium))
                    .foregroundStyle(Color.tertiaryText)
                    .frame(width: 28, height: 28)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small + 2)
                            .fill(Color.divider.opacity(AppTheme.Opacity.heavy))
                    )

                VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                    Text("Delete Account")
                        .font(Typography.UI.body)
                        .foregroundStyle(Color.tertiaryText)

                    Text("Learn about data deletion")
                        .font(Typography.UI.caption1)
                        .foregroundStyle(Color.tertiaryText.opacity(AppTheme.Opacity.overlay))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(Typography.UI.caption1)
                    .foregroundStyle(Color.tertiaryText.opacity(AppTheme.Opacity.heavy))
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Membership Footer

    private var membershipFooter: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            OrnamentalDivider(style: .sectionBreak, color: Color.scholarAccent.opacity(AppTheme.Opacity.disabled))

            Text("Member since \(memberSinceDate)")
                .font(Typography.Codex.italicTiny)
                .foregroundStyle(Color.tertiaryText)
        }
        .padding(.top, AppTheme.Spacing.xl)
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
    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: AppTheme.Spacing.xl) {
                // Header explanation
                Text("How would you like to be addressed?")
                    .font(Typography.Codex.body)
                    .foregroundStyle(Color.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.top, AppTheme.Spacing.lg)

                // Text field with scribe styling
                TextField("Your name", text: $name)
                    .font(Typography.Display.title2)
                    .foregroundStyle(Color.primaryText)
                    .multilineTextAlignment(.center)
                    .focused($isFocused)
                    .padding(AppTheme.Spacing.lg)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
                            .fill(Color.surfaceBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
                                    .stroke(
                                        isFocused
                                            ? Color.scholarAccent
                                            : Color.cardBorder.opacity(AppTheme.Opacity.disabled),
                                        lineWidth: isFocused ? AppTheme.Border.regular : AppTheme.Border.thin
                                    )
                            )
                    )
                    .shadow(
                        color: isFocused
                            ? Color.scholarAccent.opacity(AppTheme.Opacity.subtle)
                            : .clear,
                        radius: isFocused ? AppTheme.Blur.medium : 0
                    )
                    .padding(.horizontal, AppTheme.Spacing.lg)
                    .animation(AppTheme.Animation.sacredSpring, value: isFocused)

                Spacer()
            }
            .padding(AppTheme.Spacing.lg)
            .background(Color.appBackground)
            .navigationTitle("Edit Name")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.secondaryText)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.scholarAccent)
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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                    Text("Deleting Your Account")
                        .font(Typography.Display.title2)
                        .foregroundStyle(Color.primaryText)

                    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
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
                        .font(Typography.UI.body)
                        .foregroundStyle(Color.secondaryText)
                        .padding(.top, AppTheme.Spacing.md)
                }
                .padding(AppTheme.Spacing.lg)
            }
            .background(Color.appBackground)
            .navigationTitle("Delete Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.scholarAccent)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func infoRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
            Image(systemName: icon)
                .font(Typography.UI.iconSm)
                .foregroundStyle(Color.secondaryText)
                .frame(width: AppTheme.IconSize.small)

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                Text(title)
                    .font(Typography.UI.bodyBold)
                    .foregroundStyle(Color.primaryText)

                Text(description)
                    .font(Typography.UI.caption1)
                    .foregroundStyle(Color.secondaryText)
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
