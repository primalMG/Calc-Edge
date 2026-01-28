import Foundation
import SwiftUI
import SwiftData

struct TradeJournalDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var toggleDelete: Bool = false
    
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
                
                HStack {
                    ReviewSection(trade: trade)
                    MarketContextSection(trade: trade)
                }
                
                LegsSection(trade: trade)
                AttachmentsSection(trade: trade)
            }
            .padding()
        }
        .navigationTitle(trade.ticker)
        .toolbar {
            ToolbarItem {
                Button {
                    toggleDelete.toggle()
                } label: {
                    Image(systemName: "trash.fill")
                }
                .alert("Delete Journal Entry?", isPresented: $toggleDelete) {
                    
                }
            }
        }
    }
    
    private func delete() {
        modelContext.delete(trade)
        dismiss()
    }
}
