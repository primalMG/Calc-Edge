import Foundation
import SwiftUI
import SwiftData

struct TradeJournalDetailView: View {
    @Bindable var trade: Trade

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                IdentificationSection(trade: trade, inEditMode: .constant(true))
                
                if trade.closedAt != nil {
                    ExitSection(trade: trade)
                }
                
                HStack(alignment: .top) {
                    PricesSection(trade: trade)
                    
                    RiskSection(trade: trade, inEditMode: .constant(true))
                }
                
                
                StrategySection(trade: trade)
                
                ReviewSection(trade: trade)
                MarketContextSection(trade: trade)
                LegsSection(trade: trade)
                AttachmentsSection(trade: trade)
            }
            .padding()
        }
        .navigationTitle(trade.ticker)
    }

    private func displayText(_ value: String?) -> String {
        guard let value, !value.isEmpty else { return "N/A" }
        return value
    }

    private func formatDate(_ date: Date?) -> String {
        guard let date else { return "N/A" }
        return date.formatted()
    }

    private func formatDecimal(_ value: Decimal?) -> String {
        guard let value else { return "N/A" }
        return NSDecimalNumber(decimal: value).stringValue
    }

    private func formatBool(_ value: Bool) -> String {
        value ? "Yes" : "No"
    }

    private func formatImageData(_ data: Data?) -> String {
        guard let data else { return "No" }
        return "Yes (\(data.count) bytes)"
    }
}
