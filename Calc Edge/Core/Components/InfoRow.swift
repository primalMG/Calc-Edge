//
//  InfoRow.swift
//  Calc Edge
//
//  Created by Marcus Gardner on 05/02/2026.
//

import SwiftUI

struct InfoRow: View {
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .fontWeight(.medium)

            Spacer(minLength: 16)

            Text(detail)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
        }
        .font(.callout)
    }
}
