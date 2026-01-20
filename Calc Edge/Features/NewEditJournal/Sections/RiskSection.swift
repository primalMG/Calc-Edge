import SwiftUI

struct RiskSection: View {
    @Bindable var trade: Trade

    var body: some View {
        Section("Risk") {
            LabeledContent("Planned Risk Amount") {
                TextField("", text: optionalDecimalBinding($trade.plannedRiskAmount))
                    .textFieldStyle(CustomTextFieldStyle())
            }

            LabeledContent("Planned Risk Percent") {
                TextField("", text: optionalDecimalBinding($trade.plannedRiskPercent))
                    .textFieldStyle(CustomTextFieldStyle())
            }

            LabeledContent("Commissions") {
                TextField("", text: optionalDecimalBinding($trade.commissions))
                    .textFieldStyle(CustomTextFieldStyle())
            }

            LabeledContent("Slippage") {
                TextField("", text: optionalDecimalBinding($trade.slippage))
                    .textFieldStyle(CustomTextFieldStyle())
            }

            LabeledContent("MAE") {
                TextField("", text: optionalDecimalBinding($trade.mae))
                    .textFieldStyle(CustomTextFieldStyle())
            }

            LabeledContent("MFE") {
                TextField("", text: optionalDecimalBinding($trade.mfe))
                    .textFieldStyle(CustomTextFieldStyle())
            }
        }
    }
}
