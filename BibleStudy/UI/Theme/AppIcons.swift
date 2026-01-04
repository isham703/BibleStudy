import SwiftUI

// MARK: - App Icons Registry
// Central registry for all app icons
// Provides semantic naming and easy switching between SF Symbols and Streamline assets
//
// Usage:
//   Image(systemName: AppIcons.TabBar.home)
//   IlluminatedIcon(systemName: AppIcons.Study.notes, size: 20)

enum AppIcons {

    // MARK: - Tab Bar Icons
    // Highest visibility - using Streamline icons where available

    enum TabBar {
        /// Home tab - church with rays (Streamline Pentecost)
        static let home = "streamline-home"  // Streamline asset

        /// Read tab - Bible (Streamline Religion-Bible)
        static let read = "streamline-read"  // Streamline asset

        /// Scholar tab - scholar's reader (Streamline Scholar)
        static let scholar = "streamline-scholar"  // Streamline asset

        /// Ask tab - AI chat with sparkle (Streamline Ai-Chat-Spark)
        static let ask = "streamline-ask"  // Streamline asset

        // MARK: Streamline Alternatives (uncomment when assets added)
        // static let homeStreamline = "streamline-temple"
        // static let readStreamline = "streamline-bible"
        // static let askStreamline = "streamline-lamp"
    }

    // MARK: - Study Section Icons
    // High visibility in Study tab - using Streamline icons

    enum Study {
        /// Notes section - quill on parchment (Streamline Common-File-Quill)
        static let notes = "streamline-notes"  // Streamline asset

        /// Highlights section - ink brush (Streamline Design-Tool-Glue)
        static let highlights = "streamline-highlights"  // Streamline asset

        /// Stories section - books on shelf (Streamline Book-Library-1)
        static let stories = "streamline-stories"  // Streamline asset

        /// Topics section - organized topics (Streamline Topic-Organize)
        static let topics = "streamline-topics"  // Streamline asset

        /// Word Study section - character book (SF Symbol, no Streamline equivalent)
        static let words = "character.book.closed"  // SF Symbol
    }

    // MARK: - Action Icons
    // Selection toolbar and contextual actions - using Streamline where available

    enum Action {
        /// Copy action (Streamline Copy-1)
        static let copy = "streamline-copy"  // Streamline asset

        /// Share action (Streamline Share-2)
        static let share = "streamline-share"  // Streamline asset

        /// Study/insights action (Streamline Book-Library-1)
        static let study = "streamline-study"  // Streamline asset

        /// Highlight action - paint brush (Streamline Color-Brush-Paint)
        static let highlight = "streamline-highlight"  // Streamline asset

        /// Add note action - quill (Streamline Common-File-Quill)
        static let note = "streamline-note"  // Streamline asset

        /// Memorize action - brain (Streamline Brain-1)
        static let memorize = "streamline-memorize"  // Streamline asset

        /// Add to collection - archive (Streamline Archive)
        static let collection = "streamline-collection"  // Streamline asset

        /// More options (SF Symbol - standard UI)
        static let more = "ellipsis"  // SF Symbol

        /// Clear/dismiss (SF Symbol - standard UI)
        static let clear = "xmark.circle.fill"  // SF Symbol

        /// Delete action (SF Symbol - standard destructive)
        static let delete = "trash"  // SF Symbol

        /// Edit action (SF Symbol - standard UI)
        static let edit = "pencil"  // SF Symbol

        /// Bookmark action (SF Symbol)
        static let bookmark = "bookmark.fill"  // SF Symbol

        /// Favorite/heart action (SF Symbol)
        static let favorite = "heart.fill"  // SF Symbol
    }

    // MARK: - Navigation Icons
    // Mix of Streamline and SF Symbols for system conventions

    enum Navigation {
        /// Settings - sliders (Streamline Settings-Slider)
        static let settings = "streamline-settings"  // Streamline asset

        /// Search - universal (SF Symbol)
        static let search = "magnifyingglass"  // SF Symbol

        /// History - clock with arrow (Streamline Synchronize-Arrow-Clock)
        static let history = "streamline-history"  // Streamline asset

        /// Back navigation (SF Symbol - system convention)
        static let back = "chevron.left"  // SF Symbol

        /// Forward navigation (SF Symbol - system convention)
        static let forward = "chevron.right"  // SF Symbol

        /// Close/dismiss (SF Symbol - system convention)
        static let close = "xmark"  // SF Symbol

        /// Menu/hamburger (SF Symbol - system convention)
        static let menu = "line.3.horizontal"  // SF Symbol

        /// Sort options (SF Symbol)
        static let sort = "arrow.up.arrow.down"  // SF Symbol

        /// Filter options (SF Symbol)
        static let filter = "line.3.horizontal.decrease"  // SF Symbol
    }

    // MARK: - Highlight Category Icons
    // Using Streamline icons for distinctive manuscript aesthetic

    enum HighlightCategory {
        /// Promise - handshake covenant (Streamline Business-Deal-Handshake)
        static let promise = "streamline-promise"  // Streamline asset

        /// Command - gavel authority (Streamline Legal-Hammer)
        static let command = "streamline-command"  // Streamline asset

