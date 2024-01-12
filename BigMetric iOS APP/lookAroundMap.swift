//   lookAroundMap.swift
//   BigMetric
//
//   Created by: Grant Perry on 1/12/24 at 11:04 AM
//     Modified:
//
//  Copyright © 2024 Delicious Studios, LLC. - Grant Perry
//

import SwiftUI
import MapKit

extension CLLocationCoordinate2D {
	static let parking = CLLocationCoordinate2D(latitude: 42.354528, longitude: -71.068369)
}
	struct lookAroundMap: View {
		@State private var searchResults: [MKMapItem] = []
		@State private var position: MapCameraPosition = .automatic

		var body: some View {
			Map {
				Annotation ( "Parking", coordinate: .parking) {
					ZStack {
						RoundedRectangle(cornerRadius: 5)
							.fill(.background)
						RoundedRectangle (cornerRadius: 5)
							.stroke(.secondary, lineWidth: 5)
						Image (systemName: "car")
							.padding (5)
					}
				}
				.annotationTitles(.hidden)
				ForEach(searchResults, id: \.self) { result in
					Marker(item: result)
				}
			}
			.mapStyle(.hybrid(elevation: .realistic))
			.safeAreaInset(edge: .bottom) {
				HStack {
					Spacer()
					mapNavBtns(searchResults: $searchResults)
						.padding(.top)
					Spacer()
				}
				.background(.ultraThinMaterial)
			}
			}
		}


#Preview {
	lookAroundMap()
}


