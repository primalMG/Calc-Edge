import SwiftUI

struct PricesSection: View {
    @Bindable var trade: Trade

    var body: some View {
        JournalSectionContainer("Prices") {
            LazyVGrid(columns: columns, spacing: 12) {
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
        GridItem(.flexible(minimum: 140), spacing: 12)
    ]
    #else
    private let columns = [
        GridItem(.adaptive(minimum: 150), spacing: 5)
    ]
    #endif
}
