import Foundation

enum CalculatorRoute: String, Hashable {
    case stock
    case forex

    var title: String {
        switch self {
        case .stock:
            "Stock Calc"
        case .forex:
            "Forex Calc"
        }
    }
}

struct AppStartDestination: Equatable {
    let rootTab: RootTab
    let calculatorRoute: CalculatorRoute?

    init(rootTab: RootTab, calculatorRoute: CalculatorRoute? = nil) {
        self.rootTab = rootTab
        self.calculatorRoute = calculatorRoute
    }

    static let journal = AppStartDestination(rootTab: .journal)

    var title: String {
        calculatorRoute?.title ?? rootTab.title
    }
}
