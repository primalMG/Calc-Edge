import SwiftUI

struct StrategySection: View {
    @Bindable var trade: Trade

    var body: some View {
        JournalSectionContainer("Strategy") {
            LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
                JournalField("Strategy Name") {
                    SuggestingOptionalTextField(field: .strategyName, text: $trade.strategyName)
                        #if os(iOS)
                        .textFieldStyle(CustomTextFieldStyle())
                        #endif
                }
                
                JournalField("Setup Type") {
                    SuggestingOptionalTextField(field: .setupType, text: $trade.setupType)
                        #if os(iOS)
                        .textFieldStyle(CustomTextFieldStyle())
                        #endif
                }
                
                JournalField("Timeframe") {
                    SuggestingOptionalTextField(field: .timeframe, text: $trade.timeframe)
                        #if os(iOS)
                        .textFieldStyle(CustomTextFieldStyle())
                        #endif
                }
                
                JournalField("Thesis") {
                    TextField("", text: optionalTextBinding($trade.thesis))
                    #if os(iOS)
                    .textFieldStyle(CustomTextFieldStyle())
                    #endif
                }
                
                JournalField("Catalyst") {
                    SuggestingOptionalTextField(field: .catalyst, text: $trade.catalyst)
                    #if os(iOS)
                    .textFieldStyle(CustomTextFieldStyle())
                    #endif
                }
                
                Stepper("Confidence Score: \(trade.confidenceScore)", value: $trade.confidenceScore, in: 1...5)
                
                Toggle("A+ Setup", isOn: $trade.isAPlusSetup)
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
    GridItem(.adaptive(minimum: 150), spacing: 5)
]
#endif
}
