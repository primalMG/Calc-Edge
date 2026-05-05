import SwiftUI

struct PricesSection: View {
    @Bindable var trade: Trade

    private var positionSummary: TradePositionSummary {
        trade.positionSummary
    }

    var body: some View {
        JournalSectionContainer("Prices") {
            LazyVGrid(columns: columns, spacing: 12) {
                JournalField("Planned Share Count") {
                    TextField("", text: decimalBinding($trade.shareCount))
                    #if os(iOS)
                        .textFieldStyle(CustomTextFieldStyle())
                    #endif
                }

                JournalField("Current Share Count") {
                    Text(ValueDisplayFormatter.decimal(positionSummary.currentShareCount))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundStyle(.primary)
                }

                JournalField("Average Price") {
                    Text(ValueDisplayFormatter.decimal(positionSummary.averagePrice, placeholder: "No open position"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundStyle(positionSummary.averagePrice == nil ? .secondary : .primary)
                }

                JournalField("Entry Price") {
                    TextField("", text: optionalDecimalBinding($trade.entryPrice))
                    #if os(iOS)
                        .textFieldStyle(CustomTextFieldStyle())
                    #endif
                }
                
                JournalField("Exit Price") {
                    TextField("", text: optionalDecimalBinding($trade.exitPrice))
                        #if os(iOS)
                        .textFieldStyle(CustomTextFieldStyle())
                        #endif
                }

                JournalField("Exchange Rate") {
                    TextField("", text: optionalDecimalBinding($trade.exchangeRate))
                        #if os(iOS)
                        .textFieldStyle(CustomTextFieldStyle())
                        #endif
                }
                
                JournalField("Stop Price") {
                    TextField("", text: optionalDecimalBinding($trade.stopPrice))
                        #if os(iOS)
                        .textFieldStyle(CustomTextFieldStyle())
                        #endif
                }
                
                JournalField("Target Price") {
                    TextField("", text: optionalDecimalBinding($trade.targetPrice))
                        #if os(iOS)
                        .textFieldStyle(CustomTextFieldStyle())
                        #endif
                }
            }
        }
    }
    
    #if os(macOS)
    private let columns = [
        GridItem(.flexible(minimum: 140), spacing: 12),
        GridItem(.flexible(minimum: 140), spacing: 12),
        GridItem(.flexible(minimum: 140), spacing: 12)
    ]
    #else
    private let columns = [
        GridItem(.adaptive(minimum: 150), spacing: 15)
    ]
    #endif
}
