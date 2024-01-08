//
//  varView.swift
//  BigMetric Watch App
//
//  Created by Grant Perry on 10/17/23.
//

import SwiftUI

struct varView: View {
	@ObservedObject var distanceTracker = DistanceTracker()
//	@EnvironmentObject var distanceTracker: DistanceTracker

	var variables: [(String, Any)] = []

	init() {
		variables = [
			("longitude", distanceTracker.longitude as Any),
			("latitude", distanceTracker.latitude as Any),
			("lastLocation", distanceTracker.lastLocation as Any),
			("firstLocation", distanceTracker.firstLocation as Any),
			("formatter", distanceTracker.formatter),
			("currentCoords", distanceTracker.currentCoords),
			("timer", distanceTracker.timer as Any),
			("altitudes", distanceTracker.altitudes),
			("holdCLLocations", distanceTracker.holdCLLocations),
			("locationName", distanceTracker.locationName),
			("formattedTimeString", distanceTracker.formattedTimeString),
			("debugStr", distanceTracker.debugStr),
			("superBug", distanceTracker.superBug),
			("superAuthBug", distanceTracker.superAuthBug),
			("builderDebugStr", distanceTracker.builderDebugStr),
			("plusMinus", distanceTracker.plusMinus),
			("isBeep", distanceTracker.isBeep),
			("showStartText", distanceTracker.showStartText),
			("isInitialLocationObtained", distanceTracker.isInitialLocationObtained),
			("yardsOrMiles", distanceTracker.yardsOrMiles),
			("YMCalc", distanceTracker.YMCalc),
			("initRun", distanceTracker.initRun),
			("startRouteBuilder", distanceTracker.startRouteBuilder),
			("isAuthorizedForPreciseLocation", distanceTracker.isAuthorizedForPreciseLocation),
			("isUpdating", distanceTracker.isUpdating),
			("isHealthUpdate", distanceTracker.isHealthUpdate),
			("isNotAuthorized", distanceTracker.isNotAuthorized),
			("isWorkoutLive", distanceTracker.isWorkoutLive),
			("weIsRecording", distanceTracker.weIsRecording),
			("healthRecordExists", distanceTracker.healthRecordExists),
			("healthRecordsDelete", distanceTracker.healthRecordsDelete),
			("cleanVars", distanceTracker.cleanVars),
			("yardToFeet", distanceTracker.metersToMiles),
			("meterToFeet", distanceTracker.metersToYards),
			("altitude", distanceTracker.altitude),
			("distance", distanceTracker.distance as Any),
			("speedDist", distanceTracker.speedDist),
			("heartRate", distanceTracker.heartRate),
			("segmentDistance", distanceTracker.segmentDistance),
			("elapsedTime", distanceTracker.elapsedTime),
			("lastDist", distanceTracker.lastDist),
			("lastHapticMile", distanceTracker.lastHapticMile),
			("startStepCnt", distanceTracker.startStepCnt),
			("healthRecordsCount", distanceTracker.healthRecordsCount)
		]
	}

	var body: some View {
		ScrollView {
			VStack(alignment: .leading, spacing: 8) {
				ForEach(variables, id: \.0) { label, value in
					HStack {
						VStack {
							Text("\(label):")
								.font(.caption)
								.foregroundColor(Color.white)
//								.background(Color.blue)
							Text("\(String(describing: value))")
								.font(.footnote)
								.foregroundColor(Color.green)
							// Add a horizontal line under the Text

						}
						}
					Rectangle()
						.frame(height: 1)
						.foregroundColor(Color.gray)
				}
			}
			.padding()
		}
	}
}

struct varView_Previews: PreviewProvider {
	static var previews: some View {
		varView()
	}
}
