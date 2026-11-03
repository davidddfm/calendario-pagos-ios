import Domain
import WidgetKit

/// WID-03 (§8.3).
public struct WidgetCenterRefresher: WidgetRefreshing {
    public init() {}

    public func reloadAll() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}
