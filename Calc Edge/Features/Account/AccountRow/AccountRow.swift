//
//  AccountRow.swift
//  Calc Edge
//
//  Created by Marcus Gardner on 11/01/2026.
//

import SwiftUI
import SwiftData

struct AccountRow: View {
    @Bindable var account: Account

    @Environment(\.modelContext) private var modelContext

    @State private var deleteAction = false

    let onEdit: (Account) -> Void
    let onDelete: (String) -> Void

    var body: some View {
        VStack(alignment: .leading) {
            AccountRowHeader(account: account)
            AccountRowDetails(account: account)
            AccountRowActions(
                onEdit: { onEdit(account) },
                onDelete: { deleteAction = true }
            )
            .padding(.top, 5)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.gray.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal)
        #if os(macOS)
        .frame(minWidth: 700, idealWidth: 700)
        #endif
        .alert("Delete Account", isPresented: $deleteAction) {
            Button(role: .cancel) { }

            Button(role: .destructive) {
                delete()
            }
        }
    }

    private struct AccountLabel: View {
        let label: String
        let image: String
        let font: Font

        var body: some View {
            Label(label, systemImage: image)
                .font(font)
        }
    }

    private struct AccountRowHeader: View {
        @Bindable var account: Account

        var body: some View {
            VStack(alignment: .leading, spacing: 4) {
                AccountLabel(label: account.accountName, image: "person.crop.circle", font: .headline)
                AccountLabel(label: account.accountBroker, image: "building.columns", font: .subheadline)
            }
        }
    }

    private struct AccountRowDetails: View {
        @Bindable var account: Account

        var body: some View {
            VStack(alignment: .leading, spacing: 4) {
                Text("Account Details")
                    .font(.caption)
                    .padding(.top, 4)

                HStack(spacing: 15) {
                    Text("Currency: \(account.currency)")

                    HStack(spacing: 0) {
                        Text("Balance: ")
                        Text(account.accountSize.formatted())
                            .foregroundStyle(account.accountSize <= 0 ? .red : .green)
                    }
                }
                .font(.callout)
            }
        }
    }

    private struct AccountRowActions: View {
        let onEdit: () -> Void
        let onDelete: () -> Void

        var body: some View {
            HStack(spacing: 15) {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                }
                .help("Edit")
                .tint(.primary)

                Button(action: onDelete) {
                    Image(systemName: "trash.fill")
                }
                .tint(.red)
                .help("Delete")
            }
            .font(.footnote)
        }
    }

    private func delete() {
        let deletedAccountName = account.accountName
        modelContext.delete(account)
        onDelete(deletedAccountName)
    }
}

#Preview {
    AccountRow(
        account: Account(
            id: UUID(),
            accountName: "Options Account",
            accountBroker: "WeBull",
            accountSize: 100000,
            currency: "USD"
        ),
        onEdit: { _ in },
        onDelete: { _ in }
    )
}
