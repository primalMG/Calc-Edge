import SwiftUI

struct RiskSection: View {
    @Bindable var trade: Trade
    @Binding var inEditMode: Bool

    var body: some View {
        JournalSectionContainer("Risk") {
            LazyVGrid(columns: columns, spacing: 12) {
                JournalField("Planned Risk Amount") {
                    TextField("", text: optionalDecimalBinding($trade.plannedRiskAmount))
                }

                JournalField("Planned Risk Percent") {
                    TextField("", text: optionalDecimalBinding($trade.plannedRiskPercent))
                }

                if inEditMode {
                    JournalField("Commissions") {
                        TextField("", text: optionalDecimalBinding($trade.commissions))
                    }

                    JournalField("Slippage") {
                        TextField("", text: optionalDecimalBinding($trade.slippage))
                    }

                    JournalField("MAE") {
                        TextField("", text: optionalDecimalBinding($trade.mae))
                    }

                    JournalField("MFE") {
                        TextField("", text: optionalDecimalBinding($trade.mfe))
                    }
                }
            }
        }
    }

    private let columns = [
        GridItem(.flexible(minimum: 140), spacing: 12),
        GridItem(.flexible(minimum: 140), spacing: 12),
        GridItem(.flexible(minimum: 140), spacing: 12)
    ]
}
