//
//  WeatherStatsView.swift
//  howFar Watch App
//
//  Created by Grant Perry on 4/23/23.
//

import Foundation
import WeatherKit
import CoreLocation
import SwiftUI

struct WeatherStatsView: View {
	@ObservedObject var weatherKitManager: WeatherKitManager
	@EnvironmentObject var geoCodeHelper: GeoCodeHelper
	@EnvironmentObject var distanceTracker: DistanceTracker
	@Binding var showWeatherStatsView: Bool
	@State private var address = ""
	var hotColdFirst = true
	var nextHrTemp: Double { Double(weatherKitManager.tempHour) ?? 0 }
	var thisHrtemp: Double { Double(weatherKitManager.tempVar) ?? 0 }
	var nextHrTempColor: Color { PrecipChanceColor.from(chance: Int(nextHrTemp)) }
	var thisHrTempColor: Color { PrecipChanceColor.from(chance: Int(thisHrtemp)) }
	var precipChance: Double { min(weatherKitManager.precipForecast * 100, 100) }
	var precipColor: Color { PrecipChanceColor.from(chance: Int(precipChance)) }

	var body: some View {
		ScrollView {
			VStack {
				HStack {
					Button(action: {
						showWeatherStatsView = false
					}) {
						Text("") // Close
					}
					.font(.system(size: 9)) // Make the text smaller
					.background(Color.clear) // Set the background to clear
					.buttonStyle(PlainButtonStyle())
					.cornerRadius(5)
					.padding(.trailing)
				}

				Group {
					// current temp & conditions
					Text("\(weatherKitManager.tempVar)°")
						.font(.system(size: 50, weight: .bold))
						.foregroundColor(thisHrTempColor)

					Image(systemName: weatherKitManager.symbolVar)
						.font(.system(size: 45))
						.foregroundColor(.white)
				}
				.bold()
				Spacer()
				Group {
					HStack {
						Text("\(weatherKitManager.highTempVar)°")
							.foregroundColor(TemperatureColor.from(temperature: Double(hotColdFirst ? weatherKitManager.highTempVar : weatherKitManager.lowTempVar)!))
							.foregroundColor(.gpBlue)
						Text(" / ")
							.foregroundColor(.white)
						Text("\(weatherKitManager.lowTempVar)°")
							.foregroundColor(TemperatureColor.from(temperature: Double(hotColdFirst ? weatherKitManager.lowTempVar : weatherKitManager.highTempVar)!))
					}
					.font(.system(size: 13))

					Image(systemName: weatherKitManager.symbolHourly)
					HStack {
						Text("Next Hr Rain:")
							.foregroundColor(.white)

						Text("\(gpNumFormat.formatNumber(precipChance, 0))%")
							.foregroundColor(precipColor)
					}
					HStack {
						Text("Next Hr Temp:")
							.foregroundColor(.white)

						Text(gpNumFormat.formatNumber(nextHrTemp, 0))
							.foregroundColor(nextHrTempColor)
					}
					//               }
				}
				.font(.system(size: 12))
			}

			Text(address)
				.onAppear {
					geoCodeHelper.getCityNameHelper(distanceTracker.currentCoords.latitude,
															  distanceTracker.currentCoords.longitude) { result in
						address = result
					}
				}
				.font(.footnote)
				.foregroundColor(.gpPurple)
				.bold()

			Divider()
				.padding(.vertical)
			/*
			 -------- create the list of daily weather view
			 */
			VStack(alignment: .leading, spacing: 10) {
				ForEach(Array(weatherKitManager.weekForecast.enumerated()), id: \.element.id) { index, forecast in
					dailyView(index, forecast)
					Divider()
				}
			}
		}
	}

	//   func dailyView(_ index: Int, _ forecast: WeatherKitManager.Forecasts) -> HStack<TupleView<(Group<TupleView<(Text, Spacer, some View)>>, Spacer, some View)>> {
	//      return HStack {
	func dailyView(_ index: Int, _ forecast: WeatherKitManager.Forecasts) -> some View {
		HStack {
			Group {
				Text("\(gpDateStuff.getDayName(daysFromToday: index + 1)):")
					.font(.system(size: 20))
					.bold()
					.foregroundColor(.white)
				Spacer()
				Image(systemName: forecast.symbolName)
					.foregroundColor(.white)
					.bold()
			}
			Spacer()

			let mainTemp = hotColdFirst ? forecast.maxTemp : forecast.minTemp
			let secondTemp = hotColdFirst ? forecast.minTemp : forecast.maxTemp
			let mainTemperatureColor = TemperatureColor.from(temperature: Double(mainTemp)!)
			let secondaryTemperatureColor = TemperatureColor.from(temperature: Double(secondTemp)!)

			HStack {
				Text("\(mainTemp)°")
					.foregroundColor(mainTemperatureColor)
					.font(.system(size: 17))

				Text("/")
					.foregroundColor(.white)

				Text("\(secondTemp)°")
					.foregroundColor(secondaryTemperatureColor)
					.font(.system(size: 17))
			}

			.font(.system(size: 20))
			.bold()
		}
	}
	//      .padding()
}

struct WeatherStatsView_Previews: PreviewProvider {
	static var previews: some View {
		WeatherStatsView(weatherKitManager: WeatherKitManager(), showWeatherStatsView: .constant(true))
			.environmentObject(WeatherKitManager())
			.environmentObject(DistanceTracker())
			.environmentObject(GeoCodeHelper())
			.previewDisplayName("Debug Screen Preview")
	}
}
