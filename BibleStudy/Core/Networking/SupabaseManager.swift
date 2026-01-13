import Foundation
import Supabase
import Auth

// MARK: - Supabase Client
// Wrapper for Supabase SDK providing auth and database access

@MainActor
@Observable
final class SupabaseManager {
    // MARK: - Singleton
    static let shared = SupabaseManager()

    // MARK: - Properties
    let client: SupabaseClient

    var currentUser: User? {
        client.auth.currentUser
    }

    var isAuthenticated: Bool {
        currentUser != nil
    }

    var userId: String? {
        currentUser?.id.uuidString
    }

    // MARK: - Initialization
    private init() {
        client = SupabaseClient(
            supabaseURL: AppConfiguration.Supabase.url,
            supabaseKey: AppConfiguration.Supabase.anonKey,
            options: .init(
                auth: .init(
                    storage: AuthClient.Configuration.defaultLocalStorage,
                    autoRefreshToken: true,
                    emitLocalSessionAsInitialSession: true
                )
            )
        )
    }

    // MARK: - Auth Methods

    func signUp(email: String, password: String) async throws -> User {
        let response = try await client.auth.signUp(
            email: email,
            password: password,
            redirectTo: DeepLinkHandler.authCallbackURL
        )
        // Profile is automatically created by database trigger (handle_new_user)
        return response.user
    }

    /// Exchange an auth code for a session (used for email confirmation deep links)
    func exchangeCodeForSession(code: String) async throws {
        _ = try await client.auth.exchangeCodeForSession(authCode: code)
    }

    func signIn(email: String, password: String) async throws -> User {
        let session = try await client.auth.signIn(
            email: email,
            password: password
        )
        return session.user
    }

    func signInWithApple(idToken: String, nonce: String) async throws -> User {
        let session = try await client.auth.signInWithIdToken(
            credentials: .init(
                provider: .apple,
                idToken: idToken,
                nonce: nonce
            )
        )
        return session.user
    }

    func signOut() async throws {
        try await client.auth.signOut()
    }

    func resetPassword(email: String) async throws {
        try await client.auth.resetPasswordForEmail(email)
    }

    func resendConfirmation(email: String) async throws {
        try await client.auth.resend(email: email, type: .signup)
    }

    // MARK: - Session Management

    /// Get the current refresh token from the active session
    func getCurrentRefreshToken() -> String? {
        client.auth.currentSession?.refreshToken
    }

    /// Restore a session using a refresh token (for biometric quick sign-in)
    /// - Parameter refreshToken: The stored refresh token
    /// - Returns: The new session with updated tokens
    func restoreSession(refreshToken: String) async throws -> Session {
        try await client.auth.refreshSession(refreshToken: refreshToken)
    }

    // MARK: - Profile

    private func createProfile(for user: User) async throws {
        let profile = UserProfileDTO(
            id: user.id,
            displayName: nil,
            preferredTranslation: "KJV",
            fontSize: 18,
            theme: "system",
            devotionalModeEnabled: true
        )

        try await client
            .from("profiles")
            .insert(profile)
            .execute()
    }

    func getProfile() async throws -> UserProfileDTO? {
        guard let userId = userId else { return nil }

        let response: [UserProfileDTO] = try await client
            .from("profiles")
            .select()
            .eq("id", value: userId)
            .execute()
            .value

        return response.first
    }

    func updateProfile(_ updates: [String: AnyEncodable]) async throws {
        guard let userId = userId else { return }

        try await client
            .from("profiles")
            .update(updates)
            .eq("id", value: userId)
            .execute()
    }

    // MARK: - Highlights

