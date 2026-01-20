import SwiftUI

struct PricesSection: View {
    @Bindable var trade: Trade

    var body: some View {
        Section("Prices") {
            LabeledContent("Entry Price") {
                TextField("", text: optionalDecimalBinding($trade.entryPrice))
                    .textFieldStyle(CustomTextFieldStyle())
            }

            LabeledContent("Exit Price") {
                TextField("", text: optionalDecimalBinding($trade.exitPrice))
                    .textFieldStyle(CustomTextFieldStyle())
            }

            LabeledContent("Stop Price") {
                TextField("", text: optionalDecimalBinding($trade.stopPrice))
                    .textFieldStyle(CustomTextFieldStyle())
            }

            LabeledContent("Target Price") {
                TextField("", text: optionalDecimalBinding($trade.targetPrice))
                    .textFieldStyle(CustomTextFieldStyle())
            }
        }
    }
}
