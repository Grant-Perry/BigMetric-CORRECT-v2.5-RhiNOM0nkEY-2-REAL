//
//  DistanceTracker.swift
//
//  Created by Grant Perry on 1/24/23.

//		THIS IS THE BEST VERSION Jan 6, 2024

//   Modified: Modified: Saturday January 6, 2024 at 6:20:12 PM
import SwiftUI
import CoreLocation
import CoreMotion // for the pedometer
import HealthKit
//import Combine

class DistanceTracker: 	NSObject,
								ObservableObject,
								CLLocationManagerDelegate {
	@EnvironmentObject var workoutManager: 				WorkoutManager
	@Published var pedometer: CMPedometer					= CMPedometer()
	@Published var timer: 										Timer?
	@Published var longitude: 									CLLocationDegrees?
	@Published var latitude: 									CLLocationDegrees?
	@Published var lastLocation: 								CLLocation?
	@Published var firstLocation: 							CLLocation?
	var LMDelegate 												= CLLocationManager()
	@Published var currentCoords              			= CLLocationCoordinate2D()
	@Published var routeBuilder 								= HKWorkoutRouteBuilder(healthStore: HKHealthStore(), device: nil)
	@Published var HKStore 										= HKHealthStore()
	@Published var formatter 									= DateComponentsFormatter()
	@Published var locationName               			= ""
	@Published var formattedTimeString						= "00:00:00"
	@Published var debugStr: String							= "debug"
	@Published var superBug	: String							= "superBug"
	@Published var superAuthBug	: String					= "Not determined"
	@Published var builderDebugStr: String					= "[nil]"
	@Published var plusMinus: String							= "+="
	@Published var altitudes: [AltitudeDataPoint]		= []
				  var holdCLLocations: [CLLocation] 		= []
				  var locationsArray: 	[CLLocation] 		= []  // array to hold each didUpdateLocation GPS location to sum .calculatedDistance
	@AppStorage("isBeep") var isBeep							= true
	@Published var isSpeed:Bool 								= true 			// MPH-BPM state
	@Published var showStartText								= true
	@Published var yardsOrMiles								= true
	@Published var YMCalc										= true
	@Published var initRun										= true
	@Published var startRouteBuilder						= true
var isAuthorizedForPreciseLocation							= true
	@Published var isInitialLocationObtained				= false
	var healthRecordExists 									= false
	var healthRecordsDelete 									= false
	@Published var isUpdating									= false
	@Published var isHealthUpdate								= false
	@Published var isNotAuthorized							= false
	@Published var isWorkoutLive								= false
	@Published var weIsRecording								= false
	@Published var ShowEstablishGPSScreen					= false
	@Published var isPrecise 									= true {
		didSet {
			setPrecision() // change the precision for GPS when user toggles isPrecise on debugScreen
		}
	}
	@Published var cleanVars: Bool 							= false {
		didSet {
			if cleanVars {
				print("I'm in didSet for CleanVars")
				self.cleanVars = false
				resetVars()
			}
		}
	}
	@Published var healthRecordsCount						= 0
	@Published var workoutStepCount: 			Int		= 0 // overall step count from the pedometer
	@Published var lastHapticMile:				Int		= 0
	@Published var startStepCnt: 					Int		= 0
	@Published var holdInitialSteps:				Int		= 0
	@Published var prevDist: 					Double		= 0
	@Published var speedDist: 					Double		= 0
	@Published var altitude: 					Double		= 0
//	@Published var heartRate: 					Double		= 0
	@Published var heartRateReadings: 		[Double] 	= [] // array to hold heart readings to display average
	@Published var heartRate: Double = 0 {
		didSet {
			// Add the new heart rate reading to the array
			heartRateReadings.append(heartRate)
		}
	}
	@Published var finalDist:					Double		= 0
	@Published var lastDist:					Double		= 0
	@Published var elapsedTime: 				Double		= 0
	@Published var segmentDistance:			Double		= 0
	@Published var distance: 					Double		= 0 {
		didSet {
			// TODO: - DEBUG - next line
			//print("the calculated distance is: \(String(describing: distance))")
		}
	}
	@Published var GPSAccuracy									= 99.0 // for GPSIcon indicator
	@State var metersToMiles						        	= 1609.344
	@State var metersToYards									= 1.0936133 // 0.91439950622 // 3.28084
	@State var metersToFeet										= 0.3048

	override init() {
		super.init()
//		print("Inside override init\n")
		getCLAuth(LMDelegate) // get location whenInUse auth
		setupLocationManager()
	}
	
	private func setupLocationManager() {
//		print("I'm inside setupLocationManager - isInitialLocationObtained: \(isInitialLocationObtained)")
		LMDelegate.delegate = self
		LMDelegate.requestLocation()
		setPrecision()
		LMDelegate.allowsBackgroundLocationUpdates	= true
		LMDelegate.activityType = .fitness
	}

	func setPrecision() {
		LMDelegate.distanceFilter 	= isPrecise ? 1 : 10
		LMDelegate.desiredAccuracy = isPrecise ? kCLLocationAccuracyBest : kCLLocationAccuracyNearestTenMeters
	}

	func resetLocationManager() {
		LMDelegate.delegate = nil
		LMDelegate = CLLocationManager()
		getCLAuth(LMDelegate)
		print("I'm inside resetLocationManager - isInitialLocationObtained: \(isInitialLocationObtained)")
		setupLocationManager()
	}

// MARK: - didUpdateLocations
	func locationManager(_ manager: CLLocationManager,
						 didUpdateLocations GPSLocation: 	[CLLocation]) {
		// check to verify there is a valid initial location

		guard let isLocation 									= GPSLocation.last else {
			isInitialLocationObtained 							= false
			ShowEstablishGPSScreen								= true // maybe make this true here but you need to figure out why that not work
			return
		}

		GPSAccuracy = isLocation.horizontalAccuracy // set GPSIcon accuracy value
		ShowEstablishGPSScreen = false // turn off "Establishing GPS" screen
		// now set isInitialLocationObtained state 		= true
		if !isInitialLocationObtained && isLocation.horizontalAccuracy <= 50.0 {
			isInitialLocationObtained 	= true // got a clean new accurate initial location - change state
			ShowEstablishGPSScreen 		= false // turn off the 'Establishing' screen
			let geocoder 											= CLGeocoder()
			geocoder.reverseGeocodeLocation(isLocation) { [self] (placemarks, error) in
				guard error == nil, let placemark 			= placemarks?.first else { return }
				locationName 										= placemark.locality ?? "Determining..."
			}
#if os(watchOS)
			if isBeep {
				PlayHaptic.tap(PlayHaptic.up)
			}
#endif
		}
		if weIsRecording {
			if let location 				= GPSLocation.last {
				self.latitude 				= Double(location.coordinate.latitude)
				self.longitude 			= Double(location.coordinate.longitude)
				self.currentCoords 		= location.coordinate
				altitude 					= location.altitude * metersToFeet // * 3.28084
  //  Append altitude to altitudes[] for point chart
				let newDataPoint 			= AltitudeDataPoint(value: altitude, dist: distance )
				// collect coords for weather data
				self.altitudes.append(newDataPoint)
			}
			//         print("Lat: \(currentCoords.latitude) - Long: \(currentCoords.longitude) - [DistanceTracker]\n")
			// filter the GPSLocation to drop any CLLocation(s) that horizontalAccuracy are > 50
			let filteredLocations 		= GPSLocation.filter { (location: CLLocation) -> Bool in
				location.horizontalAccuracy <= 50.0
			}
			guard !filteredLocations.isEmpty else { return }
			holdCLLocations 				= filteredLocations
			locationsArray.append(contentsOf: filteredLocations)

			blinkRecordBtn(true, 2)
			guard let existingLocation = holdCLLocations.last else { return }
			
			// make certain we're not updating firstLocation unless it's the FIRST time it has a value
			if firstLocation == nil {
				firstLocation = existingLocation
				authHealthKitForHeart()
				getHKAuth()
				// fetch the starting step counter
				queryStepCount { steps in
					if let steps = steps {
						print("I'm setting starStepCnt & holdInitialSteps to: \(steps) \n-----------------")
						self.startStepCnt			= steps
						self.holdInitialSteps	= steps
						print("---------\nNumber of PREVIOUS steps: \(self.startStepCnt) \n-----------------")
					} else { print("Error retrieving step count.") }
				}
			}
			if initRun {
				isInitialLocationObtained 	= false // set state to false to correctly allow initial location to produce a value
				isWorkoutLive 					= true
				initRun 							= false // are you sure this should be false? Tuesday December 12, 2023 at 2:00:38 PM
			}
	// TODO: - previous CLLocation.distance update routine commeted below
			//				calcDistance(currentLocation: existingLocation,
			//								 prevLocation: lastLocation ?? CLLocation())
			//			}
	// MARK: - THIS IS WHERE distance is updated
			// i'm usig .calcFromLastLocation vs. incrementing the
			// distance... and this makes me SO happy!!! Sunday October 29, 2023 at 11:47:49 AM
			if !YMCalc { // YARDS calculation
				isSpeed		= false  // force the time to display and NOT speed - speed doesn't make sense to show for YARDS
				distance 	= locationsArray.calcFromLastLocation / metersToYards
			} else { // MILES calc
				distance		= locationsArray.calculatedDistance / metersToMiles
			//	isSpeed		= true // show speed and time option
			}
			// 
			//			self.distance 			= GPSLocation.distance / metersToMiles // use the CLLocation array extension .distance to calculate distance
			lastDist			= distance
			lastLocation	= existingLocation
			// check to see if mile haptic needs to fire
#if os(watchOS)
			let currentMile 	= Int(distance)
			if currentMile 	> lastHapticMile {
				lastHapticMile = currentMile // update the currentMile integer value for next mile
				if self.isBeep {
					PlayHaptic.tap(PlayHaptic.notify)
				}
			}
#endif
			debugStr = "debug"
			buildDebugStr()
			DispatchQueue.main.async {
				self.superBug 	= self.debugStr + "\n\ndistance: " + String(self.distance)
				self.debugStr 	= self.debugStr
			}
		}
	}
	
	func locationManager(_ manager: CLLocationManager, 
						 didFailWithError error: Error) {
		print("-- RIGHT HERE **** LMDelegate authorizationStatus = \(LMDelegate.authorizationStatus.rawValue)\n--------\n")
		print("LocationManager LM - locationManager failed with error: \(error.localizedDescription)")
		getCLAuth(manager)
	}
	
	/// start the CLLocation updates
	func startUpdates() {
		if self.LMDelegate.authorizationStatus !=  .authorizedWhenInUse {
			getCLAuth(LMDelegate)
			isNotAuthorized 		= true // what is this?
		}
		self.weIsRecording 		= true
		if startRouteBuilder {
			getHKAuth()
			startRouteBuilder 	= false
		}

		LMDelegate.startUpdatingLocation()
		startPedometer(startStop: true) // start the pedometer
		timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
			guard let self			= self else { return }
			if self.weIsRecording {
				self.elapsedTime 	+= 1 // add a second to the count
				self.formattedTimeString = self.stringFromTimeInterval(interval: self.elapsedTime)
			}
		}
	}
	
	func locationManager(_ manager: CLLocationManager, 
						 didChangeAuthorization status: CLAuthorizationStatus) {
//		print("didChangeAuthorization status: \(status.rawValue)")
		switch status {
		case .authorizedAlways, .authorizedWhenInUse: // we're good, move on
			return
		case .notDetermined, .denied, .restricted:
			getCLAuth(manager)
		@unknown default:
			fatalError()
		}
	}
	
	func numTimerHours() -> Int {
		return Int(elapsedTime / 3600) // 3600 = convert to minutes
	}
	// Main Distance Calculations - as of 10/29/23 at 11:50:27 AM this is no longer used.
	// the CLLocation.calculatedDistance is now used

	func calcDistance(currentLocation: CLLocation, prevLocation: CLLocation) {
		if !YMCalc {  // YARDS
			if let originalLocation = firstLocation {
				let thisDistance = currentLocation.distance(from: originalLocation) * metersToYards
//				print("thisDistance = \(thisDistance) x \(metersToYards) = \(thisDistance * metersToYards)")
				distance 			= thisDistance * metersToYards // currentLocation.distance(from: originalLocation) * metersToFeet
//				distance 			= currentLocation.distance(from: originalLocation) / metersToYards // 0.9144
				plusMinus 			= "="
			}
		} 
//		else { // MILES
//			if let lastLocation 	= lastLocation {
//				prevDist				= distance ?? 0 // just to debug
//				segmentDistance 	= currentLocation.distance(from: prevLocation) / metersToMiles // 1609.344
//				self.distance! 	+= segmentDistance
//				speedDist 			= self.distance!
//				plusMinus 			= "+="
//			}
//		}
	}
	
	/// Stop the CLLocation update
	/// - Parameter resetDist: true = all the counter be reset
	/// - Returns: timeString
	///
	func stopUpdates(_ resetDist: Bool) -> String {
		// write the collected GPS data to the HealthStore
		// var tmpLoc: [CLLocation] = []
		// writeGPSData(tmpLoc, true)
		LMDelegate.stopUpdatingLocation()
		startPedometer(startStop: false) // stop the pedometer
		timer?.invalidate()
		weIsRecording 				= false
		firstLocation 				= nil
		lastLocation 				= nil
		let timeString 			= formattedTimeString
		cleanVars 					= resetDist // didSet will handle reset
		return timeString
	}
	
	public func endWorkout() {
		let activityType: HKWorkoutActivityType = .walking // .running
		let startDate = Date()
		let endDate = startDate.addingTimeInterval(3600) // 1 hour later
		//      let duration = endDate.timeIntervalSince(startDate)
		var workOut: HKWorkout {
			return HKWorkout(activityType: 		activityType,
								  start:					startDate,
								  end:					endDate,
								  workoutEvents:		nil,
								  totalEnergyBurned:	nil,
								  totalDistance: 		nil,
								  metadata: 			[:])
		}
		
		routeBuilder.finishRoute(with: 				workOut,
										 metadata: 			nil,
										 completion: { workoutRoute, error in
			if workoutRoute == nil {
				print("error saving workout route inside endWorkout with: - \(error!)")
			} else {
				print("SUCCESS -> workoutRoute inside endWorkout - Workout = \(workOut)")
			}
		})
		LMDelegate.stopUpdatingLocation()
		startPedometer(startStop: false) // stop the pedometer
		cleanVars = true // didSet will handle reset
	}

	func startPedometer(startStop: Bool) {
		if CMPedometer.isStepCountingAvailable() {
			if startStop {
				//				DispatchQueue.main.async { [self] in
				// let's start the pedometer
				let calendar = Calendar.current
				let midnight = calendar.startOfDay(for: Date())
				pedometer.startUpdates(from: midnight) { [self] pedometerData, error in
					if let stepData = pedometerData {
						// Update step count
						// subtract the initial steps
						// This holds the cumulative steps because the pedometer lifecycle
						// may be shorter than the overall workout
						DispatchQueue.main.async { [self] in
							workoutStepCount += holdInitialSteps > 0 ? Int(truncating: stepData.numberOfSteps) - holdInitialSteps : 0
						}
					}
				}
				//				}
			} else {
				// let's stop the pedometer
				DispatchQueue.main.async { [self] in
					pedometer.stopUpdates()
				}
			}
		}
	}

	func requestCurrentLocation() {
		getCLAuth(LMDelegate)
		LMDelegate.requestLocation()
	}
}

