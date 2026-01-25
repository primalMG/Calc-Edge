import SwiftUI

struct PricesSection: View {
    @Bindable var trade: Trade

    var body: some View {
        JournalSectionContainer("Prices") {
            LazyVGrid(columns: columns, spacing: 12) {
                JournalField("Entry Price") {
                    TextField("", text: optionalDecimalBinding($trade.entryPrice))
                        .textFieldStyle(CustomTextFieldStyle())
                }

                JournalField("Exit Price") {
                    TextField("", text: optionalDecimalBinding($trade.exitPrice))
                        .textFieldStyle(CustomTextFieldStyle())
                }

                JournalField("Stop Price") {
                    TextField("", text: optionalDecimalBinding($trade.stopPrice))
                        .textFieldStyle(CustomTextFieldStyle())
                }

                JournalField("Target Price") {
                    TextField("", text: optionalDecimalBinding($trade.targetPrice))
                        .textFieldStyle(CustomTextFieldStyle())
                }
            }
        }
    }

    private let columns = [
        GridItem(.flexible(minimum: 140), spacing: 12),
        GridItem(.flexible(minimum: 140), spacing: 12)
    ]
}
