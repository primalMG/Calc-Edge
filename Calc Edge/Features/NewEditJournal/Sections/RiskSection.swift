import SwiftUI

struct RiskSection: View {
    @Bindable var trade: Trade
    @Binding var inEditMode: Bool

    var body: some View {
        riskSectionLayout {
            LazyVGrid(columns: columns, spacing: 12) {
                JournalField("Planned Risk Amount") {
                    TextField("", text: optionalDecimalBinding($trade.plannedRiskAmount))
                        #if os(iOS)
                        .textFieldStyle(CustomTextFieldStyle())
                        #endif
                }

                JournalField("Planned Risk Percent") {
                    TextField("", text: optionalDecimalBinding($trade.plannedRiskPercent))
                        #if os(iOS)
                        .textFieldStyle(CustomTextFieldStyle())
                        #endif
                }

                if inEditMode {
                    JournalField("Commissions") {
                        TextField("", text: optionalDecimalBinding($trade.commissions))
                            #if os(iOS)
                            .textFieldStyle(CustomTextFieldStyle())
                            #endif
                    }

                    JournalField("Slippage") {
                        TextField("", text: optionalDecimalBinding($trade.slippage))
                            #if os(iOS)
                            .textFieldStyle(CustomTextFieldStyle())
                            #endif
                    }

                    JournalField("MAE") {
                        TextField("", text: optionalDecimalBinding($trade.mae))
                            #if os(iOS)
                            .textFieldStyle(CustomTextFieldStyle())
                            #endif
                    }

                    JournalField("MFE") {
                        TextField("", text: optionalDecimalBinding($trade.mfe))
                            #if os(iOS)
                            .textFieldStyle(CustomTextFieldStyle())
                            #endif
                    }
                }
            }
        }
    }
    
    private func riskSectionLayout<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        #if os(macOS)
        JournalSectionContainer("Risk") {
            content()
        }
        #else
        content()
        #endif
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
