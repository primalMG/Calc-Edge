//
//  StaticProperties.swift
//  Calc Edge
//
//  Created by Marcus Gardner on 12/01/2026.
//

import Foundation


public let currencies = ["USD","GBP","EUR","JPY","CAD"]


public let doubleFormatter: NumberFormatter = {
    let f = NumberFormatter()
    f.numberStyle = .decimal
    f.maximumFractionDigits = 2
    f.minimumFractionDigits = 0
    f.generatesDecimalNumbers = true
    return f
}()
