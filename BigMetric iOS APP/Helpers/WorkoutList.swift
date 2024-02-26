//
//  WorkoutList.swift
//  Workouts
//
//  Created by Grant Perry 2/21/23
//

import SwiftUI
import HealthKit
////
///   This is the ORIGINAL view
///   shows all the workouts in a List view
///   this gets fired by default from PolyMapView
///
///   The first thing that happens is the .task async fires readWorkouts and populates workouts with its results
///
struct WorkoutList: View {
   @State var workouts: [HKWorkout] = []
   @State private var isLoading: Bool = true
	var workoutUtility = WorkoutUtility()

   var body: some View {
      ZStack {
         NavigationView {
            VStack {
               List(workouts, id: \.self) { workout in
                  WorkoutListItem(workout: workout)
               }
               .navigationBarTitle("Recent Workouts",
                                   displayMode: .large)
               .foregroundColor(.white)
            }
				.task {
					guard let workouts = try? await readWorkouts(limit: 150) else { return }
					let workoutCoords = await workoutUtility.filterWorkoutsWithCoords(workouts)
					self.workouts = workoutCoords
					self.isLoading = false
				}

         }

         if isLoading {
            LoadingView()
               .frame(maxWidth: .infinity, maxHeight: .infinity)
               .background(Color.black.opacity(0.5).edgesIgnoringSafeArea(.all))
         }
      }
   }
}