        /// Prophecy - seeing eye (Streamline Seo-Eye)
        static let prophecy = "streamline-prophecy"  // Streamline asset

        /// Character - standing figure (Streamline Single-Man)
        static let character = "streamline-character"  // Streamline asset

        /// Geography - globe (Streamline Earth-3)
        static let geography = "streamline-geography"  // Streamline asset

        /// Doctrine - classical pillar (Streamline Historical-Building-Pillar)
        static let doctrine = "streamline-doctrine"  // Streamline asset

        /// Warning - caution sign (Streamline Alert-Triangle)
        static let warning = "streamline-warning"  // Streamline asset

        /// Praise - hands with light (Streamline Religion-Hands)
        static let praise = "streamline-praise"  // Streamline asset
    }

    // MARK: - AI/Insight Icons
    // Using Streamline where available

    enum AI {
        /// AI processing indicator (SF Symbol - animated)
        static let processing = "sparkles"  // SF Symbol

        /// Insight/lightbulb moment (Streamline Bulb-1)
        static let insight = "streamline-insight"  // Streamline asset

        /// Commentary/scholarly (Streamline Design-Tool-Quill-2)
        static let commentary = "streamline-commentary"  // Streamline asset

        /// Cross references (Streamline Strategy-Split)
        static let crossReferences = "streamline-crossrefs"  // Streamline asset

        /// AI chat/ask (Streamline Ai-Chat-Spark)
        static let chat = "streamline-chat"  // Streamline asset
    }

    // MARK: - Achievement/Gamification Icons
    // Using Streamline icons for distinctive gamification aesthetic

    enum Achievement {
        /// Novice level - seedling/sprout (Streamline Plant-Sprout)
        static let novice = "streamline-novice"  // Streamline asset

        /// Apprentice level - scroll (Streamline Scroll-1)
        static let apprentice = "streamline-apprentice"  // Streamline asset

        /// Scholar level - graduation (Streamline Graduation-Cap)
        static let scholar = "streamline-scholar"  // Streamline asset

        /// Master level - crown (Streamline Crown-1)
        static let master = "streamline-master"  // Streamline asset

        /// Sage level - wisdom/enlightenment (Streamline Meditation)
        static let sage = "streamline-sage"  // Streamline asset

        /// Streak flame - fire (Streamline Fire-1)
        static let streak = "streamline-streak"  // Streamline asset

        /// Trophy/award - trophy cup (Streamline Trophy-1)
        static let trophy = "streamline-trophy"  // Streamline asset

        /// Star rating - star (Streamline Star-1)
        static let star = "streamline-star"  // Streamline asset
    }

    // MARK: - Media Control Icons

    enum Media {
        /// Play
        static let play = "play.fill"

        /// Pause
        static let pause = "pause.fill"

        /// Stop
        static let stop = "stop.fill"

        /// Skip forward
        static let skipForward = "goforward.15"

        /// Skip backward
        static let skipBackward = "gobackward.15"

        /// Volume
        static let volume = "speaker.wave.2.fill"

        /// Mute
        static let mute = "speaker.slash.fill"

        /// Playback speed
        static let speed = "speedometer"
    }

    // MARK: - Status Icons

    enum Status {
        /// Success/complete
        static let success = "checkmark.circle.fill"

        /// Error/failure
        static let error = "xmark.circle.fill"

        /// Warning
        static let warning = "exclamationmark.triangle.fill"

        /// Info
        static let info = "info.circle.fill"

        /// Loading
        static let loading = "arrow.trianglehead.2.clockwise"

        /// Offline
        static let offline = "wifi.slash"

        /// Syncing
        static let syncing = "arrow.triangle.2.circlepath"
    }

    // MARK: - Content Type Icons

    enum Content {
        /// Bible/scripture
        static let bible = "text.book.closed.fill"

        /// Chapter
        static let chapter = "number"

        /// Verse
        static let verse = "text.quote"

        /// Audio
        static let audio = "waveform"

        /// Video
        static let video = "play.rectangle.fill"

        /// Image
        static let image = "photo"

        /// Document
        static let document = "doc.text"

        /// Link
        static let link = "link"
    }
}

// MARK: - Icon Helpers

extension AppIcons {

    /// Get highlight category icon by category type
    static func iconForHighlightCategory(_ category: String) -> String {
        switch category.lowercased() {
        case "promise": return HighlightCategory.promise
        case "command": return HighlightCategory.command
        case "prophecy": return HighlightCategory.prophecy
        case "character": return HighlightCategory.character
        case "geography": return HighlightCategory.geography
        case "doctrine": return HighlightCategory.doctrine
        case "warning": return HighlightCategory.warning
        case "praise": return HighlightCategory.praise
        default: return "tag.fill"
        }
    }

    /// Get achievement icon by level
    static func iconForLevel(_ level: Int) -> String {
        switch level {
        case 0...1: return Achievement.novice
        case 2...3: return Achievement.apprentice
        case 4...5: return Achievement.scholar
        case 6...7: return Achievement.master
        default: return Achievement.sage
        }
    }
}