extension DistanceTracker { // misc helper methods
	func buildDebugStr() {
		if let fl 		= firstLocation, let ll = lastLocation {
			debugStr 	= plusMinus + " | Last: (\(ll.coordinate.latitude), \(ll.coordinate.longitude))\nFirst: (\(fl.coordinate.latitude), \(fl.coordinate.longitude))"
		} else {
			debugStr 	= "FL: nil | LL: nil"
		}
	}
	
	func stringFromTimeInterval(interval: TimeInterval) -> String {
		let interval 	= Int(interval)
		let seconds 	= interval % 60
		let minutes 	= (interval / 60) % 60
		let hours 		= (interval / 3600)
		return hours > 0 ? String(format: "%02d:%02d:%02d", hours, minutes, seconds) : String(format: "%02d:%02d", minutes, seconds)
	}
	
	func blinkRecordBtn(_ toggleState: Bool, _ blinkTime: Int) {
		DispatchQueue.main.async {
			if toggleState { self.isUpdating = true } else { self.isHealthUpdate = true }
			DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(blinkTime)) {
				if toggleState { self.isUpdating = false } else { self.isHealthUpdate = false }
				// used for the green / red status button on screen
			}
		}
	}
	
	func resetVars() {
//		DispatchQueue.main.async { [self] in
			LMDelegate.stopUpdatingLocation()
			resetLocationManager()
			holdCLLocations.removeAll()
			altitudes.removeAll()
			currentCoords 					= CLLocationCoordinate2D()
			holdCLLocations 				= []
			locationsArray 				= []
			longitude						= nil
			latitude							= nil
			firstLocation 					= nil
			lastLocation 					= nil
			initRun 							= true
			isInitialLocationObtained 	= true
			isUpdating 						= false
			isHealthUpdate 				= false
			weIsRecording 					= false
			isWorkoutLive 					= false
			ShowEstablishGPSScreen		= false
			debugStr							= ""
			superBug							= ""
			finalDist						= distance // hold for summary screen. Set this prior to resetting Distance
			distance 						= 0
			prevDist							= 0
			segmentDistance 				= 0
			elapsedTime 					= 0
			heartRate 						= 0
			speedDist						= 0
			lastHapticMile 				= 0
			GPSAccuracy						= 97
	//		lastDist							= 0
	//		startStepCnt 					= 0
	//		assertProperties()
	//		heartRateReadings				= []
	//		precisionrevealPropVals("resetVars")
		}
