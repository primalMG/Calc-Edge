import SwiftUI

struct PricesSection: View {
    @Bindable var trade: Trade

    var body: some View {
        JournalSectionContainer("Prices") {
            LazyVGrid(columns: columns, spacing: 12) {
                JournalField("Initial Share Count") {
                    if trade.isInitialShareCountLocked {
                        HStack(spacing: 8) {
                            Text(ValueDisplayFormatter.decimal(trade.shareCount, fractionDigits: 2))
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Image(systemName: "lock.fill")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        TextField("", text: decimalBinding($trade.shareCount))
                        #if os(iOS)
                            .textFieldStyle(CustomTextFieldStyle())
                        #endif
                    }
                }

                JournalField("Current Share Count") {
                    Text(ValueDisplayFormatter.decimal(trade.currentShareCount, fractionDigits: 2))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundStyle(.primary)
                }

                JournalField("Average Price") {
                    Text(ValueDisplayFormatter.decimal(trade.currentAveragePrice, placeholder: "No open position", fractionDigits: 2))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundStyle(trade.currentAveragePrice == nil ? .secondary : .primary)
                }

                JournalField("Current Spend") {
                    Text(ValueDisplayFormatter.decimal(trade.currentSpend, placeholder: "Waiting for inputs", fractionDigits: 2))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundStyle(trade.currentSpend == nil ? .secondary : .primary)
                }

                JournalField("Entry Price") {
                    TextField("", text: optionalDecimalBinding($trade.entryPrice, fractionDigits: 2))
                    #if os(iOS)
                        .textFieldStyle(CustomTextFieldStyle())
                    #endif
                }

                if trade.closedAt == nil {
                    JournalField("Current Price") {
                        TextField("", text: optionalDecimalBinding($trade.currentPrice, fractionDigits: 2))
                        #if os(iOS)
                            .textFieldStyle(CustomTextFieldStyle())
                        #endif
                    }
                } else {
                    JournalField("Exit Price") {
                        TextField("", text: optionalDecimalBinding($trade.exitPrice, fractionDigits: 2))
                        #if os(iOS)
                            .textFieldStyle(CustomTextFieldStyle())
                        #endif
                    }
                }

                JournalField("Total Profit/Loss") {
                    Text(ValueDisplayFormatter.decimal(trade.totalProfitLoss, placeholder: "Waiting for inputs", fractionDigits: 2))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundStyle(profitLossStyle)
                }

                JournalField("Dividend Total") {
                    Text(ValueDisplayFormatter.decimal(trade.dividendTotal, fractionDigits: 2))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundStyle(.primary)
                }

                JournalField("Exchange Rate") {
                    TextField("", text: optionalDecimalBinding($trade.exchangeRate))
                        #if os(iOS)
                        .textFieldStyle(CustomTextFieldStyle())
                        #endif
                }
                
                JournalField("Stop Price") {
                    TextField("", text: optionalDecimalBinding($trade.stopPrice, fractionDigits: 2))
                        #if os(iOS)
                        .textFieldStyle(CustomTextFieldStyle())
                        #endif
                }
                
                JournalField("Target Price") {
                    TextField("", text: optionalDecimalBinding($trade.targetPrice, fractionDigits: 2))
                        #if os(iOS)
                        .textFieldStyle(CustomTextFieldStyle())
                        #endif
                }
            }
        }
    }

    private var profitLossStyle: Color {
        guard let totalProfitLoss = trade.totalProfitLoss else {
            return .secondary
        }

        return totalProfitLoss >= 0 ? .green : .red
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
