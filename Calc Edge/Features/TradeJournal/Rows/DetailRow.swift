//
//  DetailRow.swift
//  Calc Edge
//
//  Created by Marcus Gardner on 20/01/2026.
//

import SwiftUI

struct DetailRow: View {
    let label: String
    @Binding var value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            TextField(label, text: $value)
            
        }
    }
}
