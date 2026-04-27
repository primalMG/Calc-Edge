import SwiftUI

struct LegsSection: View {
    @Bindable var trade: Trade
    
    private var legs: [TradeLeg] {
        trade.legs ?? []
    }

    var body: some View {
        JournalSectionContainer("Legs") {
            VStack(alignment: .leading) {
                Button("Add Leg") {
                    if trade.legs == nil {
                        trade.legs = []
                    }
                    trade.legs?.append(TradeLeg())
                }
                #if os(iOS)
                .padding(EdgeInsets(top: 5, leading: 8, bottom: 5, trailing: 8))
                .buttonStyle(.plain)
                .background(.green.gradient)
                .clipShape(Capsule())
                #endif
                .padding(.bottom, 10)
                
                if legs.isEmpty {
                    Text("No legs added yet.")
                        .foregroundStyle(.secondary)
                }
                
                ForEach(legs) { leg in
                    TradeLegEditor(leg: leg) {
                        removeLeg(leg)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func removeLeg(_ leg: TradeLeg) {
        if let index = trade.legs?.firstIndex(where: { $0 === leg }) {
            trade.legs?.remove(at: index)
        }
    }
}

private struct TradeLegEditor: View {
    @Bindable var leg: TradeLeg
    let onRemove: () -> Void
    
    @State private var isExpanded: Bool = false
    @State private var toggleSymbolPopover: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .rotationEffect(.degrees(isExpanded ? 90 : 0))
                            .frame(width: 24, height: 24)

                        Text(legTitle)
                            .font(.headline)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isExpanded ? "Collapse \(legTitle)" : "Expand \(legTitle)")

                Spacer(minLength: 0)
            }

            if isExpanded {
                Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 10) {
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
                        .pickerStyle(.menu)
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
                        .pickerStyle(.menu)
                    }

                    Button("Remove Leg") {
                        onRemove()
                    }
                    #if os(iOS)
                    .padding(EdgeInsets(top: 5, leading: 8, bottom: 5, trailing: 8))
                    .buttonStyle(.plain)
                    .background(.red.gradient)
                    .clipShape(Capsule())
                    #else
                    .tint(.red)
                    #endif
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
