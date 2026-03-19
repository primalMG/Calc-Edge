import SwiftUI

struct PricesSection: View {
    @Bindable var trade: Trade

    var body: some View {
        JournalSectionContainer("Prices") {
            LazyVGrid(columns: columns, spacing: 12) {
                JournalField("Entry Price") {
                    TextField("", text: optionalDecimalBinding($trade.entryPrice))
                }

                JournalField("Exit Price") {
                    TextField("", text: optionalDecimalBinding($trade.exitPrice))
                }

                JournalField("Stop Price") {
                    TextField("", text: optionalDecimalBinding($trade.stopPrice))
                }

                JournalField("Target Price") {
                    TextField("", text: optionalDecimalBinding($trade.targetPrice))
                }
            }
        }
    }

    private let columns = [
        GridItem(.flexible(minimum: 140), spacing: 12),
        GridItem(.flexible(minimum: 140), spacing: 12)
    ]
}
