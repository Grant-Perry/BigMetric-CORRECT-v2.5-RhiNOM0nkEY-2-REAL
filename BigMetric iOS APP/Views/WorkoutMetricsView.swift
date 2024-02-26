//   WorkoutMetricsView.swift
//   BigMetric
//
//   Created by: Grant Perry on 2/7/24 at 11:07 AM
//     Modified: 
//
//  Copyright © 2024 Delicious Studios, LLC. - Grant Perry
//

import SwiftUI
import HealthKit

struct WorkoutMetricsView: View {
	var workout: HKWorkout
	var workoutUtility = WorkoutUtility()
	@State private var workoutDistance: Double? = nil

	var body: some View {

		HStack(spacing: 10) {
			let workoutActivityType = workout.workoutActivityType
			let workoutIconEnum = WorkoutIcon(hkType: workoutActivityType)
			Image(systemName: workoutIconEnum.icon).foregroundColor(workoutIconEnum.colors)
			Text("\(workoutUtility.formatDate(workout: workout))")
				.theRows()
			Text("\(String(format: "%.2f", workoutDistance ?? 0.0))")
				.font(.caption)
				.onAppear { [self] in
					Task {
						do {
							let distance = try await workoutUtility.getWorkoutDistance(workout)
							workoutDistance = distance
						} catch {
							print("Error: \(error)")
						}
					}
				}
		}
		.font(.caption)
		.onAppear { [self] in
			// Move the data fetching logic here, so it's triggered when the row appears
			Task {
				let hasCoords = await workoutUtility.calcNumCoords(workout)
				let numRouteCoords = hasCoords
			}
		}
	}
}
