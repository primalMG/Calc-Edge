//
//  RiskCalcView.swift
//  Calc Edge
//
//  Created by Marcus Gardner on 12/01/2026.
//

import SwiftUI
import SwiftData

struct NewEditRiskCalc: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var accounts: [Account]

    @Bindable var stock: Stock
    let isNew: Bool

    @State private var selectedAccountID: Account.ID?
    @State private var toast: ToastConfiguration?
    @State private var didInsertNewStock = false

    private var selectedAccount: Account? {
        accounts.first(where: { $0.id == selectedAccountID }) ?? accounts.first
    }

    private var selectedAccountSize: Double {
        selectedAccount?.accountSize ?? 0
    }

    private var shareCount: Double {
        guard stock.entryPrice != 0 else {
            return 0
        }

        return calcRiskAmount / stock.entryPrice
    }

    private var calcRiskAmount: Double {
        selectedAccountSize * (stock.riskPercentage / 100)
    }

    private var lossDifference: Double {
        stock.entryPrice - stock.stopLoss
    }

    private var lossTotal: Double {
        lossDifference * shareCount
    }

    private var profitDifference: Double {
        stock.targetPrice - stock.entryPrice
    }

    private var profitTotal: Double {
        profitDifference * shareCount
    }

    private var riskRewardRatio: Double {
        lossTotal == 0 ? 0 : profitTotal / lossTotal
    }

    private var displayRiskAmount: Double? {
        guard selectedAccount != nil, selectedAccountSize > 0, stock.riskPercentage > 0 else {
            return nil
        }

        return calcRiskAmount
    }

    private var displayShareCount: Double? {
        guard let riskAmount = displayRiskAmount, stock.entryPrice > 0 else {
            return nil
        }

        return riskAmount / stock.entryPrice
    }

    private var displayLossDifference: Double? {
        guard stock.entryPrice > 0, stock.stopLoss > 0 else {
            return nil
        }

        return stock.entryPrice - stock.stopLoss
    }

    private var displayLossTotal: Double? {
        guard let lossDifference = displayLossDifference, let shareCount = displayShareCount else {
            return nil
        }

        return lossDifference * shareCount
    }

    private var displayProfitDifference: Double? {
        guard stock.entryPrice > 0, stock.targetPrice > 0 else {
            return nil
        }

        return stock.targetPrice - stock.entryPrice
    }

    private var displayProfitTotal: Double? {
        guard let profitDifference = displayProfitDifference, let shareCount = displayShareCount else {
            return nil
        }

        return profitDifference * shareCount
    }

    private var displayRiskRewardRatio: Double? {
        guard let lossTotal = displayLossTotal,
              let profitTotal = displayProfitTotal,
              lossTotal != 0 else {
            return nil
        }

        return profitTotal / lossTotal
    }

    var body: some View {
        content
            .onAppear(perform: configureInitialAccountSelection)
            .toast($toast)
    }

    @ViewBuilder
    private var content: some View {
        #if os(iOS)
        NavigationStack {
            formContent
        }
        #else
        formContent
        #endif
    }

    private var formContent: some View {
        Form {
            RiskCalcAccountSection(
                accounts: accounts,
                selectedAccountID: $selectedAccountID,
                riskPercentage: $stock.riskPercentage,
                displayAccountBalance: displayAccountBalance
            )

            RiskCalcStockDetailsSection(stock: stock)
            RiskCalcLossInputsSection(stopLoss: $stock.stopLoss)
            RiskCalcProfitInputsSection(targetPrice: $stock.targetPrice)

            RiskCalcLiveResultsSection(
                riskAmount: displayRiskAmount,
                shareCount: displayShareCount,
                lossDifference: displayLossDifference,
                lossTotal: displayLossTotal,
                profitDifference: displayProfitDifference,
                profitTotal: displayProfitTotal,
                riskRewardRatio: displayRiskRewardRatio
            )

            RiskCalcActionSection(
                onSave: save,
                onCancel: { dismiss() }
            )
        }
        #if os(iOS)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
                .tint(.red)
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("Save", action: save)
                    .tint(.green)
            }
        }
        #endif
        #if os(macOS)
        .padding()
        .frame(minWidth: 360, idealWidth: 520, maxWidth: 680)
        .frame(minHeight: 600)
        #endif
    }

    private func configureInitialAccountSelection() {
        if selectedAccountID == nil {
            selectedAccountID = accounts.first?.id
        }
    }

    private var displayAccountBalance: String {
        guard let selectedAccount else {
            return "No account selected"
        }

        return "\(selectedAccount.currency.uppercased()), \(ValueDisplayFormatter.double(selectedAccount.accountSize))"
    }

    private func save() {
        stock.ticker = stock.ticker
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()

        guard !stock.ticker.isEmpty else {
            toast = ToastConfiguration(
                title: "Ticker Required",
                message: "Enter a ticker before saving this risk calculation.",
                state: .warning
            )
            return
        }

        applyCalculatedStockSnapshot()

        do {
            if isNew {
                if !didInsertNewStock {
                    modelContext.insert(stock)
                    didInsertNewStock = true
                } else {
                    stock.updatedAt = .now
                }
            } else {
                stock.updatedAt = .now
            }

            try modelContext.save()

            toast = ToastConfiguration(
                title: "Calculation Saved",
                message: "Your risk calculation has been saved.",
                state: .success
            )
        } catch {
            toast = ToastConfiguration(
                title: "Save Failed",
                message: error.localizedDescription,
                state: .error,
                duration: 4
            )
        }
    }

    private func applyCalculatedStockSnapshot() {
        stock.shareCount = shareCount
        stock.amountRisked = calcRiskAmount
        stock.account = selectedAccount
        stock.accountUsed = selectedAccount?.accountName ?? ""
        stock.balanceAtTrade = selectedAccount?.accountSize ?? 0
        stock.lossDiffernce = lossDifference
        stock.lossTotal = lossTotal
        stock.profitDifference = profitDifference
        stock.profitTotal = profitTotal
        stock.riskRewardRatio = riskRewardRatio
    }
}

#Preview {
    NewEditRiskCalc(
        stock: Stock(
            ticker: "DAL",
            entryPrice: 47.5,
            riskPercentage: 1,
            stopLoss: 45.5,
            shareCount: 2,
            targetPrice: 55.5,
            accountUsed: "WeBull",
            balanceAtTrade: 5000,
            amountRisked: 100
        ),
        isNew: true
    )
    .modelContainer(for: Account.self, inMemory: true)
}
