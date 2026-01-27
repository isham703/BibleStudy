import SwiftUI

// MARK: - Caption Reference State
// Manages detected Bible references during live captioning.
// Tracks which references have been found and which is actively selected.

@MainActor
@Observable
final class CaptionReferenceState {
    // MARK: - Public State

    /// All references detected during the session (ordered by detection time)
    private(set) var detectedReferences: [DetectedReference] = []

    /// Currently selected reference (for chip overlay display)
    var selectedReference: DetectedReference?

    // MARK: - Private State

    /// Canonical IDs already seen — prevents duplicate detections
    private var seenCanonicalIds = Set<String>()

    // MARK: - Detected Reference Model

    struct DetectedReference: Identifiable, Equatable {
        let id: UUID
        let parsed: ParsedReference
        let canonicalId: String
        let detectedAt: Date

        static func == (lhs: DetectedReference, rhs: DetectedReference) -> Bool {
            lhs.id == rhs.id
        }
    }

    // MARK: - Detection

    /// Scan text for new references. Call from the caption observation loop.
    func scanText(_ text: String) {
        let newRefs = CaptionReferenceDetector.detectNew(
            in: text,
            seenIds: &seenCanonicalIds
        )

        for ref in newRefs {
            let detected = DetectedReference(
                id: UUID(),
                parsed: ref,
                canonicalId: ReferenceParser.canonicalId(for: ref),
                detectedAt: Date()
            )
            detectedReferences.append(detected)

            // Auto-select the latest reference
            selectedReference = detected
        }
    }

    /// Dismiss the chip overlay.
    /// If `forReferenceId` is provided, only clears if it's still the active reference
    /// (prevents a delayed dismiss from wiping a newly detected reference).
    func dismissChip(forReferenceId: UUID? = nil) {
        if let id = forReferenceId {
            guard selectedReference?.id == id else { return }
        }
        selectedReference = nil
    }

    /// Navigate to the selected reference's location
    func locationForSelected() -> BibleLocation? {
        selectedReference?.parsed.location
    }

    /// Reset all state (recording ended or cancelled)
    func reset() {
        detectedReferences = []
        selectedReference = nil
        seenCanonicalIds = []
    }
}
