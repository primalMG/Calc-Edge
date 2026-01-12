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
    var id: UUID
    var accountName: String
    var accountSize: Double
    var currency: String
    
    var stocks: [Stock]
    
    init(id: UUID,
         accountName: String,
         accountSize: Double,
         currency: String,
         stocks: [Stock] = []
    ) {
        self.id = id
        self.accountName = accountName
        self.accountSize = accountSize
        self.currency = currency
        self.stocks = stocks
    }
}
