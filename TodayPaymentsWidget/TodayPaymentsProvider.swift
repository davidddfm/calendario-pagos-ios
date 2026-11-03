import Domain
import SystemServices
import WidgetKit

/// WID-04 (§10.2): entrada actual y de medianoche; se recarga a medianoche.
nonisolated struct TodayPaymentsProvider: TimelineProvider {
    func placeholder(in context: Context) -> TodayEntry {
        .sample(date: .now)
    }

    func getSnapshot(in context: Context, completion: @escaping (TodayEntry) -> Void) {
        guard !context.isPreview else { return completion(.sample(date: .now)) }
        let clock = SystemClock()
        completion(
            TodayEntry.load(for: [clock.now], calendar: clock.calendar).first
                ?? TodayEntry(date: clock.now, content: .unavailable))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodayEntry>) -> Void) {
        let clock = SystemClock()
        let now = clock.now
        let plan = WidgetTimelinePlanner.plan(now: now, calendar: clock.calendar)
        let entries = TodayEntry.load(for: plan.entryDates, calendar: clock.calendar)
        guard !entries.isEmpty else {
            let retry = WidgetTimelinePlanner.retry(now: now)
            completion(
                Timeline(entries: [TodayEntry(date: now, content: .unavailable)], policy: .after(retry.reloadDate)))
            return
        }
        completion(Timeline(entries: entries, policy: .after(plan.reloadDate)))
    }
}
