import SwiftUI

struct StrategySection: View {
    @Bindable var trade: Trade

    var body: some View {
        JournalSectionContainer("Strategy") {
            LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
                JournalField("Strategy Name") {
                    SuggestingOptionalTextField(field: .strategyName, text: $trade.strategyName)
                }
                
                JournalField("Setup Type") {
                    SuggestingOptionalTextField(field: .setupType, text: $trade.setupType)
                }
                
                JournalField("Timeframe") {
                    SuggestingOptionalTextField(field: .timeframe, text: $trade.timeframe)
                }
                
                JournalField("Thesis") {
                    TextField("", text: optionalTextBinding($trade.thesis))
                }
                
                JournalField("Catalyst") {
                    SuggestingOptionalTextField(field: .catalyst, text: $trade.catalyst)
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
