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
    @Binding var inEditMode: Bool
    @Query private var accounts: [Account]
    
    @State private var selectedAccountID: Account.ID?
    
    private var selectedAccount: Account {
        accounts.first(where: { $0.id == selectedAccountID })
        ?? accounts.first
        ?? Account(id: UUID(), accountName: "", accountSize: 0, currency: "")
    }
    
    var body: some View {
        JournalSectionContainer("Identification") {
            LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
                JournalField("Ticker") {
                    TextField("", text: $trade.ticker)
//                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
//                        .textFieldStyle(CustomTextFieldStyle())
                }

                JournalField("Market") {
                    TextField("", text: optionalTextBinding($trade.market))
//                        .textFieldStyle(CustomTextFieldStyle())
                }

                JournalField("Accounts") {
                    Picker("", selection: $selectedAccountID) {
                        ForEach(accounts) { account in
                            Text(account.accountName)
                                .tag(account.id as Account.ID?)
                        }
                    }
                    .labelsHidden()
                    .onChange(of: selectedAccountID) { _, _ in
                        trade.account = selectedAccount.accountName
                    }
                }

                JournalField("Instrument") {
                    Picker("", selection: $trade.instrument) {
                        ForEach(InstrumentType.allCases, id: \.self) { instrument in
                            Text(instrument.rawValue.capitalized)
                                .tag(instrument)
                        }
                    }
                    .labelsHidden()
                }
                
                JournalField("Direction") {
                    Picker("", selection: $trade.direction) {
                        ForEach(TradeDirection.allCases, id: \.self) { direction in
                            Text(direction.rawValue.capitalized)
                                .tag(direction)
                        }
                    }
                    .labelsHidden()
                }
                
                JournalField("Opened At") {
                    DatePicker("", selection: $trade.openedAt, displayedComponents: [.date, .hourAndMinute])
                        .labelsHidden()
                }
                
                if inEditMode {
                    JournalField("Closed Trade") {
                        Toggle("", isOn: closedTradeBinding)
                            .labelsHidden()
                    }
                    
                    if trade.closedAt != nil {
                        JournalField("Closed At") {
                            DatePicker("", selection: closedAtBinding, displayedComponents: [.date, .hourAndMinute])
                                .labelsHidden()
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            }
        }
        .animation(.easeInOut, value: trade.closedAt != nil)
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
                withAnimation(.easeInOut) {
                    if isClosed {
                        trade.closedAt = trade.closedAt ?? Date()
                    } else {
                        trade.closedAt = nil
                    }
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

    private let columns = [
        GridItem(.adaptive(minimum: 180), spacing: 5),
        GridItem(.adaptive(minimum: 180), spacing: 5)
    ]
}
