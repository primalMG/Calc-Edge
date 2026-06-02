//
//  InfoSection.swift
//  Calc Edge
//
//  Created by Marcus Gardner on 05/02/2026.
//

import SwiftUI

struct InfoSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        FormSectionContainer(title, style: .info) {
            content
        }
    }
}
