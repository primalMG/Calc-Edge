//
//  ForexCalcView.swift
//  Calc Edge
//
//  Created by Marcus Gardner on 03/02/2026.
//

import SwiftUI
import SwiftData

struct ForexCalcView: View {
    @Query(sort: \ForexCalculation.createdAt, order: .reverse) private var calculations: [ForexCalculation]
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        NavigationStack {
            Group {
                if calculations.isEmpty {
                    VStack(spacing: 12) {
                        Text("Forex Calc")
                            .font(.largeTitle)

                        Text("No calculations yet.")
                            .foregroundStyle(.secondary)

                        Button("New Calculation") {
                            openWindow(id: "new-forex-calc")
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(calculations) { calculation in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(calculation.normalizedPair)
                                        .font(.headline)
                                    Text(calculation.calculator.displayName)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Text(calculation.createdAt.formatted(date: .abbreviated, time: .omitted))
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("Forex Calc")
            .toolbar {
                ToolbarItem {
                    Button {
                        openWindow(id: "new-forex-calc")
                    } label: {
                        Image(systemName: "plus")
                    }
                    .help("New Calculation")
                }
            }
        }
    }
}

#Preview {
    ForexCalcView()
}
