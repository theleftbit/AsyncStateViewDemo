//
//  DataSource.swift
//  AsyncStateViewDemo
//
//  Created by Pierluigi Cifani on 20/7/23.
//

import Foundation

class DataSource: ObservableObject {
  
  @Published var content: String
  
  init(withTab tab: Tab) async throws {
    try await Task.sleep(for: .seconds(1))
  
    switch tab.title {
    case Tab.Skate:
      content = "A skateboard is a type of sports equipment used for skateboarding. It is usually made of a specially designed 7–8-ply maple plywood deck and has polyurethane wheels attached to the underside by a pair of skateboarding trucks."
    case Tab.Bike:
      content = "A bicycle, also called a pedal cycle, bike, push-bike or cycle, is a human-powered or motor-powered assisted, pedal-driven, single-track vehicle, having two wheels attached to a frame, one behind the other. A bicycle rider is called a cyclist, or bicyclist."
    case Tab.Boat:
      content = "A boat is a watercraft of a large range of types and sizes, but generally smaller than a ship, which is distinguished by its larger size, shape, cargo or passenger capacity, or its ability to carry boats."
    case Tab.Plane:
      content = "An airplane (American English), or aeroplane (Commonwealth English), informally plane, is a fixed-wing aircraft that is propelled forward by thrust from a jet engine, propeller, or rocket engine. Airplanes come in a variety of sizes, shapes, and wing configurations."
    case Tab.Car:
      content = "A car or an automobile is a motor vehicle with wheels. Most definitions of cars say that they run primarily on roads, seat one to eight people, have four wheels, and mainly transport people, not cargo."
    default:
      content = "Don't know this one"
    }
  }
}

enum DisplayMode {
  case localContent
  case remoteContent
}

struct Tab: Identifiable, Equatable {
  let title: String
  var id: String {
    title
  }
  
  var displayMode: DisplayMode {
    switch self.title {
    case Tab.Feet:
      return .localContent
    default:
      return .remoteContent
    }
  }
  
  static func mockTabs() -> [Tab] {
    [
      .init(title: Skate),
      .init(title: Bike),
      .init(title: Car),
      .init(title: Boat),
      .init(title: Plane),
      .init(title: Feet),
    ]
  }
  
  static let Skate = "🛹 Skate"
  static let Bike = "🚴🏽‍♂️ Bike"
  static let Car = "🚗 Car"
  static let Boat = "🚢 Boat"
  static let Plane = "✈️ Plane"
  static let Feet = "👣 Feet"
}
