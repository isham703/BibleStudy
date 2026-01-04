import Foundation

// MARK: - Reading Plan
// Represents a Bible reading plan with daily readings

struct ReadingPlan: Identifiable, Codable {
    let id: UUID
    let userId: UUID?
    let title: String
    let description: String?
    let isCustom: Bool
    let schedule: [DayReading]
    let createdAt: Date

    var totalDays: Int { schedule.count }

    init(
        id: UUID = UUID(),
        userId: UUID? = nil,
        title: String,
        description: String? = nil,
        isCustom: Bool = true,
        schedule: [DayReading],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.title = title
        self.description = description
        self.isCustom = isCustom
        self.schedule = schedule
        self.createdAt = createdAt
    }
}

// MARK: - Day Reading
struct DayReading: Identifiable, Codable {
    var id: Int { day }
    let day: Int
    let readings: [VerseRange]

    var reference: String {
        readings.map { $0.reference }.joined(separator: "; ")
    }
}

// MARK: - Reading Progress
struct ReadingProgress: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    let planId: UUID
    let dayNumber: Int
    var completedAt: Date?
    var reflection: String?
    let createdAt: Date

    var isCompleted: Bool { completedAt != nil }

    init(
        id: UUID = UUID(),
        userId: UUID,
        planId: UUID,
        dayNumber: Int,
        completedAt: Date? = nil,
        reflection: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.planId = planId
        self.dayNumber = dayNumber
        self.completedAt = completedAt
        self.reflection = reflection
        self.createdAt = createdAt
    }
}

// MARK: - Plan with Progress
struct PlanWithProgress: Identifiable {
    let plan: ReadingPlan
    var progress: [ReadingProgress]

    var id: UUID { plan.id }
    var title: String { plan.title }
    var description: String? { plan.description }

    var completedDays: Int {
        progress.filter { $0.isCompleted }.count
    }

    var totalDays: Int { plan.totalDays }

    var progressPercentage: Double {
        guard totalDays > 0 else { return 0 }
        return Double(completedDays) / Double(totalDays)
    }

    var currentDay: Int {
        completedDays + 1
    }

    var todayReading: DayReading? {
        plan.schedule.first { $0.day == currentDay }
    }

    var isCompleted: Bool {
        completedDays >= totalDays
    }
}

// MARK: - Sample Plans
extension ReadingPlan {
    static var samplePlans: [ReadingPlan] {
        [
            ReadingPlan(
                title: "Gospel of John",
                description: "Read through the Gospel of John in 21 days",
                isCustom: false,
                schedule: (1...21).map { day in
                    DayReading(day: day, readings: [
                        VerseRange(bookId: 43, chapter: day, verseStart: 1, verseEnd: 51)
                    ])
                }
            ),
            ReadingPlan(
                title: "Psalms in 30 Days",
                description: "Journey through the Psalms",
                isCustom: false,
                schedule: (1...30).map { day in
                    let startPsalm = (day - 1) * 5 + 1
                    return DayReading(day: day, readings: (startPsalm...(startPsalm + 4)).map { psalm in
                        VerseRange(bookId: 19, chapter: psalm, verseStart: 1, verseEnd: 99)
                    })
                }
            ),
            ReadingPlan(
                title: "Genesis Deep Dive",
                description: "Study the book of Genesis chapter by chapter",
                isCustom: false,
                schedule: (1...50).map { day in
                    DayReading(day: day, readings: [
                        VerseRange(bookId: 1, chapter: day, verseStart: 1, verseEnd: 99)
                    ])
                }
            )
        ]
    }
}
