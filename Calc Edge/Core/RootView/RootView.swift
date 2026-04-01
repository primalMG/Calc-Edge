//
//  ContentView.swift
//  Calc Edge
//
//  Created by Marcus Gardner on 11/01/2026.
//

import SwiftUI
import SwiftData

struct RootView: View {
    
    var body: some View {
        rootViewLayout {
            RootSidebarView()
        }
    }
    
    @ViewBuilder
    private func rootViewLayout<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        #if os(macOS)
        NavigationSplitView {
            content()
        } detail: {
            DashboardView()
        }
        #else
        NavigationStack {
            content()
        }
        #endif
    }
}

#Preview {
    RootView()
}
