//
//  ForexCalcView.swift
//  Calc Edge
//
//  Created by Marcus Gardner on 03/02/2026.
//

import SwiftUI
import SwiftData

struct ForexCalcView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ForexCalculation.createdAt, order: .reverse) private var calculations: [ForexCalculation]

    @State private var draftCalculation = ForexCalculation.emptyDraft
    @State private var presentSheet = false
    #if os(macOS)
    @State private var selectedCalculationID: UUID?
    #endif

    var body: some View {
        listContent
            .navigationTitle("Forex Calc")
            .toolbar {
                ToolbarItemGroup {
                    Button {
                        draftCalculation = .emptyDraft
                        presentSheet = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                    .help("New Calculation")
                    .sheet(isPresented: $presentSheet) {
                        AddEditForexCalcView(calculation: draftCalculation, isNew: true)
                    }
                }
            }
            #if os(macOS)
            .inspector(isPresented: inspectorIsPresented) {
                if let inspectorCalculation {
                    ForexCalculationDetailView(calculation: inspectorCalculation)
                        .inspectorColumnWidth(min: 450, ideal: 540, max: 800)
                } else {
                    ContentUnavailableView("Select a Calculation", systemImage: "dollarsign.circle")
                        .inspectorColumnWidth(min: 450, ideal: 540, max: 800)
                }
            }
            .frame(minWidth: 300, idealWidth: 320)
            .onAppear(perform: syncInitialSelection)
            .onChange(of: selectedCalculationID, updateSelection)
            .onChange(of: calculations.count) { _, _ in
                keepSelectionInSync()
            }
            #endif
    }

    #if os(macOS)
    private var inspectorCalculation: ForexCalculation? {
        guard let selectedCalculationID else { return nil }
        return calculations.first(where: { $0.id == selectedCalculationID })
    }

    private var inspectorIsPresented: Binding<Bool> {
        Binding(
            get: { selectedCalculationID != nil },
            set: { isPresented in
                if !isPresented {
                    selectedCalculationID = nil
                }
            }
        )
    }
    #endif

    @ViewBuilder
    private var listContent: some View {
        if calculations.isEmpty {
            ContentUnavailableView(
                "No Forex Calculations",
                systemImage: "dollarsign.circle",
                description: Text("Create a calculation to review pip value, position size, margin, or risk / reward.")
            )
        } else {
            #if os(macOS)
            List(selection: $selectedCalculationID) {
                ForEach(calculations) { calculation in
                    ForexCalcRow(calculation: calculation)
                        .tag(calculation.id)
                }
                .onDelete(perform: deleteItems)
            }
            #else
            List {
                ForEach(calculations) { calculation in
                    NavigationLink {
                        ForexCalculationDetailView(calculation: calculation)
                    } label: {
                        ForexCalcRow(calculation: calculation)
                    }
                }
                .onDelete(perform: deleteItems)
            }
            #endif
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                #if os(macOS)
                if calculations[index].id == selectedCalculationID {
                    selectedCalculationID = nil
                }
                #endif
                modelContext.delete(calculations[index])
            }
        }
    }

    #if os(macOS)
    private func syncInitialSelection() {
        if selectedCalculationID == nil {
            selectedCalculationID = calculations.first?.id
        }
    }

    private func updateSelection(oldValue: UUID?, newValue: UUID?) {
        guard let newValue,
              calculations.contains(where: { $0.id == newValue }) else {
            return
        }
    }

    private func keepSelectionInSync() {
        if let selectedCalculationID,
           calculations.contains(where: { $0.id == selectedCalculationID }) {
            return
        }

        self.selectedCalculationID = calculations.first?.id
    }
    #endif
}

private struct ForexCalcRow: View {
    let calculation: ForexCalculation

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(calculation.normalizedPair.isEmpty ? "New Pair" : calculation.normalizedPair)
                    .font(.headline)

                Spacer()

                if let updatedAt = calculation.updatedAt {
                    Text("Updated \(updatedAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 12) {
                Label(calculation.calculator.displayName, systemImage: "dial.medium")
                Label(calculation.accountCurrency, systemImage: "dollarsign.circle")

                if let summaryValue = summaryValue {
                    Label(summaryValue, systemImage: "chart.line.uptrend.xyaxis")
                }
            }
            .font(.subheadline)

            Text("Created \(calculation.createdAt.formatted(date: .abbreviated, time: .omitted))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private var summaryValue: String? {
        switch calculation.calculator {
        case .pipValue:
            return calculation.totalPipValue.map { "Pip Value \(formatDecimal($0))" }
        case .positionSize:
            return calculation.derivedPositionSizeUnits.map { "Units \(formatDecimal($0))" }
        case .margin:
            return calculation.derivedMarginRequiredInt.map { "Margin \($0)" }
        case .riskReward:
            return calculation.derivedRiskRewardRatio.map { "R:R \(formatDecimal($0))" }
        }
    }

    private func formatDecimal(_ value: Decimal) -> String {
        ValueDisplayFormatter.decimal(value)
    }
}

#Preview {
    ForexCalcView()
        .modelContainer(for: ForexCalculation.self, inMemory: true)
}
