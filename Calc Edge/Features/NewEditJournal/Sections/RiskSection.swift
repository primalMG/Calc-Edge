import SwiftUI

struct RiskSection: View {
    @Bindable var trade: Trade
    @Binding var inEditMode: Bool

    var body: some View {
        JournalSectionContainer("Risk") {
            LazyVGrid(columns: columns, spacing: 12) {
                JournalField("Planned Risk Amount") {
                    TextField("", text: optionalDecimalBinding($trade.plannedRiskAmount))
                        .textFieldStyle(CustomTextFieldStyle())
                }

                JournalField("Planned Risk Percent") {
                    TextField("", text: optionalDecimalBinding($trade.plannedRiskPercent))
                        .textFieldStyle(CustomTextFieldStyle())
                }

                if inEditMode {
                    JournalField("Commissions") {
                        TextField("", text: optionalDecimalBinding($trade.commissions))
                            .textFieldStyle(CustomTextFieldStyle())
                    }

                    JournalField("Slippage") {
                        TextField("", text: optionalDecimalBinding($trade.slippage))
                            .textFieldStyle(CustomTextFieldStyle())
                    }

                    JournalField("MAE") {
                        TextField("", text: optionalDecimalBinding($trade.mae))
                            .textFieldStyle(CustomTextFieldStyle())
                    }

                    JournalField("MFE") {
                        TextField("", text: optionalDecimalBinding($trade.mfe))
                            .textFieldStyle(CustomTextFieldStyle())
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
