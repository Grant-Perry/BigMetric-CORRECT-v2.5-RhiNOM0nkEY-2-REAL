//
//  BigMetricApp.swift
//  BigMetric Watch App
//
//  Created by: Grant Perry on 5/25/23.
//    Modified: Modified: Monday January 8, 2024 at 8:08:20 PM

//			Trust ONLY this project 
//

import SwiftUI

let APP_NAME 		= "BigMetric"
let APP_VERSION 	= "3.1 RhiNO-M0nkEY"
let MOD_DATE 		= "Mod: 1/8/24 - 8:07 PM"

@main
struct BigMetric_Watch_AppApp: App {
   @Environment(\.scenePhase) var scenePhase
   @StateObject var distanceTracker     = DistanceTracker()
   @StateObject var workoutManager      = WorkoutManager()
   @StateObject var weatherKitManager   = WeatherKitManager()
   @StateObject var geoCodeHelper       = GeoCodeHelper()
   @State private var distanceTrackerInitialized = false

	/*	HOLY FUCKING COW! You know why...
	 This is the root - @main view; the 'source of truth' so @StateObject is
	 the parent - all other views needing access to the ParentObject need to use
	 @ObservedObject or @EnvironmentObject

	 @StateObject is the parent initializer for the object to be utilized in all child views.
	 In order to be part of the "family", any child view requiring access to any of the components
	 in the parent's need to use an ObservedObject or EnvironmentObject to "attach" to the parent's
	 (and subsequent child) view components.

	 @ObservedObject: This is used in child views that need to observe an object but don’t own it.
	 You typically pass an ObservableObject that was created by a parent view (using @StateObject)
	 to a child view and annotate it with @ObservedObject. This allows the child view to update
	 when the observed object changes.

	 @EnvironmentObject: This is another way to pass an observable object down the view hierarchy. Instead
	 of passing it directly to child views, you inject it into the environment of a view hierarchy using
	 .environmentObject(_:). Any view within this hierarchy can then access it by declaring it. It's
	 useful for data that needs to be accessed by many views at different levels in the view hierarchy.

	 The parent view initializes the child view with a modifier .environmentObject(observed-object-name) to share    */

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


