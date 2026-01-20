//
//  DetailSection.swift
//  Calc Edge
//
//  Created by Marcus Gardner on 20/01/2026.
//

import SwiftUI

struct DetailSection<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            content
        }
    }
}