//	}

	func assertProperties() {
		print("-----------[ asserting properties ]---------------\n")
		assert(self.holdCLLocations.isEmpty 	== true, 	"holdCLLocations was not reset correctly")
		assert(self.altitudes.isEmpty 			== true, 	"altitudes was not reset correctly")
		assert(self.firstLocation 					== nil, 		"firstLocation was not reset correctly")
		assert(self.lastLocation 					== nil, 		"lastLocation was not reset correctly")
		assert(self.initRun 							== true, 	"initRun was not reset correctly")
		assert(self.isInitialLocationObtained 	== true, 	"isInitialLocationObtained was not reset correctly")
		assert(self.isUpdating 						== false, 	"isUpdating was not reset correctly")
		assert(self.isHealthUpdate 				== false, 	"isHealthUpdate was not reset correctly")
		assert(self.weIsRecording 					== false, 	"weIsRecording was not reset correctly")
		assert(self.isWorkoutLive 					== false, 	"isWorkoutLive was not reset correctly")
		assert(self.holdCLLocations.isEmpty 	== true, 	"holdCLLocations was not reset correctly")
		assert(self.distance 						== 0.0, 		"distance was not reset correctly")
		assert(self.segmentDistance 				== 0.0, 		"holdDist was not reset correctly")
		assert(self.elapsedTime 					== 0.0, 		"elapsedTime was not reset correctly")
//		assert(self.heartRate 						== 0, 		"heartRate was not reset correctly")
		assert(self.lastHapticMile 				== 0, 		"lastHapticMile was not reset correctly")
		assert(self.startStepCnt 					== 0, 		"startStepCnt was not reset correctly")
		print("-----------[ END - asserting variables ]---------------\n\n")

	}

	func revealPropVals(_ label: String) {
		//		print("workoutManager: \(workoutManager)")
		print("\n---------------------------------------------------------------------------------------")
		print("              [      From -----> \(label)      ]")
		print("---------------------------------------------------------------------------------------\n")
		print("longitude: \(String(describing: longitude))")
		print("latitude: \(String(describing: latitude))")
		print("lastLocation: \(String(describing: lastLocation))")
		print("firstLocation: \(String(describing: firstLocation))")
		print("currentCoords: \(currentCoords)")
		print("altitudes: \(altitudes)")
		print("holdCLLocations: \(holdCLLocations)")
		print("locationName: \(locationName)")
		print("formattedTimeString: \(formattedTimeString)")
		print("formatter: \(formatter)")
		print("timer: \(String(describing: timer))")
		print("debugStr: \(debugStr)")
		print("superBug: \(superBug)")
		print("superAuthBug: \(superAuthBug)")
		print("builderDebugStr: \(builderDebugStr)")
		print("plusMinus: \(plusMinus)")
		print("isBeep: \(isBeep)")
		print("showStartText: \(showStartText)")
		print("isInitialLocationObtained: \(isInitialLocationObtained)")
		print("yardsOrMiles: \(yardsOrMiles)")
		print("YMCalc: \(YMCalc)")
		print("initRun: \(initRun)")
		print("startRouteBuilder: \(startRouteBuilder)")
		print("isAuthorizedForPreciseLocation: \(isAuthorizedForPreciseLocation)")
		print("isUpdating: \(isUpdating)")
		print("isHealthUpdate: \(isHealthUpdate)")
		print("isNotAuthorized: \(isNotAuthorized)")
		print("isWorkoutLive: \(isWorkoutLive)")
		print("weIsRecording: \(weIsRecording)")
		print("cleanVars: \(cleanVars)")
		print("altitude: \(altitude)")
		print("distance: \(String(describing: distance))")
		print("prevDist: \(prevDist)")
		print("speedDist: \(speedDist)")
		print("heartRate: \(heartRate)")
		print("holdDist: \(segmentDistance)")
		print("elapsedTime: \(elapsedTime)")
		print("lastDist: \(lastDist)")
		print("lastHapticMile: \(lastHapticMile)")
		print("startStepCnt: \(startStepCnt)")
		print("healthRecordsCount: \(healthRecordsCount)")
	}

	func calculateAverageHeartRate(bleach: Bool) -> Double {
		var avgHeartRate:Double = 0
		let totalHeartRate = heartRateReadings.reduce(0, +)
		avgHeartRate = totalHeartRate / Double(heartRateReadings.count)
		if bleach {	heartRateReadings = []	}
		return avgHeartRate // totalHeartRate / Double(heartRateReadings.count)
	}
}

extension DistanceTracker { // toggle stuff
	
	func toggleYMBool(_ ymState: Bool)  {
YMCalc 	= ymState
_ 			= stopUpdates(true)
	}
	
	func toggleYMBoolFalse() {
		YMCalc 						= false
	}
	
	func toggleWeIsRecording(_ RecState: Bool)  {
		weIsRecording 				= RecState
	}
}



