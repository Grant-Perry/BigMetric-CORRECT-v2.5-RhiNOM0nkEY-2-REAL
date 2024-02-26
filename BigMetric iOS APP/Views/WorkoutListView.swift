////   WorkoutListView.swift
////   BigMetric
////
////   Created by: Grant Perry on 2/6/24 at 3:36 PM
////     Modified: 
////
////  Copyright © 2024 Delicious Studios, LLC. - Grant Perry
////
//
//import SwiftUI
//import HealthKit
//import MapKit
//
///// This is the NEW label: content - initial workout list view
/////
//struct WorkoutListView: View {
//
//	@State var workouts: [HKWorkout] = []
//	@State private var isLoading: Bool = true
//	var workoutUtility = WorkoutUtility()
//
//	var body: some View {
//
//
////		NavigationView {
//////			List(workouts, id: \.self) { workout in
//////				// Use a Task to asynchronously fetch the coordinates for each workout
//////				Task {
//////					do {
//////						let coords = try await workoutUtility.getWorkoutCoords(workout)
//////						// Once you have the coordinates, update the view with WorkoutRowView
//////						WorkoutRowView(workout: workout, longitude: coords.longitude, latitude: coords.latitude)
//////					} catch {
//////						// Handle errors if necessary
//////						print("Error fetching coordinates: \(error)")
//////					}
//////				}
//////			}
//////			.navigationBarTitle("Recent Workouts", displayMode: .large)
//////			.foregroundColor(.white)
////
////			// Display a loading view if workouts are still loading
////
////			}
////		}
////		.edgesIgnoringSafeArea(.all)
////
////	}
//
//
//struct InteractiveMapView: UIViewRepresentable {
//	let region: MKCoordinateRegion
//
//	func makeUIView(context: Context) -> MKMapView {
//		let mapView = MKMapView()
//		mapView.setRegion(region, animated: true)
//		mapView.mapType = .standard
//		mapView.isPitchEnabled = true
//		mapView.isRotateEnabled = true
//		mapView.isZoomEnabled = true
//		mapView.isScrollEnabled = true
//		mapView.isZoomEnabled = true
//		return mapView
//	}
//
//	func updateUIView(_ uiView: MKMapView, context: Context) {
//		// Update the map region when SwiftUI state changes
//		uiView.setRegion(region, animated: true)
//	}
//}
//
//struct FullMapView: View {
//	var city: CityCoords
//	var body: some View {
//		InteractiveMapView(region: MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: city.latitude,
//																											  longitude: city.longitude),
//																	 latitudinalMeters: 2500, longitudinalMeters: 2500))
//		.edgesIgnoringSafeArea(.all)
//		.navigationTitle(city.cityName)
//	}
//}
//
//#Preview {
//    WorkoutListView()
//}
