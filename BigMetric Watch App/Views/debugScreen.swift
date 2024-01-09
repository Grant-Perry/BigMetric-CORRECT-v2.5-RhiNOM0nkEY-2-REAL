//
//  debugScreen.swift
//  howFar
//
//  Created by: Grant Perry on 1/28/23.
//    Modified: Wednesday November 29, 2023 at 10:32:58 AM
//

import SwiftUI
//import Combine

struct debugScreen: View {

   @EnvironmentObject var distanceTracker: 		DistanceTracker
   @EnvironmentObject var workoutManager:			WorkoutManager
   @EnvironmentObject var weatherKitManager: 	WeatherKitManager
   @EnvironmentObject var geoCodeHelper: 			GeoCodeHelper
   @State var finalSteps: Int = 0
   @State private 		var showWeatherStatsView 		= false

   var body: some View {
#if os(watchOS)
      VStack {
         HStack {
            HStack {
               ScrollView {
                  Spacer()
                  toggleBeep()
                  Button(action: {
//                      print("in DebugScreen - Current Coords: \(distanceTracker.currentCoords)")
                     weatherKitManager.getWeather(for: distanceTracker.currentCoords)
                     showWeatherStatsView = true
                  }) {
                     showAllWeather()
//                     ShowWeather()
                  }
                  .leftJustify()
                  Divider()

                     .sheet(isPresented: $showWeatherStatsView) {
                        WeatherStatsView(weatherKitManager: weatherKitManager, showWeatherStatsView: $showWeatherStatsView)
                     }

                  DebugSummary(
                     icon: "gauge.open.with.lines.needle.33percent",
                     title: "Distance:",
							val: gpNumFormat.formatNumber(distanceTracker.distance , 3))
                  .accentColor(.gpPink)

						DebugSummary(
                     icon: "gauge.high",
                     title: "Speed:",
							val: gpNumFormat.formatNumber(distanceTracker.distance / distanceTracker.elapsedTime * 3600, 2))
                  .accentColor(.gpGreen)

                  DebugSummary(
                     icon: "timer",
                     title: "Time:",
                     val: distanceTracker.formattedTimeString)
                  .accentColor(.gpBlue)

                  DebugSummary(
                     icon: "shoeprints.fill",
                     title: "Steps:",
							val: gpNumFormat.formatNumber(Double(distanceTracker.workoutStepCount), 0)) // gpNumFormat.formatNumber(Double(finalSteps), 0))
                  .accentColor(.gpPurple)

                  DebugSummary(
                     icon: "mountain.2",
                     title: "Altitude:",
                     val: gpNumFormat.formatNumber(distanceTracker.altitude, 0))
                  .accentColor(.gpGreen)

                  DebugSummary(
                     icon: "heart.fill",
                     title: "Heart Rate:",
                     val: gpNumFormat.formatNumber(distanceTracker.heartRate, 0))
                  .accentColor(.gpBlue)
               }
               .edgesIgnoringSafeArea(.bottom)

               .alert(isPresented: $weatherKitManager.isErrorAlert) {
                  Alert(
                     title: Text("No Internet"),
                     message: Text("Please check your Internet connection and try again."),
                     dismissButton: .default(Text("OK"))
                  )
               }
            }
            .overlay(
               GeometryReader { geometry in
                  VStack {
                     HStack {
                        Spacer()
                        smallDistanceView()
//                           .environmentObject(distanceTracker)
//                           .environmentObject(workoutManager)
                           .scaleEffect(0.6)
                     }
                     Spacer()
                  }
                  .frame(width: geometry.size.width, height: geometry.size.height)
               }
                  .padding(.top, -66)
                  .padding(.leading, 95)
            )
         }
      }
		.environmentObject(distanceTracker)
		.environmentObject(workoutManager)
		.environmentObject(weatherKitManager)
		.environmentObject(geoCodeHelper)
      /*
       the .onAppear updates the steps counter for this view because it's an async func call. There's a
       completion handler in queryStepCount so it has to finish updating before self.finalSteps is updated.
       */
      .onAppear {
         weatherKitManager.getWeather(for: distanceTracker.currentCoords)
         distanceTracker.queryStepCount { steps in
            if let steps = steps {
               finalSteps = steps - distanceTracker.startStepCnt // how many steps THIS workout
            } else {
               print("Error retrieving step count for debugScreen view.")
            }
         }
      }
      //      .id(UUID()) // force refresh
      .padding()
#endif
   }
}

