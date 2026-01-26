//
//  SermonDestination.swift
//  BibleStudy
//
//  Navigation destinations for the sermon hub & spoke architecture.
//  Used with NavigationLink(value:) and .navigationDestination(for:).
//

import Foundation

// MARK: - Sermon Destination

enum SermonDestination: Hashable {
    /// Study Guide spoke — AI-generated insights, takeaways, quotes, etc.
    /// Optional `scrollTo` parameter for deep-linking from "Start Here" prompts.
    case studyGuide(scrollTo: SermonSectionID? = nil)

    /// Listen & Read spoke — audio player, outline, transcript.
    /// `autoPlay` starts playback on appear.
    case listenRead(autoPlay: Bool = false)

    /// My Journal spoke — user bookmarks and journal entries.
    case journal
}
