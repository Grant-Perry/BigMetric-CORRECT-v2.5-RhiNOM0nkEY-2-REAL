//
//  HealthKit.swift
//  Workouts
//
//  Created by: Grant Perry
//    Modified: Monday January 1, 2024 at 3:00:39 PM
//
// https://developer.apple.com/documentation/healthkit/workouts_and_activity_rings
// https://www.andyibanez.com/posts/converting-closure-based-code-into-async-await-in-swift/

import SwiftUI
import HealthKit
import CoreLocation

var workoutUtility = WorkoutUtility()

let store = HKHealthStore()

/// func readWorkouts() - gather workouts from the HealthStore
/// - Parameter limit: max number of results to query
/// - Returns: queried workouts

func readWorkouts(limit: Int = HKObjectQueryNoLimit) async throws -> [HKWorkout]? {
	let store = HKHealthStore()
	let workoutTypes: [HKWorkoutActivityType] = [.cycling, .walking, .running]
	let predicates = workoutTypes.map { HKQuery.predicateForWorkouts(with: $0) }
	let compoundPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: predicates)

	do {
//		let samples = try await withCheckedThrowingContinuation { continuation in
		let samples: [HKSample] = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKSample], Error>) in
			let query = HKSampleQuery(sampleType: .workoutType(),
											  predicate: compoundPredicate,
											  limit: limit,
											  sortDescriptors: [NSSortDescriptor(keyPath: \HKSample.startDate, ascending: false)]) { _, samples, error in
				if let error = error {
					continuation.resume(throwing: error)
				} else if let samples = samples {
					continuation.resume(returning: samples)
				} else {
					continuation.resume(returning: [])
				}
			}
			store.execute(query)
		}
		return samples as? [HKWorkout]
	} catch {
		print("Error reading workouts: \(error)")
		throw error
	}
}

/// Gets all samples in HealthKit from the workout passed
///  HKQuery.predicateForObjects(from:) method is used to create a query predicate that returns only
//// samples belonging to a specified workout.  So this next line is setting byWorkout to only the
///  routes in the workout passed to getWorkoutRoute
///
func getWorkoutRoute(workout: HKWorkout) async -> [HKWorkoutRoute]? {
   let byWorkout 	= HKQuery.predicateForObjects(from: workout)
   let samples 	= try! await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKSample], Error>) in
      store.execute(HKAnchoredObjectQuery(type: HKSeriesType.workoutRoute(),
                                          predicate: byWorkout,
                                          anchor: nil,
                                          limit: HKObjectQueryNoLimit,
                                          resultsHandler: { (query, samples, deletedObjects, anchor, error) in
         if let hasError = error {
            continuation.resume(throwing: hasError)
            return
         }
         guard let samples = samples else { return }
         continuation.resume(returning: samples)
      }))
   }
   guard let workouts = samples as? [HKWorkoutRoute] else { return nil }
   return workouts
}

/// Retrieves all the location / coordinates for the givenRoute
/// - Parameter givenRoute: the user selected a route that was part of the List on main page.
/// - Returns: all of the coordinates and location data
///
///HKWorkoutRouteQuery is a query object to retrieve the location data for a specific workout
///route in HealthKit. It takes a HKWorkoutRoute object as its parameter and
///represents the workout route for which you want to retrieve location data.
///
///The closure to the HKWorkoutRouteQuery constructor is called each time the query retrieves
///a new batch of location data. The closure takes four parameters:
///
///- parameter query: The HKWorkoutRouteQuery object that retrieved the location data - selected from the list on main.
///- parameter locationsOrNil: An optional array of CLLocation objects that represents the retrieved location data. nil = error retrieving location data
///- parameter done: boolean value indicating whether the query has finished retrieving location data. When the
///query is finished, the value of done is true, and the locationsOrNil parameter contains all the retrieved location data.
///- parameter errorOrNil: An optional error object that represents any error that occurred while retrieving the location data. T
///his parameter is nil if there were no errors.
//////

func getCLocationDataForRoute(routeToExtract: HKWorkoutRoute) async -> [CLLocation] {
	do {
		let locations: [CLLocation] = try await withCheckedThrowingContinuation { continuation in
			var allLocations: [CLLocation] = []
			let query = HKWorkoutRouteQuery(route: routeToExtract) { query, locationsOrNil, done, errorOrNil in
				if let error = errorOrNil {
					continuation.resume(throwing: error)
					return
				}
				if let locationsOrNil = locationsOrNil {
					allLocations.append(contentsOf: locationsOrNil)
					if done {
						continuation.resume(returning: allLocations)
					}
				} else {
					continuation.resume(returning: []) // Resume with an empty array if no locations are found
				}
			}
			store.execute(query)
		}
		return locations
	} catch {
		print("Error fetching location data: \(error.localizedDescription)")
		return []
	}
}








/*
 queryStepCount returns the current daily step count
 to utilize you need to pass a closure to it like...

 queryStepCount { steps in
 if let steps = steps {
 print("Number of steps: \(steps)")
 } else {
 print("Error retrieving step count.") } }

 */
func queryStepCount(completion: @escaping (Int?) -> Void) {
	let healthStore          = HKHealthStore()
	let stepsQuantityType    = HKQuantityType.quantityType(forIdentifier: .stepCount)!
	let now                  = Date()
	let startOfDay           = Calendar.current.startOfDay(for: now)
	let predicate            = HKQuery.predicateForSamples(withStart: startOfDay, 
																			 end: now,
																			 options: .strictStartDate)
	let dataTypesToRead      = Set([HKObjectType.quantityType(forIdentifier: .stepCount)!])
	let dataTypesToWrite     = Set([HKObjectType.quantityType(forIdentifier: .stepCount)!])
	healthStore.requestAuthorization(toShare: dataTypesToWrite,
												read: dataTypesToRead) { (success, error) in
		if !success {
			print("Error requesting authorization: \(error?.localizedDescription ?? "Unknown error")")
			completion(nil)
			return
		}
		let query 				= HKStatisticsQuery(quantityType: stepsQuantityType,
															  quantitySamplePredicate: predicate,
															  options: .cumulativeSum) { (_, stepResults, error) in
			guard let sum 		= stepResults?.sumQuantity() else {
				print("Error: \(error?.localizedDescription ?? "Unknown error")")
				completion(nil)
				return
			}
			let steps = sum.doubleValue(for: HKUnit.count())
			completion(Int(steps))
		}
		healthStore.execute(query)
	}
}

func formatDuration(duration: TimeInterval) -> String {
   let formatter = DateComponentsFormatter()
   formatter.unitsStyle = .positional
   formatter.allowedUnits = [.minute, .second]
   formatter.zeroFormattingBehavior = .pad

   if duration >= 3600 { // if duration is 1 hour or longer
      formatter.allowedUnits.insert(.hour)
   }

   return formatter.string(from: duration) ?? "0:00"
}

func formatDateName(_ date: Date) -> String {
   let dateFormatter = DateFormatter()
   dateFormatter.dateFormat = "MMMM d, yyyy"
   return dateFormatter.string(from: date)
}

func healthKitHasAccess () -> Bool {
   return HKHealthStore.isHealthDataAvailable()
}


func requestPermission () async -> Bool {
   typealias HKST = HKSeriesType
   let write: Set<HKSampleType> = [.workoutType()]
   let read: Set = [.workoutType(),
                    HKST.activitySummaryType(),
                    HKST.workoutRoute(),
                    HKST.workoutType()]
   // res: ()? is a constant of type "Optional:<Void>"
   let res: ()? = try? await store.requestAuthorization(toShare: write, read: read)
   guard res != nil else {
      return false
   }
   return true
}



