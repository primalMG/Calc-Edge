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
        NavigationSplitView {
            RootSidebarView()
        } detail: {
            DashboardView()
        }
    }
}

#Preview {
    RootView()
        
}
