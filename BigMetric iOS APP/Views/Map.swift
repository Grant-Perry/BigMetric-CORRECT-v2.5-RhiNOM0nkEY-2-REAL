//
//  Map.swift
//  Workouts
//
//   Created by: Grant Perry
//  Modified on: Friday December 29, 2023 at 4:12:56 PM
//

import SwiftUI
import UIKit
import MapKit

struct MapView: UIViewRepresentable {
	let mapView: MKMapView

	func makeUIView(context: UIViewRepresentableContext<MapView>) -> MKMapView {
		return mapView
	}

	func updateUIView(_ view: MKMapView,
							context: UIViewRepresentableContext<MapView>) {
	}
}

class MapViewDelegate: NSObject, MKMapViewDelegate {
	func mapView(_ mapView: MKMapView,
					 rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
		if let polylineOverlay 	= overlay as? MKPolyline {
			let renderer 			= GradientPolylineRenderer(polyline: polylineOverlay)
			renderer.lineWidth 	= 12
			return renderer
		}
		return MKOverlayRenderer(overlay: overlay)
	}
}

class MKMapViewWithRenderers {
   public let mapView: MKMapView;
   public let delegate: MapViewDelegate

   public init() {
      let mapView = MKMapView()
      let delegate = MapViewDelegate()

		mapView.delegate = delegate
      self.mapView = mapView
      self.delegate = delegate
   }

   func get() -> (MKMapView, MapViewDelegate) {
      return (self.mapView, self.delegate)
   }

   func randomCGFloat() -> CGFloat {
      return CGFloat(arc4random()) / CGFloat(UInt32.max)
   }

   func randomColor() -> UIColor {
      return UIColor(
         red:   randomCGFloat(),
         green: randomCGFloat(),
         blue:  randomCGFloat(),
         alpha: 1
      )
   }
}
