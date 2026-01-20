import SwiftUI

struct LegsSection: View {
    @Bindable var trade: Trade

    var body: some View {
        Section("Legs") {
            if trade.legs.isEmpty {
                Text("No legs added yet.")
                    .foregroundStyle(.secondary)
            }

            ForEach(trade.legs) { leg in
                TradeLegEditor(leg: leg) {
                    removeLeg(leg)
                }
            }

            Button("Add Leg") {
                trade.legs.append(TradeLeg())
            }
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

    var body: some View {
        DisclosureGroup(legTitle) {
            VStack(spacing: 12) {
                LabeledContent("Symbol") {
                    TextField("", text: optionalTextBinding($leg.symbol))
                }

                Picker("Instrument", selection: $leg.legInstrument) {
                    ForEach(InstrumentType.allCases, id: \.self) { instrument in
                        Text(instrument.rawValue.capitalized)
                            .tag(instrument)
                    }
                }

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

                DatePicker("Option Expiration", selection: optionExpirationBinding, displayedComponents: [.date])

                LabeledContent("Option Strike") {
                    TextField("", text: optionalDecimalBinding($leg.optionStrike))
                        .textFieldStyle(CustomTextFieldStyle())
                }

                LabeledContent("Option Type") {
                    TextField("", text: optionalTextBinding($leg.optionType))
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
