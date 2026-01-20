//
//  IdentificationSection.swift
//  Calc Edge
//
//  Created by Marcus Gardner on 20/01/2026.
//

import SwiftUI
import SwiftData

struct IdentificationSection: View {
    @Bindable var trade: Trade
    @Query private var accounts: [Account]
    
    @State private var selectedAccountID: Account.ID?
    
    private var selectedAccount: Account {
        accounts.first(where: { $0.id == selectedAccountID })
        ?? accounts.first
        ?? Account(id: UUID(), accountName: "", accountSize: 0, currency: "")
    }
    
    var body: some View {
        Section("Identification") {
            LabeledContent("Ticker") {
                TextField("", text: $trade.ticker)
//                            .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
            }

            LabeledContent("Market") {
                TextField("", text: optionalTextBinding($trade.market))
            }

            Picker("Accounts", selection: $selectedAccountID) {
                ForEach(accounts) { account in
                    Text(account.accountName)
                        .tag(account.id as Account.ID?)
                }
            }
            .onChange(of: selectedAccountID) { _, _ in
                trade.account = selectedAccount.accountName
            }

            Picker("Instrument", selection: $trade.instrument) {
                ForEach(InstrumentType.allCases, id: \.self) { instrument in
                    Text(instrument.rawValue.capitalized)
                        .tag(instrument)
                }
            }
            
            Picker("Direction", selection: $trade.direction) {
                ForEach(TradeDirection.allCases, id: \.self) { direction in
                    Text(direction.rawValue.capitalized)
                        .tag(direction)
                }
            }
            
            DatePicker("Opened At", selection: $trade.openedAt, displayedComponents: [.date, .hourAndMinute])

            Toggle("Closed Trade", isOn: closedTradeBinding)

            if trade.closedAt != nil {
                DatePicker("Closed At", selection: closedAtBinding, displayedComponents: [.date, .hourAndMinute])
            }
        }
        .onAppear {
            if selectedAccountID == nil {
                selectedAccountID = accounts.first?.id
            }
        }
    }
    
    private var closedTradeBinding: Binding<Bool> {
        Binding(
            get: { trade.closedAt != nil },
            set: { isClosed in
                if isClosed {
                    trade.closedAt = trade.closedAt ?? Date()
                } else {
                    trade.closedAt = nil
                }
            }
        )
    }

    private var closedAtBinding: Binding<Date> {
        Binding(
            get: { trade.closedAt ?? Date() },
            set: { trade.closedAt = $0 }
        )
    }
}
