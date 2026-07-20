import SwiftUI

struct DataResetSceneContent: View {
    let phase: AppDataResetPhase

    var body: some View {
        VStack(spacing: 12) {
            ProgressView()

            Text(phase == .deleting ? "Deleting App Data…" : "Preparing to Clear Data…")
                .font(.headline)

            Text("Calc Edge is closing open records before deleting them.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#if os(macOS)
struct NewJournalSceneContent: View {
    @State private var trade = Trade(ticker: "")

    var body: some View {
        NewJournalView(trade: trade)
    }
}

struct NewForexCalculationSceneContent: View {
    @State private var calculation = ForexCalculation.emptyDraft

    var body: some View {
        AddEditForexCalcView(calculation: calculation, isNew: true)
    }
}
#endif
