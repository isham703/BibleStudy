import SwiftUI

// MARK: - AI Feature
// Navigation model for AI-powered Bible study experiences
// Used by Sanctuary views and Sacred Threshold to navigate to experiences

enum AIFeature: String, CaseIterable, Identifiable {
    case scriptureFindsYou = "Scripture Finds You"
    case theApprentice = "The Apprentice"
    case illuminate = "Illuminate"
    case theThread = "The Thread"
    case prayersFromDeep = "The Portico"
    case memoryPalace = "Memory Palace"
    case compline = "Compline"
    case breathe = "Breathe"
    case sermonRecording = "Sermon Recording"

    var id: String { rawValue }
    var title: String { rawValue }

    // MARK: - Display Properties

    var subtitle: String {
        switch self {
        case .scriptureFindsYou: return "Context-aware verses that surface when you need them"
        case .theApprentice: return "Your personal AI study companion that grows with you"
        case .illuminate: return "AI-generated sacred art for any verse"
        case .theThread: return "Conversations with historical figures about scripture"
        case .prayersFromDeep: return "AI-crafted prayers for your intentions"
        case .memoryPalace: return "Visual journeys for scripture memorization"
        case .compline: return "AI-led evening prayer experience"
        case .breathe: return "Guided breathing exercises for peace and rest"
        case .sermonRecording: return "Record sermons and generate AI study guides"
        }
    }

    var icon: String {
        switch self {
        case .scriptureFindsYou: return "sparkle.magnifyingglass"
        case .theApprentice: return "bubble.left.and.bubble.right.fill"
        case .illuminate: return "paintpalette.fill"
        case .theThread: return "person.2.wave.2.fill"
        case .prayersFromDeep: return "building.columns"
        case .memoryPalace: return "building.columns.fill"
        case .compline: return "moon.stars.fill"
        case .breathe: return "wind"
        case .sermonRecording: return "waveform.circle.fill"
        }
    }

    var gradientColors: [Color] {
        switch self {
        case .scriptureFindsYou: return [Color("FeedbackInfo"), Color("FeedbackInfo")]
        case .theApprentice: return [Color("FeedbackWarning"), Color("FeedbackError")]
        case .illuminate: return [Color("AccentBronze"), Color("AppAccentAction")]
        case .theThread: return [Color("FeedbackSuccess"), Color("FeedbackSuccess")]
        case .prayersFromDeep: return [Color("HighlightBlue"), Color("HighlightBlue").opacity(0.8)]
        case .memoryPalace: return [Color("FeedbackSuccess"), Color("FeedbackInfo")]
        case .compline: return [Color("AppAccentAction"), Color("AppAccentAction")]
        case .breathe: return [Color("AppAccentAction"), Color("AppAccentAction")]
        case .sermonRecording: return [Color("AccentBronze"), Color("FeedbackWarning")]
        }
    }

    // MARK: - Card Labels (for Sanctuary views)

    var cardLabel: String {
        switch self {
        case .scriptureFindsYou: return "DISCOVER"
        case .theApprentice: return "COMPANION"
        case .illuminate: return "ART"
        case .theThread: return "DIALOGUE"
        case .prayersFromDeep: return "PORTICO"
        case .memoryPalace: return "MEMORY"
        case .compline: return "COMPLINE"
        case .breathe: return "BREATHE"
        case .sermonRecording: return "SERMON"
        }
    }

    var cardTitle: String {
        switch self {
        case .scriptureFindsYou: return "Scripture Finds You"
        case .theApprentice: return "The Apprentice"
        case .illuminate: return "Illuminate"
        case .theThread: return "The Thread"
        case .prayersFromDeep: return "The Portico"
        case .memoryPalace: return "Memory Palace"
        case .compline: return "Compline"
        case .breathe: return "Breathe"
        case .sermonRecording: return "Sermon Recording"
        }
    }

    var cardSubtitle: String {
        switch self {
        case .scriptureFindsYou: return "Discover timely verses"
        case .theApprentice: return "Your study companion"
        case .illuminate: return "Sacred visual art"
        case .theThread: return "Conversations with history"
        case .prayersFromDeep: return "AI-crafted prayers"
        case .memoryPalace: return "Memorize Psalm 23"
        case .compline: return "Begin your evening prayer"
        case .breathe: return "Find your calm"
        case .sermonRecording: return "Record & transcribe"
        }
    }

    // MARK: - Navigation Destination

    @ViewBuilder
    var destinationView: some View {
        switch self {
        case .prayersFromDeep:
            PrayersFromDeepView()
        case .compline:
            ComplineView()
        case .breathe:
            BreatheView()
        case .sermonRecording:
            SermonView()
        default:
            // Placeholder for features not yet implemented
            AIFeaturePlaceholderView(feature: self)
        }
    }
}

// MARK: - Placeholder View

/// Placeholder for AI features until production implementation
struct AIFeaturePlaceholderView: View {
    let feature: AIFeature

    var body: some View {
        ZStack {
            LinearGradient(
                colors: feature.gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // swiftlint:disable:next hardcoded_stack_spacing
            VStack(spacing: 24) {  // Feature card layout spacing
                Image(systemName: feature.icon)
                    // swiftlint:disable:next hardcoded_font_system
                    .font(Typography.Icon.display)
                    .foregroundStyle(.white.opacity(Theme.Opacity.textPrimary))

                Text(feature.title)
                    // swiftlint:disable:next hardcoded_swiftui_text_style
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                Text(feature.subtitle)
                    // swiftlint:disable:next hardcoded_swiftui_text_style
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(Theme.Opacity.pressed))
                    .multilineTextAlignment(.center)
                    // swiftlint:disable:next hardcoded_padding_edge
                    .padding(.horizontal, 40)

                Text("Coming Soon")
                    // swiftlint:disable:next hardcoded_swiftui_text_style
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.white.opacity(Theme.Opacity.textPrimary))
                    .padding(.top, Theme.Spacing.sm)
            }
        }
    }
}

// MARK: - Feature Sets for Different Times

extension AIFeature {
    /// Features shown in Dawn Sanctuary (morning devotion focus)
    static var dawnFeatures: [AIFeature] {
        [.prayersFromDeep, .memoryPalace, .scriptureFindsYou, .theApprentice]
    }

    /// Features shown in Meridian Sanctuary (study focus)
    static var meridianFeatures: [AIFeature] {
        [.sermonRecording, .prayersFromDeep, .memoryPalace, .scriptureFindsYou]
    }

    /// Features shown in Afternoon Sanctuary (contemplation focus)
    static var afternoonFeatures: [AIFeature] {
        [.sermonRecording, .prayersFromDeep, .memoryPalace, .scriptureFindsYou]
    }

    /// Features shown in Vespers Sanctuary (evening reflection focus)
    static var vespersFeatures: [AIFeature] {
        [.prayersFromDeep, .compline, .breathe, .memoryPalace]
    }

    /// Features shown in Compline Sanctuary (night prayer focus)
    static var complineFeatures: [AIFeature] {
        [.compline, .breathe, .prayersFromDeep, .memoryPalace]
    }

    /// Features for Sacred Threshold rooms
    static var thresholdFeatures: [AIFeature] {
        [.memoryPalace, .prayersFromDeep, .compline, .breathe]
    }
}
