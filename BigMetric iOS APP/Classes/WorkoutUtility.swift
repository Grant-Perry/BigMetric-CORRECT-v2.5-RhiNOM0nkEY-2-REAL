//   WorkoutUtility.swift
//   BigMetric
//
//   Created by: Grant Perry on 2/7/24 at 11:53 AM
//     Modified: 
//
//  Copyright © 2024 Delicious Studios, LLC. - Grant Perry
//

import SwiftUI
import Observation
import HealthKit
import CoreLocation

@Observable
class WorkoutUtility {
	var numRouteCoords: Int = 0
	var workoutDistance: Double? = nil

	public func getWorkoutDistance(_ thisWorkout: HKWorkout) async throws -> Double {
		guard let route = await getWorkoutRoute(workout: thisWorkout)?.first else {
			return 0
		}
		// get the coordinates of the last workout
		let coords = await getCLocationDataForRoute(routeToExtract: route)
		var longitude = coords.last?.coordinate.longitude
		var latitude = coords.last?.coordinate.latitude
		return coords.calcDistance
		//		return await getCLocationDataForRoute(routeToExtract: route).calcDistance
	}

	public func getWorkoutCoords(_ thisWorkout: HKWorkout) async throws -> CLLocationCoordinate2D {
		guard let route = await getWorkoutRoute(workout: thisWorkout)?.first else {
			throw CustomErrors.routeNotFound
		}
		let coords = await getCLocationDataForRoute(routeToExtract: route)
		guard let lastCoordinate = coords.last?.coordinate else {
			throw CustomErrors.coordinatesNotFound
		}
		return lastCoordinate
	}

	func formatDate(workout: HKWorkout) -> String {
		let dateToStringFormatter = DateFormatter()
		dateToStringFormatter.timeStyle 	= .short
		dateToStringFormatter.dateStyle 	= .short
		return dateToStringFormatter.string(from: workout.startDate)
	}

	func calcNumCoords(_ work: HKWorkout) async -> Int {
		guard let route = await getWorkoutRoute(workout: work)?.first else {
			return 0
		}
		let locations = await getCLocationDataForRoute(routeToExtract: route)
		let filteredLocations = locations.filter { $0.coordinate.latitude != 0 || $0.coordinate.longitude != 0 }
		return filteredLocations.count
	}

	func filterWorkoutsWithCoords(_ workouts: [HKWorkout]) async -> [HKWorkout] {
		var filteredWorkouts: [HKWorkout] = []
		for workout in workouts {
			if await calcNumCoords(workout) > 0 {
				filteredWorkouts.append(workout)
			}
		}
		return filteredWorkouts
	}

}

