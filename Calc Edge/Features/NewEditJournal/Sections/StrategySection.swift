import SwiftUI

struct StrategySection: View {
    @Bindable var trade: Trade

    var body: some View {
        Section("Strategy") {
            LabeledContent("Strategy Name") {
                TextField("", text: optionalTextBinding($trade.strategyName))
            }

            LabeledContent("Setup Type") {
                TextField("", text: optionalTextBinding($trade.setupType))
            }

            LabeledContent("Timeframe") {
                TextField("", text: optionalTextBinding($trade.timeframe))
            }

            LabeledContent("Thesis") {
                TextField("", text: optionalTextBinding($trade.thesis))
            }

            LabeledContent("Catalyst") {
                TextField("", text: optionalTextBinding($trade.catalyst))
            }

            Stepper("Confidence Score: \(trade.confidenceScore)", value: $trade.confidenceScore, in: 1...5)

            Toggle("A+ Setup", isOn: $trade.isAPlusSetup)
        }
    }
}
