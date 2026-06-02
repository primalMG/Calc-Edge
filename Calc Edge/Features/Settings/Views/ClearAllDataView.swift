import SwiftData
import SwiftUI

struct ClearAllDataView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var isShowingConfirmation = false
    @State private var isClearingData = false
    @State private var toast: ToastConfiguration?

    var body: some View {
        #if os(iOS)
        List {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Label("Delete everything created in Calc Edge", systemImage: "trash.fill")
                        .font(.headline)
                        .foregroundStyle(.red)

                    Text("This removes journals, trade attachments, reviews, market context, transactions, value change logs, notes, accounts, rulebook entries, playbook setups, suggestions, stock calculations, and forex calculations.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            Section {
                Button(role: .destructive, action: presentConfirmation) {
                    if isClearingData {
                        Label("Clearing Data", systemImage: "hourglass")
                    } else {
                        Label("Clear All Data", systemImage: "trash")
                    }
                }
                .disabled(isClearingData)
                .confirmationDialog(
                    "Clear all app data?",
                    isPresented: $isShowingConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("Clear All Data", role: .destructive, action: clearAllData)
                    Button("Cancel", role: .cancel) { }
                } message: {
                    Text("This permanently deletes everything you have created in Calc Edge.")
                }
            } footer: {
                Text("This cannot be undone from inside the app. If iCloud sync is enabled, deletion may also sync to your private iCloud data.")
            }
        }
        .navigationTitle("Clear All Data")
        .toast($toast)
        #else
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header

                InfoSection(title: "Deletion Scope") {
                    Label("Delete everything created in Calc Edge", systemImage: "trash.fill")
                        .font(.headline)
                        .foregroundStyle(.red)

                    Text("This removes journals, trade attachments, reviews, market context, transactions, value change logs, notes, accounts, rulebook entries, playbook setups, suggestions, stock calculations, and forex calculations.")
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                InfoSection(title: "Before You Clear") {
                    ClearDataDetailRow(
                        title: "Cannot be undone",
                        detail: "Deleted records cannot be restored from inside Calc Edge."
                    )

                    Divider()

                    ClearDataDetailRow(
                        title: "iCloud sync",
                        detail: "If iCloud sync is enabled, deletion may also sync to your private iCloud data."
                    )
                }

                FormSectionContainer("Action", style: .info) {
                    Button(role: .destructive, action: presentConfirmation) {
                        if isClearingData {
                            Label("Clearing Data", systemImage: "hourglass")
                        } else {
                            Label("Clear All Data", systemImage: "trash")
                        }
                    }
                    .controlSize(.large)
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .disabled(isClearingData)
                }
            }
            .frame(maxWidth: 820, alignment: .leading)
            .padding()
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .navigationTitle("Clear All Data")
        .confirmationDialog(
            "Clear all app data?",
            isPresented: $isShowingConfirmation,
            titleVisibility: .visible
        ) {
            Button("Clear All Data", role: .destructive, action: clearAllData)
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This permanently deletes everything you have created in Calc Edge.")
        }
        .toast($toast)
        #endif
    }

    #if os(macOS)
    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Clear All Data")
                .font(.largeTitle)
                .fontWeight(.semibold)

            Text("Remove all journals, calculations, accounts, notes, and setup data from this app.")
                .foregroundStyle(.secondary)
        }
    }
    #endif

    private func presentConfirmation() {
        isShowingConfirmation = true
    }

    private func clearAllData() {
        isClearingData = true

        do {
            let deletedCount = try AppDataResetService.clearAllData(in: modelContext)
            isClearingData = false

            if deletedCount == 0 {
                toast = ToastConfiguration(
                    title: "No Data to Clear",
                    message: "There was no app-created data to delete.",
                    state: .info
                )
            } else {
                toast = ToastConfiguration(
                    title: "Data Cleared",
                    message: "Deleted \(deletedCount) records.",
                    state: .success
                )
            }
        } catch {
            isClearingData = false
            modelContext.rollback()
            toast = ToastConfiguration(
                title: "Clear Failed",
                message: error.localizedDescription,
                state: .error,
                duration: 4
            )
        }
    }
}

private struct ClearDataDetailRow: View {
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)

            Text(detail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    NavigationStack {
        ClearAllDataView()
    }
    .modelContainer(
        for: [
            Account.self,
            ForexCalculation.self,
            Note.self,
            Stock.self,
            Trade.self,
            TradeAttachment.self,
            TradeContext.self,
            TradeFieldSuggestion.self,
            TradeLeg.self,
            TradeReview.self,
            TradeRuleCheck.self,
            TradeTransaction.self,
            TradeValueChangeLog.self,
            TradingRule.self,
            TradingSetup.self
        ],
        inMemory: true
    )
}
