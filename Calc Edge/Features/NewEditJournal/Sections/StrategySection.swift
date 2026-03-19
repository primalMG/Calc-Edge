import SwiftUI

struct StrategySection: View {
    @Bindable var trade: Trade

    var body: some View {
        JournalSectionContainer("Strategy") {
            LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
                JournalField("Strategy Name") {
                    TextField("", text: optionalTextBinding($trade.strategyName))
                }
                
                JournalField("Setup Type") {
                    TextField("", text: optionalTextBinding($trade.setupType))
                }
                
                JournalField("Timeframe") {
                    TextField("", text: optionalTextBinding($trade.timeframe))
                }
                
                JournalField("Thesis") {
                    TextField("", text: optionalTextBinding($trade.thesis))
                }
                
                JournalField("Catalyst") {
                    TextField("", text: optionalTextBinding($trade.catalyst))
                }
                
                Stepper("Confidence Score: \(trade.confidenceScore)", value: $trade.confidenceScore, in: 1...5)
                
                Toggle("A+ Setup", isOn: $trade.isAPlusSetup)
            }
        }
    }
    
    private let columns = [
        GridItem(.flexible(minimum: 140), spacing: 12),
        GridItem(.flexible(minimum: 140), spacing: 12),
        GridItem(.flexible(minimum: 140), spacing: 12)
    ]
}
