//   workoutLocations.swift
//   BigMetric
//
//   Created by: Grant Perry on 1/12/24 at 2:29 PM
//     Modified: 
//
//  Copyright © 2024 Delicious Studios, LLC. - Grant Perry
//

import SwiftUI
import Observation
import CoreLocation

@Observable
class WorkoutCoords: 	NSObject {
	var coords: [CLLocationCoordinate2D]?
}
