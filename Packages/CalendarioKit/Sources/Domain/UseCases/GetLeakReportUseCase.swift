/// Detector de fugas (HER-04 a HER-06). Funciona sin salario (S-05).
public struct GetLeakReportUseCase {
    private let payments: any PaymentRepository
    private let clock: any DateProviding

    public init(payments: any PaymentRepository, clock: any DateProviding) {
        self.payments = payments
        self.clock = clock
    }

    public func execute() throws -> LeakReport {
        LeakDetector.report(activePayments: try payments.activePayments(clock: clock))
    }
}
