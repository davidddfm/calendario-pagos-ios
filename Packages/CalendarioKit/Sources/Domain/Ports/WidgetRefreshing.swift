/// WID-03: pide a WidgetKit que vuelva a calcular las líneas de tiempo (§8.3).
public protocol WidgetRefreshing: Sendable {
    func reloadAll()
}
