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
    let onEdit: (Account) -> Void
    
    
    var body: some View {
        HStack {
            Text(account.accountName)
            
            Text(account.currency)
            
            Text(account.accountSize.formatted())
            
            Button {
                onEdit(account)
            } label: {
                Image(systemName: "pencil")
            }
            .help("Edit")

            Button {
                delete()
            } label: {
                Image(systemName: "trash.fill")
            }
            .tint(.red)
            .help("Delete")
            
        }
        .padding()
        .frame(minWidth: 700, idealWidth: 700)
    }
    
    
    private func delete() {
        modelContext.delete(account)
    }
    
    
}

#Preview {
    AccountRow(account: Account(id: UUID(), accountName: "Webull", accountSize: 100000, currency: "USD", stocks: [Stock(ticker: "AAPL", entryPrice: 30.0, riskPercentage: 2, stopLoss: 28, shareCount: 10, targetPrice: 40)]), onEdit: { _ in})
}