struct DebugSummary: View {
   var icon: String
   var title: String
   var val: String
   var body: some View {
      HStack {
         VStack {
            HStack {
               HStack {
                  Image(systemName: icon)
               }
               .rightJustify()
               HStack(spacing: 4) {
                  Text(title)
                     .font(
                        .system(.footnote, design: .rounded))
                     .multilineTextAlignment(.trailing)
                     .frame(width: 80, alignment: .trailing)
                     .foregroundColor(.accentColor)
                     .padding(.trailing)
               }
            }
            .leftJustify()
         }
         VStack {
            Text(val)
               .font(
                  .system(.title3, design: .rounded))
               .frame(alignment: .leading)
               .foregroundColor(.accentColor)
               .padding(.bottom, 2)
         }
         .leftJustify()
      }
      
      Divider()
   }
}

struct toggleBeep: View {
   @EnvironmentObject var distanceTracker: DistanceTracker
   @EnvironmentObject var workoutManager: WorkoutManager
   var body: some View {
      VStack {
         HStack {
            Text("Summary:")
               .frame(height: 30, alignment: .leading)
               .font(.headline)
               .foregroundColor(.gpPink)
               .alignmentGuide(.top) { $0[.bottom] }
               .baselineOffset(10)
               .leftJustify()
               .padding(.top, -20)
            Spacer()
            Divider()
         }
         .frame(height: 55)
// MARK: - haptic & precise toggle buttons
			VStack {
				ToggleRow(isOn: 		$distanceTracker.isBeep,
							 iconName: 	"bell.fill",
							 label: 		"Haptic:",
							 trueLabel: "ON:",
							 falseLabel:"OFF:",
							 trueColor: .gpGreen,
							 falseColor:.gpRed)

				ToggleRow(isOn: 		$distanceTracker.isPrecise,
							 iconName: 	"scope",
							 label: 		"Precise:",
							 trueLabel: "ON:",
							 falseLabel:"OFF:",
							 trueColor: .gpGreen,
							 falseColor:.gpRed)
			}

         HStack {
            Spacer()
         }
         HStack {
            Spacer()
         }
      }
//      .environmentObject(distanceTracker)
//      .environmentObject(workoutManager)
      Divider()
   }
}

// the toggle button views for the debugScreen
struct ToggleRow: View {
	@Binding var isOn: 		Bool
	let 		iconName: 		String
	let 		label: 			String
	let 		trueLabel: 		String
	let 		falseLabel: 	String
	let 		trueColor: 		Color
	let 		falseColor: 	Color

	var body: some View {
		HStack {
			Image(systemName: iconName)
			Toggle(isOn: $isOn) {
				HStack {
					Text(label)
						.rightJustify()
						.font(.footnote)
						.foregroundColor(isOn ? trueColor : falseColor)
					Text(isOn ? trueLabel : falseLabel)
						.foregroundColor(isOn ? trueColor : falseColor)
				}
				.font(.footnote)
			}
			.font(.footnote)
			.padding(.trailing)
			Spacer()
		}
	}
}

extension debugScreen {
   func getSpeed() -> Double {
      let timeComponents = distanceTracker.formattedTimeString.components(separatedBy: ":")
      let hoursIndex = timeComponents.count > 2 ? 0 : -1
      let minutesIndex = hoursIndex + 1
      let secondsIndex = hoursIndex + 2
      let decimalHours = Double(hoursIndex) + Double(minutesIndex)/60.0 + Double(secondsIndex)/3600.0
      let speed = distanceTracker.speedDist / decimalHours
      return speed
   }
}

struct debugScreen_Previews: PreviewProvider {
	static var previews: some View {
		debugScreen()
//			.environmentObject(DistanceTracker())
//			.environmentObject(WorkoutManager())
//			.environmentObject(WeatherKitManager())
//			.environmentObject(GeoCodeHelper())
			.previewDisplayName("Debug Screen Preview")
	}
}
