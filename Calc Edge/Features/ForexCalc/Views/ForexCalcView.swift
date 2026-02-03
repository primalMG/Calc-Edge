//
//  ForexCalcView.swift
//  Calc Edge
//
//  Created by Marcus Gardner on 03/02/2026.
//

import SwiftUI

struct ForexCalcView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Forex Calc")
                    .font(.largeTitle)

                Text("Coming soon.")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .navigationTitle("Forex Calc")
        }
    }
}

#Preview {
    ForexCalcView()
}
