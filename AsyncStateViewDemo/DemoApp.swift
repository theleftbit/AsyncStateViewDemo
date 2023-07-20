//
//  AsyncStateViewDemoApp.swift
//  AsyncStateViewDemo
//
//  Created by Pierluigi Cifani on 20/7/23.
//

import SwiftUI

@main
struct DemoApp: App {
  var body: some Scene {
    WindowGroup {
      RootView()
    }
  }
}

struct RootView: View {
  var body: some View {
    AsyncStateView(id: "root-view") {
      try await RootView.fetchTabs()
    } hostedViewGenerator: {
      ContentView(tabs: $0)
    } errorViewGenerator: { error, _ in
      Text("Error Loading Initial Tabs")
    } loadingViewGenerator: {
      ProgressView()
    }
  }
  
  static func fetchTabs() async throws -> [Tab] {
    try await Task.sleep(for: .seconds(1))
    return Tab.mockTabs()
  }
}
