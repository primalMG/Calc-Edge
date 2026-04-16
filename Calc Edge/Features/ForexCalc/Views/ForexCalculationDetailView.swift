import SwiftUI
import SwiftData

struct ForexCalculationDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var toggleAlert = false
    @State private var presentSheet = false

    @Bindable var calculation: ForexCalculation

    private let statColumns = [
        GridItem(.adaptive(minimum: 180), spacing: 12)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header

                InfoSection(title: "Overview") {
                    LazyVGrid(columns: statColumns, alignment: .leading, spacing: 12) {
                        ForEach(overviewCards) { card in
                            InfoStatCard(
                                title: card.title,
                                value: card.value,
                                subtitle: card.subtitle,
                                accentColor: card.accentColor
                            )
                        }
                    }
                }

                InfoSection(title: "Inputs") {
                    ForEach(inputRows, id: \.title) { row in
                        InfoRow(title: row.title, detail: row.detail)
                    }
                }

                if !resultRows.isEmpty {
                    InfoSection(title: "Calculated Results") {
                        ForEach(resultRows, id: \.title) { row in
                            InfoRow(title: row.title, detail: row.detail)
                        }
                    }
                }

                InfoSection(title: "Timeline") {
                    InfoRow(
                        title: "Created",
                        detail: calculation.createdAt.formatted(date: .abbreviated, time: .shortened)
                    )

                    if let updatedAt = calculation.updatedAt {
                        InfoRow(
                            title: "Updated",
                            detail: updatedAt.formatted(date: .abbreviated, time: .shortened)
                        )
                    }
                }
            }
            .padding()
        }
        .navigationTitle(calculation.normalizedPair.isEmpty ? "Forex Calc" : calculation.normalizedPair)
        .toolbar {
            ToolbarItemGroup {
                Button {
                    presentSheet.toggle()
                } label: {
                    Image(systemName: "pencil")
                }
                .help("Edit Calculation")
                .keyboardShortcut("E")
                .sheet(isPresented: $presentSheet) {
                    AddEditForexCalcView(calculation: calculation, isNew: false)
                }

                Button {
                    toggleAlert.toggle()
                } label: {
                    Image(systemName: "trash")
                }
                .help("Delete")
                .keyboardShortcut("D")
                .alert("Delete Calculation", isPresented: $toggleAlert) {
                    Button("Cancel", role: .cancel) { }
                    Button("Yes", role: .destructive) {
                        deleteCalculation()
                    }
                } message: {
                    Text("Are you sure you want to do this?")
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(calculation.normalizedPair.isEmpty ? "Forex Calculation" : calculation.normalizedPair)
                .font(.largeTitle)
                .fontWeight(.semibold)

            Text("\(calculation.calculator.displayName) for \(calculation.accountCurrency) account planning.")
                .foregroundStyle(.secondary)
        }
    }

    private var overviewCards: [DetailCard] {
        switch calculation.calculator {
        case .pipValue:
            [
                DetailCard(title: "Pip Value", value: format(calculation.totalPipValue), accentColor: .green),
                DetailCard(title: "Pip Size", value: format(calculation.pipSize), accentColor: nil),
                DetailCard(title: marketRateTitle, value: format(calculation.marketPairRate), accentColor: nil),
                DetailCard(title: quoteToAccountTitle, value: format(calculation.effectiveQuoteToAccountRate), accentColor: nil)
            ]
        case .positionSize:
            [
                DetailCard(title: "Risk Amount", value: format(calculation.derivedRiskAmount), accentColor: .red),
                DetailCard(title: "Position Size", value: format(calculation.derivedPositionSizeUnits), accentColor: .green),
                DetailCard(title: "Stop Loss (Pips)", value: format(calculation.derivedStopLossPips), accentColor: nil),
                DetailCard(title: "Pip Value / Unit", value: format(calculation.pipValuePerUnit), accentColor: nil)
            ]
        case .margin:
            [
                DetailCard(title: "Margin Required", value: format(calculation.derivedMarginRequired), accentColor: .orange),
                DetailCard(title: "Units", value: format(calculation.derivedUnits), accentColor: nil),
                DetailCard(title: "Leverage", value: format(calculation.leverage), accentColor: nil),
                DetailCard(title: "Entry Price", value: format(calculation.entryPrice), accentColor: nil)
            ]
        case .riskReward:
            [
                DetailCard(title: "Risk / Reward", value: format(calculation.derivedRiskRewardRatio), accentColor: .green),
                DetailCard(title: "Stop Loss (Pips)", value: format(calculation.derivedStopLossPips), accentColor: .red),
                DetailCard(title: "Take Profit (Pips)", value: format(calculation.derivedTakeProfitPips), accentColor: .green),
                DetailCard(title: "Pip Size", value: format(calculation.pipSize), accentColor: nil)
            ]
        }
    }

    private var inputRows: [DetailRowValue] {
        var rows: [DetailRowValue] = [
            .init(title: "Calculator Type", detail: calculation.calculator.displayName),
            .init(title: "Pair", detail: calculation.normalizedPair),
            .init(title: "Account Currency", detail: calculation.accountCurrency)
        ]

        appendRow(&rows, title: "Account Balance", value: calculation.accountBalance)
        appendRow(&rows, title: "Risk Percent", value: calculation.riskPercent)
        appendRow(&rows, title: "Risk Amount", value: calculation.derivedRiskAmount)
        appendRow(&rows, title: "Entry Price", value: calculation.entryPrice)
        appendRow(&rows, title: "Stop Loss Price", value: calculation.stopLossPrice)
        appendRow(&rows, title: "Stop Loss (Pips)", value: calculation.stopLossPips)
        appendRow(&rows, title: "Take Profit Price", value: calculation.takeProfitPrice)
        appendRow(&rows, title: "Take Profit (Pips)", value: calculation.takeProfitPips)
        appendRow(&rows, title: "Lot Size", value: calculation.lotSize)
        if calculation.calculator != .pipValue {
            appendRow(&rows, title: "Units", value: calculation.units)
        }
        appendRow(&rows, title: "Leverage", value: calculation.leverage)
        appendRow(&rows, title: marketRateTitle, value: calculation.marketPairRate)
        appendRow(&rows, title: quoteToAccountTitle, value: calculation.quoteToAccountRate)
        appendRow(&rows, title: "Pip Size", value: calculation.pipSizeOverride)

        return rows
    }

    private var resultRows: [DetailRowValue] {
        let rows: [DetailRowValue] = switch calculation.calculator {
        case .pipValue:
            [
                .init(title: "Pip Value / Unit", detail: format(calculation.pipValuePerUnit)),
                .init(title: "Total Pip Value", detail: format(calculation.totalPipValue))
            ]
        case .positionSize:
            [
                .init(title: "Derived Risk Amount", detail: format(calculation.derivedRiskAmount)),
                .init(title: "Derived Stop Loss (Pips)", detail: format(calculation.derivedStopLossPips)),
                .init(title: "Pip Value / Unit", detail: format(calculation.pipValuePerUnit)),
                .init(title: "Position Size Units", detail: format(calculation.derivedPositionSizeUnits))
            ]
        case .margin:
            [
                .init(title: "Derived Units", detail: format(calculation.derivedUnits)),
                .init(title: "Margin Required", detail: format(calculation.derivedMarginRequired))
            ]
        case .riskReward:
            [
                .init(title: "Derived Stop Loss (Pips)", detail: format(calculation.derivedStopLossPips)),
                .init(title: "Derived Take Profit (Pips)", detail: format(calculation.derivedTakeProfitPips)),
                .init(title: "Risk / Reward Ratio", detail: format(calculation.derivedRiskRewardRatio))
            ]
        }

        return rows.filter { $0.detail != "N/A" }
    }

    private var quoteToAccountTitle: String {
        let quote = calculation.quoteCurrency ?? "QUOTE"
        return "Quote / Account Rate (\(quote) -> \(calculation.accountCurrency))"
    }

    private var marketRateTitle: String {
        let base = calculation.baseCurrency ?? "BASE"
        let quote = calculation.quoteCurrency ?? "QUOTE"
        return "Market Rate (\(base)/\(quote))"
    }

    private func appendRow(_ rows: inout [DetailRowValue], title: String, value: Decimal?) {
        guard let value else { return }
        rows.append(.init(title: title, detail: format(value)))
    }

    private func format(_ value: Decimal?) -> String {
        guard let value else { return "N/A" }
        return NSDecimalNumber(decimal: value).stringValue
    }

    private func deleteCalculation() {
        withAnimation {
            modelContext.delete(calculation)
            try? modelContext.save()
        }
        dismiss()
    }
}

private struct DetailCard: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let subtitle: String?
    let accentColor: Color?

    init(title: String, value: String, subtitle: String? = nil, accentColor: Color?) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.accentColor = accentColor
    }
}

private struct DetailRowValue {
    let title: String
    let detail: String
}

#Preview {
    ForexCalculationDetailView(calculation: ForexCalculation(calculator: .positionSize, pair: "EURUSD", accountBalance: 10000, riskPercent: 1, entryPrice: 1.1050, stopLossPrice: 1.1000, quoteToAccountRate: 1))
        .modelContainer(for: ForexCalculation.self, inMemory: true)
}
