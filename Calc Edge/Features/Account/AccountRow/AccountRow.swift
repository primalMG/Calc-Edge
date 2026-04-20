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
    
    @State private var editMode: Bool = false
    @State private var deleteAction: Bool = false
    
    let onEdit: (Account) -> Void
    
    
    var body: some View {
        VStack(alignment: .leading)  {
            
            AccountLabel(label: account.accountName, image: "person.crop.circle", font: .headline)
                
            AccountLabel(label: account.accountBroker, image: "building.columns", font: .subheadline)
            
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
            
            HStack(spacing: 15) {
                Button {
                    onEdit(account)
                } label: {
                    Image(systemName: "pencil")
                }
                .help("Edit")
                .tint(.primary)
                
                Button {
                    deleteAction = true
                } label: {
                    Image(systemName: "trash.fill")
                }
                .tint(.red)
                .help("Delete")
                .alert("Delete Account", isPresented: $deleteAction) {
                    Button(role: .cancel) { }
                    
                    Button(role: .destructive) { delete() }
                }
            }
            .padding(.top, 5)
            .font(.footnote)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.gray.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding()
        #if os(macOS)
        .frame(minWidth: 700, idealWidth: 700)
        #endif
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
    
    
    private func delete() {
        modelContext.delete(account)
    }
    
    
}

#Preview {
    AccountRow(account: Account(id: UUID(), accountName: "Options Account", accountBroker: "WeBull", accountSize: 100000, currency: "USD", stocks: [Stock(ticker: "DAL", entryPrice: 47.5, riskPercentage: 1, stopLoss: 45.5, shareCount: 2.8, targetPrice: 55.5, accountUsed: "WeBull", balanceAtTrade: 5000, amountRisked: 100)]), onEdit: { _ in})
}
