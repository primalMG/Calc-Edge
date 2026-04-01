//
//  Account.swift
//  Calc Edge
//
//  Created by Marcus Gardner on 11/01/2026.
//

import Foundation
import SwiftData

@Model
final class Account {
    var id: UUID = UUID()
    var accountName: String = ""
    var accountSize: Double = 0
    var currency: String = "USD"
    
    var stocks: [Stock]? = []
    
    init(id: UUID = UUID(),
         accountName: String = "",
         accountSize: Double = 0,
         currency: String = "USD",
         stocks: [Stock]? = []
    ) {
        self.id = id
        self.accountName = accountName
        self.accountSize = accountSize
        self.currency = currency
        self.stocks = stocks
    }
}
