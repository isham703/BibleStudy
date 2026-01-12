import Testing
@testable import BibleStudy

// MARK: - TimestampFormatter Tests

@Suite("TimestampFormatter")
struct TimestampFormatterTests {

    // MARK: - format(_:) Tests

    @Suite("format(_:)")
    struct FormatTests {

        @Test("Formats zero seconds as 0:00")
        func formatsZeroSeconds() {
            let result = TimestampFormatter.format(0)
            #expect(result == "0:00")
        }

        @Test("Formats seconds only (under 1 minute)")
        func formatsSecondsOnly() {
            #expect(TimestampFormatter.format(5) == "0:05")
            #expect(TimestampFormatter.format(30) == "0:30")
            #expect(TimestampFormatter.format(59) == "0:59")
        }

        @Test("Formats minutes and seconds")
        func formatsMinutesAndSeconds() {
            #expect(TimestampFormatter.format(60) == "1:00")
            #expect(TimestampFormatter.format(90) == "1:30")
            #expect(TimestampFormatter.format(125) == "2:05")
            #expect(TimestampFormatter.format(599) == "9:59")
        }

        @Test("Formats exactly one hour")
        func formatsOneHour() {
            #expect(TimestampFormatter.format(3600) == "1:00:00")
        }

        @Test("Formats hours, minutes, and seconds")
        func formatsHoursMinutesSeconds() {
            #expect(TimestampFormatter.format(3661) == "1:01:01")
            #expect(TimestampFormatter.format(3723) == "1:02:03")
            #expect(TimestampFormatter.format(7325) == "2:02:05")
        }

        @Test("Formats multi-hour durations")
        func formatsMultiHour() {
            #expect(TimestampFormatter.format(36000) == "10:00:00")
            #expect(TimestampFormatter.format(86399) == "23:59:59")
        }

        @Test("Handles fractional seconds by truncating")
        func handlesFractionalSeconds() {
            #expect(TimestampFormatter.format(90.5) == "1:30")
            #expect(TimestampFormatter.format(90.9) == "1:30")
            #expect(TimestampFormatter.format(3661.999) == "1:01:01")
        }
    }

    // MARK: - format(_:forceHours:) Tests

    @Suite("format(_:forceHours:)")
    struct FormatWithForceHoursTests {

        @Test("Does not force hours when forceHours is false")
        func doesNotForceHours() {
            #expect(TimestampFormatter.format(90, forceHours: false) == "1:30")
            #expect(TimestampFormatter.format(599, forceHours: false) == "9:59")
        }

        @Test("Forces hours display when forceHours is true")
        func forcesHoursDisplay() {
            #expect(TimestampFormatter.format(0, forceHours: true) == "0:00:00")
            #expect(TimestampFormatter.format(90, forceHours: true) == "0:01:30")
            #expect(TimestampFormatter.format(599, forceHours: true) == "0:09:59")
        }

        @Test("Shows hours regardless of forceHours when time >= 1 hour")
        func showsHoursWhenTimeExceedsHour() {
            #expect(TimestampFormatter.format(3661, forceHours: false) == "1:01:01")
            #expect(TimestampFormatter.format(3661, forceHours: true) == "1:01:01")
        }
    }

    // MARK: - formatDuration(_:) Tests

    @Suite("formatDuration(_:)")
    struct FormatDurationTests {

        @Test("Formats zero as 0 min")
        func formatsZeroDuration() {
            #expect(TimestampFormatter.formatDuration(0) == "0 min")
        }

        @Test("Formats minutes only")
        func formatsMinutesOnly() {
            #expect(TimestampFormatter.formatDuration(60) == "1 min")
            #expect(TimestampFormatter.formatDuration(300) == "5 min")
            #expect(TimestampFormatter.formatDuration(1800) == "30 min")
        }

        @Test("Formats exactly one hour")
        func formatsOneHour() {
            #expect(TimestampFormatter.formatDuration(3600) == "1 hr")
        }

        @Test("Formats hours and minutes")
        func formatsHoursAndMinutes() {
            #expect(TimestampFormatter.formatDuration(3660) == "1 hr 1 min")
            #expect(TimestampFormatter.formatDuration(5400) == "1 hr 30 min")
            #expect(TimestampFormatter.formatDuration(7500) == "2 hr 5 min")
        }

        @Test("Ignores seconds in duration (truncates to minutes)")
        func ignoresSeconds() {
            // 90 seconds = 1 min (30 seconds truncated)
            #expect(TimestampFormatter.formatDuration(90) == "1 min")
            // 119 seconds = 1 min (59 seconds truncated)
            #expect(TimestampFormatter.formatDuration(119) == "1 min")
        }

        @Test("Formats typical sermon durations")
        func formatsTypicalSermonDurations() {
            // 25 minute sermon
            #expect(TimestampFormatter.formatDuration(1500) == "25 min")
            // 45 minute sermon
            #expect(TimestampFormatter.formatDuration(2700) == "45 min")
            // 1 hour 15 minute sermon
            #expect(TimestampFormatter.formatDuration(4500) == "1 hr 15 min")
        }
    }
}
