import Domain
import Foundation
import TestSupport
import Testing

@testable import Features

@Suite("PAG-01 a PAG-04 · Formulario de pago")
struct PaymentFormViewModelTests {
    let payments = InMemoryPaymentRepository()
    let observer = SpyChangeObserver()
    let clock: FixedClock

    init() throws {
        clock = FixedClock(now: try Calendar.testGregorian.date(year: 2026, month: 10, day: 20))
    }

    private func makeViewModel(_ mode: PaymentFormViewModel.Mode = .create, defaultDay: Int = 20)
        -> PaymentFormViewModel
    {
        PaymentFormViewModel(
            mode: mode,
            defaultDay: defaultDay,
            createPayment: CreatePaymentUseCase(payments: payments, clock: clock, observer: observer),
            updatePayment: UpdatePaymentUseCase(payments: payments, clock: clock, observer: observer),
            deletePayment: DeletePaymentUseCase(payments: payments, clock: clock, observer: observer),
            getPayment: GetPaymentUseCase(payments: payments),
            locale: Locale(identifier: "en_US")
        )
    }

    @Test("Un formulario nuevo arranca con el día de hoy, Gastos y Guardar desactivado")
    func initialState() {
        let viewModel = makeViewModel()
        #expect(viewModel.dayOfMonth == 20)
        #expect(viewModel.category == .expenses)
        #expect(viewModel.fortnight == .second)
        #expect(!viewModel.canSave)
        // Los errores aparecen solo tras tocar el campo.
        #expect(viewModel.nameError == nil)
        #expect(viewModel.amountError == nil)
    }

    @Test("Reescribir el mismo valor no muestra errores antes de que el usuario escriba")
    func rewritingSameValueKeepsFieldPristine() {
        let viewModel = makeViewModel()
        viewModel.name = ""
        viewModel.amountText = ""
        #expect(viewModel.nameError == nil)
        #expect(viewModel.amountError == nil)
    }

    @Test("Crear un pago válido lo guarda y cierra el formulario")
    func create() throws {
        let viewModel = makeViewModel()
        viewModel.name = "Renta"
        viewModel.amountText = "1,250.50"
        viewModel.dayOfMonth = 1
        viewModel.category = .utilities
        #expect(viewModel.canSave)

        viewModel.save()

        let saved = try #require(payments.stored.values.first)
        #expect(saved.name == "Renta")
        #expect(saved.amount == Money(minorUnits: 125_050))
        #expect(saved.dayOfMonth == 1)
        #expect(saved.category == .utilities)
        #expect(viewModel.didFinish)
    }

    @Test(
        "Errores junto a cada campo",
        arguments: [
            ("", PaymentValidationError?.some(.amountRequired)),
            ("abc", .amountRequired),
            ("0", .amountRequired),
            ("10000000", .amountOutOfRange),
            ("-5", .amountOutOfRange),
            ("9999999.99", nil),
        ])
    func amountErrors(text: String, expected: PaymentValidationError?) {
        let viewModel = makeViewModel()
        viewModel.amountText = "1"  // el usuario escribe y luego corrige
        viewModel.amountText = text
        #expect(viewModel.amountError == expected)
    }

    @Test func nameErrors() {
        let viewModel = makeViewModel()
        viewModel.name = "   "
        #expect(viewModel.nameError == .nameRequired)
        viewModel.name = String(repeating: "a", count: 61)
        #expect(viewModel.nameError == .nameTooLong)
    }

    @Test("Un día por defecto inválido cae en 1")
    func invalidDefaultDay() {
        #expect(makeViewModel(defaultDay: 0).dayOfMonth == 1)
    }

    @Test("Editar carga los datos del pago y guarda los cambios")
    func edit() throws {
        let payment = Payment.fixture(
            name: "Luz", amount: Money(minorUnits: 8_050), day: 5, category: .utilities,
            createdAt: Date(timeIntervalSince1970: 0))
        try payments.insert(payment)
        let viewModel = makeViewModel(.edit(payment.id))

        viewModel.load()
        #expect(viewModel.name == "Luz")
        #expect(viewModel.amountText == "80.5")
        #expect(viewModel.dayOfMonth == 5)
        #expect(viewModel.category == .utilities)
        #expect(viewModel.nameError == nil)

        viewModel.amountText = "95"
        viewModel.save()
        #expect(try payments.payment(id: payment.id)?.amount == Money(major: 95))
        #expect(viewModel.didFinish)
    }

    @Test("Editar un pago que ya no existe muestra un error de carga")
    func editMissing() {
        let viewModel = makeViewModel(.edit(UUID()))
        viewModel.load()
        #expect(viewModel.loadError == UserFacingError(DomainError.paymentNotFound))
    }

    @Test("PAG-04 · Eliminar desde la edición")
    func delete() throws {
        let payment = Payment.fixture(createdAt: Date(timeIntervalSince1970: 0))
        try payments.insert(payment)
        let viewModel = makeViewModel(.edit(payment.id))

        viewModel.confirmDeletion()

        #expect(try payments.payment(id: payment.id)?.deletedAt == clock.now)
        #expect(viewModel.didFinish)
    }
}
