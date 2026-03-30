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
            VStack(alignment: .leading, spacing: 10) {
                LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
                    JournalField("Ticker") {
                        TextField("", text: $trade.ticker)
                            .autocorrectionDisabled()
                        #if os(iOS)
                        .textInputAutocapitalization(.characters)
                        .textFieldStyle(CustomTextFieldStyle())
                        #endif
                    }

                    JournalField("Market") {
                        TextField("", text: optionalTextBinding($trade.market))
                        #if os(iOS)
                        .textFieldStyle(CustomTextFieldStyle())
                        #endif
                        
                    }

                    JournalField("Accounts") {
                        if !accounts.isEmpty {
                            Picker("", selection: $selectedAccountID) {
                                ForEach(accounts) { account in
                                    Text(account.accountName)
                                        .tag(account.id as Account.ID?)
                                }
                            }
                            .labelsHidden()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .onChange(of: selectedAccountID) { _, _ in
                                trade.account = selectedAccount.accountName
                            }
                        } else {
                            Text("No Accounts Found")
                                .font(.caption)
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
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    JournalField("Direction") {
                        Picker("", selection: $trade.direction) {
                            ForEach(TradeDirection.allCases, id: \.self) { direction in
                                Text(direction.rawValue.capitalized)
                                    .tag(direction)
                            }
                        }
                        .labelsHidden()
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if inEditMode {
                        JournalField("Closed Trade") {
                            Toggle("", isOn: closedTradeBinding)
                                .labelsHidden()
                        }
                    }
                }

                datePickersLayout {
                    JournalField("Opened At") {
                        DatePicker("", selection: $trade.openedAt, displayedComponents: [.date, .hourAndMinute])
                            .labelsHidden()
                            .datePickerStyle(.compact)
                    }

                    if inEditMode, trade.closedAt != nil {
                        JournalField("Closed At") {
                            DatePicker("", selection: closedAtBinding, displayedComponents: [.date, .hourAndMinute])
                                .labelsHidden()
                                .datePickerStyle(.compact)
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            }
        }
        .animation(.easeInOut, value: trade.closedAt != nil)
        .onAppear {
            if selectedAccountID == nil {
                selectedAccountID =
                    accounts.first(where: { $0.accountName == trade.account })?.id
                    ?? accounts.first?.id
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

    private var selectedAccountLabel: String {
        if let selectedAccountID,
           let account = accounts.first(where: { $0.id == selectedAccountID }) {
            return account.accountName
        }

        if let account = trade.account, !account.isEmpty {
            return account
        }

        return accounts.first?.accountName ?? "Select Account"
    }

    @ViewBuilder
    private func datePickersLayout<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        #if os(macOS)
        HStack(alignment: .top, spacing: 10) {
            content()
        }
        #else
        VStack(alignment: .leading, spacing: 10) {
            content()
        }
        #endif
    }

    #if os(macOS)
    private let columns = [
        GridItem(.adaptive(minimum: 180), spacing: 5),
        GridItem(.adaptive(minimum: 180), spacing: 5)
    ]
    #else
    private let columns = [
        GridItem(.adaptive(minimum: 200), spacing: 5),
        GridItem(.adaptive(minimum: 200), spacing: 5)
    ]
    #endif
}
