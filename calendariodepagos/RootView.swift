import DesignSystem
import Domain
import Features
import SwiftUI

/// §11.1: error de almacén → bloqueo → onboarding → pestañas.
struct RootView: View {
    let container: AppContainer
    let notifications: NotificationDelegate
    @State private var router = AppRouter()
    @State private var settings: AppSettings
    @Environment(\.scenePhase) private var scenePhase

    init(container: AppContainer, notifications: NotificationDelegate) {
        self.container = container
        self.notifications = notifications
        _settings = State(initialValue: container.settings.load())
    }

    var body: some View {
        let appLock = container.appLock
        Group {
            if appLock.isLocked {
                AppLockView(controller: appLock)  // SEG-03: ningún dato a la vista
            } else if settings.needsOnboarding {
                OnboardingView(viewModel: container.makeOnboardingViewModel())
            } else {
                MainTabView(container: container, router: router)
                    .environment(\.currency, settings.currency ?? .usd)  // MND-02
            }
        }
        .environment(container.tracker)
        .task(id: container.tracker.version) { settings = container.settings.load() }
        .onAppear {
            appLock.didBecomeActive()
            deliverPendingLink()
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active:
                // Cambios hechos fuera de la app y cambio de día o de mes (MAR-03, §9.4).
                container.tracker.bump()
                appLock.didBecomeActive()
                container.reconcileReminders()  // NOT-04
            case .background:
                appLock.didEnterBackground()
                AppRefresh.schedule()
            case .inactive:
                break
            @unknown default:
                break
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
            container.tracker.bump()
            container.reconcileReminders()
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSSystemTimeZoneDidChange)) { _ in
            container.tracker.bump()
            container.reconcileReminders()
        }
        // §9.3: la URL se descarta en silencio si no es un enlace válido.
        .onOpenURL { url in
            guard let link = DeepLink(url: url) else { return }
            router.pendingDeepLink = link
            deliverPendingLink()
        }
        .onChange(of: notifications.pendingLink) { _, link in
            guard let link else { return }
            notifications.pendingLink = nil
            router.pendingDeepLink = link
            deliverPendingLink()
        }
        .onChange(of: appLock.isLocked) { deliverPendingLink() }
        .alert(
            "Se desactivó el bloqueo de la app",
            isPresented: Binding(
                get: { appLock.showsPasscodeRemovedAlert },
                set: { if !$0 { appLock.dismissPasscodeRemovedAlert() } })
        ) {
        } message: {
            // SEG-04
            Text(
                "Tu iPhone ya no tiene código de desbloqueo. Vuelve a activarlo en Configuración cuando lo configures.")
        }
    }

    /// SEG-03: con la app bloqueada, el enlace espera hasta desbloquear.
    private func deliverPendingLink() {
        if let link = notifications.pendingLink {
            notifications.pendingLink = nil
            router.pendingDeepLink = link
        }
        guard !container.appLock.isLocked, !settings.needsOnboarding, let link = router.pendingDeepLink else { return }
        router.pendingDeepLink = nil
        router.handle(link)
    }
}
