//   MKPolyLine.swift
//   BigMetric
//
//   Created by: Grant Perry on 12/29/23 at 4:40 PM
//     Modified: 
//
//  Copyright © 2023 Delicious Studios, LLC. - Grant Perry
//

import SwiftUI
import CoreLocation
import MapKit

extension MKPolyline {
	/*
	 RDP stands for "Ramer-Douglas-Peucker" RDP; an algorithm used for polyline simplification.
	 The RDP is used to reduce the number of points in a polyline while preserving its essential
	 shape. It works by iteratively removing points that are within a specified distance (epsilon)
	 of a straight line connecting two nearby points.
	 */

	func simplifyUsingRDP(epsilon: Double) -> MKPolyline {
		let count			= self.pointCount
		if count < 3 {
			return self
		}
		let points 			= self.points()
		var keep				= [Bool](repeating: false,
											count: count)
		keep[0] 				= true
		keep[count - 1] 	= true

		compressRDP(points: points,
						start: 0,
						end: count - 1,
						epsilon: epsilon,
						keep: &keep)

		var newPoints = [MKMapPoint]()
		for i in 0..<count {
			if keep[i] {
				newPoints.append(points[i])
			}
		}

		return MKPolyline(points: newPoints,
								count: newPoints.count)
	}

	private func compressRDP(points: UnsafeMutablePointer<MKMapPoint>,
									 start: Int,
									 end: Int,
									 epsilon: Double,
									 keep: inout [Bool]) {
		if end <= start + 1 {
			return
		}

		var maxDistance 	= 0.0
		var maxIndex 		= 0

		for i in (start + 1)..<end {
			let distance = perpendicularDistance(point: points[i],
															 lineStart: points[start],
															 lineEnd: points[end])

			if distance > maxDistance {
				maxDistance = distance
				maxIndex 	= i
			}
		}

		if maxDistance > epsilon {
			keep[maxIndex] = true

			compressRDP(points: points,
							start: start,
							end: maxIndex,
							epsilon: epsilon,
							keep: &keep)

			compressRDP(points: points,
							start: maxIndex,
							end: end,
							epsilon: epsilon,
							keep: &keep)
		}
	}

	private func perpendicularDistance(point: MKMapPoint,
												  lineStart: MKMapPoint,
												  lineEnd: MKMapPoint) -> Double {
		let lineLength = lineStart.distance(to: lineEnd)
		if lineLength == 0.0 {
			return point.distance(to: lineStart)
		}

		let t = ((point.x - lineStart.x) * (lineEnd.x - lineStart.x) + (point.y - lineStart.y) * (lineEnd.y - lineStart.y)) / (lineLength * lineLength)

		if t < 0.0 {
			return point.distance(to: lineStart)
		}

		if t > 1.0 {
			return point.distance(to: lineEnd)
		}

		let projectionX = lineStart.x + t * (lineEnd.x - lineStart.x)
		let projectionY = lineStart.y + t * (lineEnd.y - lineStart.y)

		return point.distance(to: MKMapPoint(x: projectionX, y: projectionY))
	}
}
