import SwiftUI
import SwiftData

struct StrategySection: View {
    @Query(sort: \TradingSetup.name) private var setups: [TradingSetup]
    @Bindable var trade: Trade

    var body: some View {
        strategySectionLayout {
            if !activeSetups.isEmpty {
                Menu {
                    ForEach(activeSetups) { setup in
                        Button(setup.name.isEmpty ? "Untitled Setup" : setup.name) {
                            apply(setup)
                        }
                    }
                } label: {
                    Label("Apply Playbook Setup", systemImage: "rectangle.stack")
                }
                .buttonStyle(.bordered)
            }

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

                JournalField("Catalyst") {
                    SuggestingOptionalTextField(field: .catalyst, text: $trade.catalyst)
                    #if os(iOS)
                    .textFieldStyle(CustomTextFieldStyle())
                    #endif
                }
            }

            JournalField("Thesis") {
                TextField("", text: optionalTextBinding($trade.thesis))
                #if os(iOS)
                    .textFieldStyle(JournalCustomTextFieldStyle())
                #endif
            }

            Stepper("Confidence Score: \(trade.confidenceScore)", value: $trade.confidenceScore, in: 1...5)

            Toggle("A+ Setup", isOn: $trade.isAPlusSetup)
        }
    }

    private func strategySectionLayout<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        #if os(macOS)
        JournalSectionContainer("Strategy") {
            content()
        }
        #else
        content()
        #endif
    }

    private var activeSetups: [TradingSetup] {
        setups.filter(\.isActive)
    }

    private func apply(_ setup: TradingSetup) {
        if !setup.name.isEmpty {
            trade.setupType = setup.name
        }

        if let strategyName = setup.strategyName, !strategyName.isEmpty {
            trade.strategyName = strategyName
        }

        if let timeframe = setup.timeframe, !timeframe.isEmpty {
            trade.timeframe = timeframe
        }

        if let catalyst = setup.catalyst, !catalyst.isEmpty {
            trade.catalyst = catalyst
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
        GridItem(.adaptive(minimum: 150), spacing: 15, alignment: .topLeading)
    ]
    #endif
}

