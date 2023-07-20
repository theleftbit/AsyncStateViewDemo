//
//  ContentView.swift
//  AsyncStateViewDemo
//
//  Created by Pierluigi Cifani on 20/7/23.
//

import SwiftUI

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView(
      tabs: Tab.mockTabs()
    )
  }
}

struct ContentView: View {
  
  init(tabs: [Tab]) {
    self.tabs = tabs
    self.selectedTab = tabs.first!
  }
  
  var tabs: [Tab]
  @State var selectedTab: Tab
  
  var body: some View {
    AsyncStateView(id: $selectedTab.id) {
      await DataSource(withTab: selectedTab)
    } hostedViewGenerator: {
      TextView(dataSource: $0)
    } errorViewGenerator: {
      AsyncStatePlainErrorView(error: $0, onRetry: $1)
    } loadingViewGenerator: {
      LoadingView()
    }
    .safeAreaInset(edge: .top) {
      TabsView(tabs: tabs, selectedTab: $selectedTab)
        .background(.thinMaterial)
    }
  }
  
  private struct LoadingView: View {
    var body: some View {
      HStack(spacing: 8) {
        ProgressView()
        Text("Fetching Information...")
      }
        .frame(maxHeight: .infinity)
    }
  }
  
  private struct TextView: View {
  
    @ObservedObject var dataSource: DataSource
    
    var body: some View {
      ScrollView {
        Text(dataSource.content)
          .padding()
      }
    }
  }
  
  private struct TabsView: View {
    var tabs: [Tab]
    @Binding var selectedTab: Tab
    
    var body: some View {
      ScrollView(.horizontal) {
        HStack(alignment: .bottom, spacing: 0) {
          ForEach(tabs, id: \.title) { tab in
            Button {
              withAnimation {
                selectedTab = tab
              }
            } label: {
              Text(tab.title)
                .foregroundStyle(tab.id == selectedTab.id ? .blue : .primary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
                .overlay(alignment: .bottom) {
                  indicatorView(forTab: tab)
                }
            }
          }
        }
        .fixedSize(horizontal: false, vertical: true)
      }
      .onTapGesture {
        /// Isn't SwiftUI just magical?
        /// https://stackoverflow.com/a/72613194
      }
      .scrollIndicators(.hidden)
    }
    
    private func indicatorView(forTab tab: Tab) -> some View {
      Rectangle()
        .foregroundStyle(tab.id == selectedTab.id ? .blue : .clear)
        .frame(height: tab.id == selectedTab.id ? 4 : 1)
        .frame(maxWidth: .infinity)
    }
  }
  
}
