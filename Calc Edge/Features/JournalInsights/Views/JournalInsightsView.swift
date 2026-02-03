//
//  JournalInsightsView.swift
//  Calc Edge
//
//  Created by Marcus Gardner on 03/02/2026.
//

import SwiftUI

struct JournalInsightsView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Journal Insights")
                    .font(.largeTitle)

                Text("AI insights coming soon.")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .navigationTitle("Journal Insights")
        }
    }
}

#Preview {
    JournalInsightsView()
}
