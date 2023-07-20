
import SwiftUI

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
    /// Simulate a network fetch...
    try await Task.sleep(for: .seconds(1))
    return Tab.mockTabs()
  }
}
