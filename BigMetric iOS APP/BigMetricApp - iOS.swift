//
//  BigMetricApp.swift
//  BigMetric
//
//  Created by Grant Perry on 5/25/23.
//

import SwiftUI
import CoreLocation

var holdRouteCoords: [CLLocationCoordinate2D]?

@main
struct BigMetricApp: App {
    var body: some Scene {
        WindowGroup {
            PolyMapView()
        }
    }
}
