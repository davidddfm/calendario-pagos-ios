import DesignSystem
import Domain
import Features
import SwiftUI

/// §11.1: error de almacén → onboarding → pestañas. El bloqueo (SEG) se agrega en la iteración 5.
struct RootView: View {
    let container: AppContainer
    @State private var router = AppRouter()
    @State private var settings: AppSettings
    @Environment(\.scenePhase) private var scenePhase

    init(container: AppContainer) {
        self.container = container
        _settings = State(initialValue: container.settings.load())
    }

    var body: some View {
        Group {
            if settings.needsOnboarding {
                OnboardingView(viewModel: container.makeOnboardingViewModel())
            } else {
                MainTabView(container: container, router: router)
                    .environment(\.currency, settings.currency ?? .usd)  // MND-02
            }
        }
        .environment(container.tracker)
        .task(id: container.tracker.version) { settings = container.settings.load() }
        // Cambios hechos fuera de la app y cambio de día o de mes (MAR-03, §9.4).
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { container.tracker.bump() }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
            container.tracker.bump()
        }
    }
}
