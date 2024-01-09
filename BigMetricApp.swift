//
//  BigMetricApp.swift
//  BigMetric Watch App
//
//  Created by: Grant Perry on 5/25/23.
//    Modified: Modified: Sunday January 7, 2024 at 4:19:05 PM

//			Trust ONLY this project 1/7/24 - 5:00 PM

//			DEVELOP MODE branch

//

import SwiftUI

let APP_NAME 		= "BigMetric"
let APP_VERSION 	= "2.9 RhiNO-M0nkEY"
let MOD_DATE 		= "Mod: 1/7/24 - 4:21 PM"

@main
struct BigMetric_Watch_AppApp: App {
   @Environment(\.scenePhase) var scenePhase
   @StateObject var distanceTracker     = DistanceTracker()
   @StateObject var workoutManager      = WorkoutManager()
   @StateObject var weatherKitManager   = WeatherKitManager()
   @StateObject var geoCodeHelper       = GeoCodeHelper()
   @State private var distanceTrackerInitialized = false
   @State private var selectedTab = 2

   var body: some Scene {
      WindowGroup {
         TabView(selection: $selectedTab) {

            endWorkout(selectedTab: $selectedTab) // when end workout is finished
               .tabItem { Image(systemName: "circle.fill") }
               .tag(0)

            howFarGPS()
               .tabItem { Image(systemName: "circle.fill") }
               .tag(2)

            debugScreen()
               .tabItem { Image(systemName: "circle.fill") }
               .tag(3)


				summary(selectedTab: $selectedTab)
					.tag(4)

				AltitudeView()
					.tabItem { Image(systemName: "circle.fill") }
					.tag(5)

            CompassView(heading: .constant(0), routeHeading: .constant(0))
               .tabItem { Image(systemName: "circle.fill") }
               .tag(6)

//				showHeartBeat()
//					.tabItem { Image(systemName: "circle.fill") }
//					.tag(6)

//				varView()
//					.tabItem { Image(systemName: "circle.fill") }
//					.tag(7)

         }
         .environmentObject(distanceTracker)
         .environmentObject(workoutManager)
         .environmentObject(weatherKitManager)
         .environmentObject(geoCodeHelper)
         .onAppear {
            self.selectedTab = 2
            workoutManager.requestHKAuth()
         }
         .tabViewStyle(PageTabViewStyle())
      }
   }
}