    func getHighlights() async throws -> [HighlightDTO] {
        guard let userId = userId else { return [] }

        return try await client
            .from("highlights")
            .select()
            .eq("user_id", value: userId)
            .is("deleted_at", value: nil)
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    func getHighlights(for range: VerseRange) async throws -> [HighlightDTO] {
        guard let userId = userId else { return [] }

        return try await client
            .from("highlights")
            .select()
            .eq("user_id", value: userId)
            .eq("book_id", value: range.bookId)
            .eq("chapter", value: range.chapter)
            .gte("verse_start", value: range.verseStart)
            .lte("verse_end", value: range.verseEnd)
            .is("deleted_at", value: nil)
            .execute()
            .value
    }

    func createHighlight(_ highlight: HighlightDTO) async throws {
        try await client
            .from("highlights")
            .insert(highlight)
            .execute()
    }

    func deleteHighlight(id: String) async throws {
        try await client
            .from("highlights")
            .update(["deleted_at": AnyEncodable(Date())])
            .eq("id", value: id)
            .execute()
    }

    // MARK: - Notes

    func getNotes() async throws -> [NoteDTO] {
        guard let userId = userId else { return [] }

        return try await client
            .from("notes")
            .select()
            .eq("user_id", value: userId)
            .is("deleted_at", value: nil)
            .order("updated_at", ascending: false)
            .execute()
            .value
    }

    func getNotes(for range: VerseRange) async throws -> [NoteDTO] {
        guard let userId = userId else { return [] }

        return try await client
            .from("notes")
            .select()
            .eq("user_id", value: userId)
            .eq("book_id", value: range.bookId)
            .eq("chapter", value: range.chapter)
            .gte("verse_start", value: range.verseStart)
            .lte("verse_end", value: range.verseEnd)
            .is("deleted_at", value: nil)
            .execute()
            .value
    }

    func createNote(_ note: NoteDTO) async throws {
        try await client
            .from("notes")
            .insert(note)
            .execute()
    }

    func updateNote(id: String, content: String, template: String? = nil) async throws {
        var updates: [String: AnyEncodable] = [
            "content": AnyEncodable(content),
            "updated_at": AnyEncodable(Date())
        ]
        if let template = template {
            updates["template"] = AnyEncodable(template)
        }
        try await client
            .from("notes")
            .update(updates)
            .eq("id", value: id)
            .execute()
    }

    func deleteNote(id: String) async throws {
        try await client
            .from("notes")
            .update(["deleted_at": AnyEncodable(Date())])
            .eq("id", value: id)
            .execute()
    }

    // MARK: - Saved Prayers

    func getSavedPrayers() async throws -> [SavedPrayerDTO] {
        guard let userId = userId else { return [] }

        return try await client
            .from("saved_prayers")
            .select()
            .eq("user_id", value: userId)
            .is("deleted_at", value: nil)
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    func createSavedPrayer(_ prayer: SavedPrayerDTO) async throws {
        try await client
            .from("saved_prayers")
            .insert(prayer)
            .execute()
    }

    func deleteSavedPrayer(id: String) async throws {
        try await client
            .from("saved_prayers")
            .update(["deleted_at": AnyEncodable(Date())])
            .eq("id", value: id)
            .execute()
    }

    // MARK: - Topics

    func getTopics() async throws -> [TopicDTO] {
        try await client
            .from("topics")
            .select()
            .order("name")
            .execute()
            .value
    }

    // TODO: Re-enable once Swift 6 Sendable issues are resolved
    // nonisolated func searchTopics(embedding: [Float], limit: Int = 10) async throws -> [TopicDTO] {
    //     // Use RPC for vector similarity search
    //     let params = TopicSearchParams(query_embedding: embedding, match_count: limit)
    //     return try await client
    //         .rpc("search_topics", params: params)
    //         .execute()
    //         .value
    // }

    // MARK: - Sermons

    func getSermons() async throws -> [SermonDTO] {
        guard let userId = userId else { return [] }

        return try await client
            .from("sermons")
            .select()
            .eq("user_id", value: userId)
            .is("deleted_at", value: nil)
            .order("recorded_at", ascending: false)
            .execute()
            .value
    }

    func deleteSermon(id: String) async throws {
        try await client
            .from("sermons")
            .update(["deleted_at": AnyEncodable(Date())])
            .eq("id", value: id)
            .execute()
    }

    func uploadSermonAudio(data: Data, path: String, contentType: String = "audio/mp4") async throws -> String {
        _ = try await client.storage
            .from("sermons")
            .upload(path, data: data, options: .init(contentType: contentType))
        return path
    }

    func getSermonAudioURL(path: String, expiresIn: Int = 3600) async throws -> URL {
        let signedURL = try await client.storage
            .from("sermons")
            .createSignedURL(path: path, expiresIn: expiresIn)
        return signedURL
    }

    func getSermon(id: String) async throws -> SermonDTO? {
        guard userId != nil else { return nil }

        let result: [SermonDTO] = try await client
            .from("sermons")
            .select()
            .eq("id", value: id)
            .limit(1)
            .execute()
            .value
        return result.first
    }

    func upsertSermon(_ sermon: SermonDTO) async throws {
        try await client
            .from("sermons")
            .upsert(sermon)
            .execute()
    }

    func upsertSermonTranscript(_ transcript: SermonTranscriptDTO) async throws {
        try await client
            .from("sermon_transcripts")
            .upsert(transcript)
            .execute()
    }

    func upsertSermonStudyGuide(_ guide: SermonStudyGuideDTO) async throws {
        try await client
            .from("sermon_study_guides")
            .upsert(guide)
            .execute()
    }

    func upsertSermonBookmark(_ bookmark: SermonBookmarkDTO) async throws {
        try await client
            .from("sermon_bookmarks")
            .upsert(bookmark)
            .execute()
    }

    func deleteSermonBookmark(id: String) async throws {
        try await client
            .from("sermon_bookmarks")
            .update(["deleted_at": AnyEncodable(Date())])
            .eq("id", value: id)
            .execute()
    }
}

// MARK: - DTOs

struct UserProfileDTO: Codable {
    let id: UUID
    var displayName: String?
    var preferredTranslation: String
    var fontSize: Int
    var theme: String
    var devotionalModeEnabled: Bool
    var hasCompletedOnboarding: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case preferredTranslation = "preferred_translation"
        case fontSize = "font_size"
        case theme
        case devotionalModeEnabled = "devotional_mode_enabled"
        case hasCompletedOnboarding = "has_completed_onboarding"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        displayName = try container.decodeIfPresent(String.self, forKey: .displayName)
        preferredTranslation = try container.decodeIfPresent(String.self, forKey: .preferredTranslation) ?? "KJV"
        fontSize = try container.decodeIfPresent(Int.self, forKey: .fontSize) ?? 18
        theme = try container.decodeIfPresent(String.self, forKey: .theme) ?? "system"
        devotionalModeEnabled = try container.decodeIfPresent(Bool.self, forKey: .devotionalModeEnabled) ?? true
        hasCompletedOnboarding = try container.decodeIfPresent(Bool.self, forKey: .hasCompletedOnboarding) ?? false
    }

    init(id: UUID, displayName: String?, preferredTranslation: String, fontSize: Int, theme: String, devotionalModeEnabled: Bool, hasCompletedOnboarding: Bool = false) {
        self.id = id
        self.displayName = displayName
        self.preferredTranslation = preferredTranslation
        self.fontSize = fontSize
        self.theme = theme
        self.devotionalModeEnabled = devotionalModeEnabled
        self.hasCompletedOnboarding = hasCompletedOnboarding
    }
}

struct HighlightDTO: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let bookId: Int
    let chapter: Int
    let verseStart: Int
    let verseEnd: Int
    let color: String
    var category: String?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case bookId = "book_id"
        case chapter
        case verseStart = "verse_start"
        case verseEnd = "verse_end"
        case color
        case category
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct NoteDTO: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let bookId: Int
    let chapter: Int
    let verseStart: Int
    let verseEnd: Int
    var content: String
    var template: String?
    var linkedNoteIds: [UUID]?
    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case bookId = "book_id"
        case chapter
        case verseStart = "verse_start"
        case verseEnd = "verse_end"
        case content
        case template
        case linkedNoteIds = "linked_note_ids"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct TopicDTO: Codable, Identifiable {
    let id: UUID
    let slug: String
    let name: String
    let description: String?
    let level: Int

    var isTopLevel: Bool { level == 0 }
}

// MARK: - Errors

enum SupabaseError: Error, LocalizedError {
    case authFailed(String)
    case notAuthenticated
    case networkError(Error)
    case dataError(String)

    var errorDescription: String? {
        switch self {
        case .authFailed(let message):
            return "Authentication failed: \(message)"
        case .notAuthenticated:
            return "You must be signed in to perform this action"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .dataError(let message):
            return "Data error: \(message)"
        }
    }
}

// MARK: - AnyEncodable Helper
struct AnyEncodable: Encodable, @unchecked Sendable {
    private let _encode: @Sendable (Encoder) throws -> Void

    init<T: Encodable & Sendable>(_ value: T) {
        _encode = { encoder in
            try value.encode(to: encoder)
        }
    }

    func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }
}
