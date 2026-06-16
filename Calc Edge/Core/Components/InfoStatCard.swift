//
//  InfoStatCard.swift
//  Calc Edge
//
//  Created by Marcus Gardner on 05/02/2026.
//

import SwiftUI

struct InfoStatCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let accentColor: Color?

    init(title: String, value: String, subtitle: String? = nil, accentColor: Color? = nil) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.accentColor = accentColor
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(accentColor ?? .primary)

            if let subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        #if os(iOS)
        .background(.gray.secondary.opacity(0.5))
        #else
        .background(.regularMaterial)
        #endif
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(accessibilityValue)
    }

    private var accessibilityValue: String {
        if let subtitle {
            "\(value), \(subtitle)"
        } else {
            value
        }
    }
}
