//   ShowTimeOrSpeed.swift
//   BigMetric Watch App
//
//   Created by: Grant Perry on 1/1/24 at 1:23 PM
//     Modified: 
//
//  Copyright © 2024 Delicious Studios, LLC. - Grant Perry
//

import SwiftUI

struct ShowTimeOrSpeed: View {

	@Bindable var distanceTracker: DistanceTracker
	var workoutManager: WorkoutManager

	var body: some View {
		VStack {
			HStack {
				Text(!distanceTracker.isSpeed ? "" : workoutManager.heading)
					.font(.callout)
					.fontWeight(.bold)
					.foregroundColor(.white)

				Button(action: {
					distanceTracker.isSpeed.toggle()
				}) {
					Text(distanceTracker.isSpeed ?
						  (distanceTracker.distance / distanceTracker.elapsedTime * 3600).isNaN ||
						  (distanceTracker.distance / distanceTracker.elapsedTime * 3600).isInfinite ?
						  "0" : "\(gpNumFormat.formatNumber(distanceTracker.distance / distanceTracker.elapsedTime * 3600, 1))" :
							distanceTracker.formattedTimeString)
					.foregroundColor(distanceTracker.isSpeed ? .white : .gpYellow)
					.font(distanceTracker.isSpeed ? .title2 : (distanceTracker.numTimerHours() > 0 ? .title3 : .title2))
				}
				// remove the gray background from the button
				.buttonStyle(PlainButtonStyle())
				.background(Color.clear)
				.frame(width: 95, height: 45)

				Text(distanceTracker.isSpeed ? "MPH" : "Time")
					.font(.system(size: 13))
					.padding(.top, -16)
					.padding(.leading, -10)
					.foregroundColor(.white)
					.bold()
			}

			.frame(height: 45)
			.horizontallyCentered()

			Spacer()
		}
		.padding(.top, -15)
	}

}
