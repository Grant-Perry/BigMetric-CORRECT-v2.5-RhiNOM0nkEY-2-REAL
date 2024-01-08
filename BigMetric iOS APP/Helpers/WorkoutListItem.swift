//
//  WorkoutListItem.swift
//  BigMetric
//
//  Created by Grant Perry on 5/31/23.
//

import SwiftUI
import HealthKit
import CoreLocation
import MapKit

struct WorkoutListItem: View {
   let workout: HKWorkout
   let mapView: MKMapView										= MKMapView()
   @State var healthStore 										= HKHealthStore()
   @State var locations: [CLLocation]? 					= nil
   @State private var numRouteCoords: Int 				= 0
   @State var regionLatLongHeight:CLLocationDistance	= 2000 // feet
	@State private var workoutDistance: Double? 			= nil
	@State private var CityState: String?
	@State private var lastCoordinates: CLLocationCoordinate2D?
	@State var longitude: CLLocationDegrees?
	@State var latitude: CLLocationDegrees?
   // this is the map view displayed when user selects a workout from the List
   func focusLocations() {

		if let coordinates 	= processLocations(self.locations) {
			let delegate 		= MapViewDelegate()
			mapView.delegate 	= delegate
			let polyLine 		= MKPolyline(coordinates: coordinates, 
													 count: coordinates.count)
			let region 			= MKCoordinateRegion(center: coordinates[0],
													  latitudinalMeters: regionLatLongHeight,
													  longitudinalMeters: regionLatLongHeight)

			mapView.addOverlay(polyLine)
			mapView.setCenter(coordinates[0], animated: true)
			mapView.setRegion(region, animated: true)
		} else {
			return
			// Handle the case where there are no valid coordinates
		}
	}

	func processLocations(_ locations: [CLLocation]?) -> [CLLocationCoordinate2D]? {
		guard let validLocations = locations?.filter({ $0.coordinate.latitude != 0 || $0.coordinate.longitude != 0 }), validLocations.count > 0 else {
			return nil
		}
		let coordinates = validLocations.map({ $0.coordinate })
		return coordinates
	}

	func getWorkoutDistance(_ thisWorkout: HKWorkout) async throws -> Double {
		guard let route = await getWorkoutRoute(workout: thisWorkout)?.first else {
			return 0
		}
		let coords = await getCLocationDataForRoute(routeToExtract: route)
		longitude = coords.last?.coordinate.longitude
		latitude = coords.last?.coordinate.latitude
		return coords.calcDistance
//		return await getCLocationDataForRoute(routeToExtract: route).calcDistance
	}

	var body: some View {
		NavigationLink {
			VStack {
				// on initial load, locations = nil so this part of the block does not run
				if let locations = self.locations {
					VStack {
						Text("\(self.formatDateName())")
							.theHead()
					}
					VStack {
						Text("Distance: \(String(format: "%.2f", locations.calcDistance))") +
						Text(" | Duration: \(formatDuration(duration: workout.duration))") +
						Text(" | Calories: \(Int(workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0))")
					}
					.headSmall()
					Text("Found \(locations.count) waypoints")
						.font(.caption)
					MapView(mapView:mapView)
						.ignoresSafeArea()
				}
			}
			Spacer()
				.task {
					guard let routes = await getWorkoutRoute(workout: workout) else {
						return
					}
					guard routes.count > 0 else {
						// clear locations from last query and get it ready for next
						self.locations = []
						return
					}

					if routes.count > 1 {
						print("found \(routes.count) route samples for workout")
					}
					// next line builds a [CLLocation] from the given workout route into locations
					self.locations = await getCLocationDataForRoute(routeToExtract: routes[0])

					DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
						self.focusLocations()
					}
				}
		}

		// MARK: - the list view
	label: {  // label for the NavigationLink
		HStack(spacing: 10) {
			let workoutActivityType 		= workout.workoutActivityType
			let workoutIconEnum 				= WorkoutIcon(hkType: workoutActivityType)

			Image(systemName: workoutIconEnum.icon).foregroundColor(workoutIconEnum.colors)

			Text("\(self.formatDate())")
				.theRows()
			//
			//			Text("Address")
			//				.theRows()

			// distance calculated
			//			Text("\(CityState)")
			Text("\(String(format: "%.2f", workoutDistance ?? 0.0))")
				.font(.caption)
				.onAppear {
					Task {
						do {
							let distance		= try await getWorkoutDistance(workout)
							workoutDistance	= distance
						} catch {
							// Handle any errors here
							print("Error: \(error)")
						}
					}
				}
		}
		.font(.caption)
		.onAppear {
			// Move the data fetching logic here, so it's triggered when the row appears
			Task {
				let hasCoords = await calcNumCoords(workout)
				self.numRouteCoords = hasCoords
			}
		}
	}

	}
}

extension WorkoutListItem {

   func formatDate() -> String {
      let dateToStringFormatter = DateFormatter()
      dateToStringFormatter.timeStyle 	= .short
      dateToStringFormatter.dateStyle 	= .short

      return dateToStringFormatter.string(from: workout.startDate)
   }

   func formatDateName() -> String {
      let dateToStringFormatter 			= DateFormatter()
      dateToStringFormatter.dateFormat = "MMMM d, yyyy"

      return dateToStringFormatter.string(from: workout.startDate)
   }
}



