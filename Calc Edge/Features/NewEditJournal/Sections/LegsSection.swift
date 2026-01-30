import SwiftUI

struct LegsSection: View {
    @Bindable var trade: Trade

    var body: some View {
        JournalSectionContainer("Legs") {
            VStack(alignment: .leading) {
                Button("Add Leg") {
                    trade.legs.append(TradeLeg())
                }
                
                if trade.legs.isEmpty {
                    Text("No legs added yet.")
                        .foregroundStyle(.secondary)
                }
                
                ForEach(trade.legs) { leg in
                    TradeLegEditor(leg: leg) {
                        removeLeg(leg)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func removeLeg(_ leg: TradeLeg) {
        if let index = trade.legs.firstIndex(where: { $0 === leg }) {
            trade.legs.remove(at: index)
        }
    }
}

private struct TradeLegEditor: View {
    @Bindable var leg: TradeLeg
    let onRemove: () -> Void
    
    @State private var toggleSymbolPopover: Bool = false

    var body: some View {
        DisclosureGroup(legTitle) {
            Grid(alignment: .trailing, horizontalSpacing: 10, verticalSpacing: 10) {
                GridRow {
                    LabeledContent {
                        TextField("", text: optionalTextBinding($leg.symbol))
                            .textFieldStyle(CustomTextFieldStyle())
                    } label: {
                        Text("Symbol")
                        Button {
                            toggleSymbolPopover.toggle()
                        } label: {
                            Image(systemName: "info.bubble.fill.rtl")
                        }
                        .buttonStyle(.plain)
                        .popover(isPresented: $toggleSymbolPopover) {
                            Text("OCC or OSI Code")
                                .padding()
                        }
                    }
                    

                    Picker("Instrument", selection: $leg.legInstrument) {
                        ForEach(InstrumentType.allCases, id: \.self) { instrument in
                            Text(instrument.rawValue.capitalized)
                                .tag(instrument)
                        }
                    }
                }
                
                GridRow {
                    LabeledContent("Quantity") {
                        TextField("", text: decimalBinding($leg.quantity))
                            .textFieldStyle(CustomTextFieldStyle())
                    }

                    LabeledContent("Entry Price") {
                        TextField("", text: optionalDecimalBinding($leg.entryPrice))
                            .textFieldStyle(CustomTextFieldStyle())
                    }

                    LabeledContent("Exit Price") {
                        TextField("", text: optionalDecimalBinding($leg.exitPrice))
                            .textFieldStyle(CustomTextFieldStyle())
                    }
                }
                
                GridRow {
                    DatePicker("Option Expiration", selection: optionExpirationBinding, displayedComponents: [.date])
                }
                
                GridRow {
                    LabeledContent("Option Strike") {
                        TextField("", text: optionalDecimalBinding($leg.optionStrike))
                            .textFieldStyle(CustomTextFieldStyle())
                    }
                    
                    Picker("Option Type", selection: $leg.optionType) {
                        ForEach(OptionType.allCases, id: \.self) { type in
                            Text(type.rawValue)
                                .tag(type)
                        }
                    }

                }
                
                Button("Remove Leg") {
                    onRemove()
                }
                .tint(.red)
            }
            .padding(.top, 8)
        }
    }

    private var legTitle: String {
        if let symbol = leg.symbol, !symbol.isEmpty {
            return symbol
        }
        return "Trade Leg"
    }

    private var optionExpirationBinding: Binding<Date> {
        Binding(
            get: { leg.optionExpiration ?? Date() },
            set: { leg.optionExpiration = $0 }
        )
    }
}
