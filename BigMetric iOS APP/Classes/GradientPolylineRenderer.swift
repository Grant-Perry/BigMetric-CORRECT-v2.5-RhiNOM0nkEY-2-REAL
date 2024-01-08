//   GradientPolylineRenderer.swift
//   BigMetric
//
//   Created by: Grant Perry on 12/29/23 at 4:42 PM
//     Modified: 
//
//  Copyright © 2023 Delicious Studios, LLC. - Grant Perry
//
/*
 This class is utilized for the iOS app to create the gradient polyline overlay
 */

import SwiftUI
import UIKit
import MapKit

class GradientPolylineRenderer: MKPolylineRenderer {
	override func draw(_ mapRect: MKMapRect,
							 zoomScale: MKZoomScale,
							 in context: CGContext) {
		/*
		 context.saveGState()
		 called at the beginning of a rendering operation to preserve the current graphics state. Then,
		 after various drawing operations are performed, context.restoreGState() is called to return the
		 graphics context to its original state before the rendering began. This ensures that changes made
		 during rendering do not affect subsequent drawing operations or elements on the same context.
		 */
		context.saveGState()
		// Set the epsilon value to nix non-necessary way points
		let simplifiedPolyline = self.polyline.simplifyUsingRDP(epsilon: 0.0001)

		let path = createStrokedPath(for: simplifiedPolyline,
											  lineWidth: self.lineWidth / zoomScale)
		context.addPath(path)
		context.setLineWidth(self.lineWidth / zoomScale)
		context.clip()

		let totalPoints 	= simplifiedPolyline.pointCount
		let points 			= simplifiedPolyline.points()

		// Segmentation indices
		let greenEndPoint 	= totalPoints / 4    // 25%
		let yellowEndPoint 	= totalPoints * 3 / 4  // 75%

		for i in 0..<(totalPoints - 1) {
			let start 	= points[i]
			let end 		= points[i + 1]
			if i < greenEndPoint {
				drawSegment(from: start,
								to: end,
								color: UIColor(Color.green),
								in: context)
			} else if i < yellowEndPoint {
				drawSegment(from: start,
								to: end,
								color: UIColor(Color.yellow),
								in: context)
			} else {
				drawSegment(from: start,
								to: end,
								color: UIColor(Color.red),
								in: context)
			}
		}
		context.restoreGState()
	}

	private func createStrokedPath(for polyline: MKPolyline, 
											 lineWidth: CGFloat) -> CGPath {
		let path 	= CGMutablePath()
		let points 	= polyline.points()
		let count 	= polyline.pointCount

		if count < 2 {
			return path
		}

		path.move(to: self.point(for: points[0]))

		for i in 1..<count {
			let point = self.point(for: points[i])
			path.addLine(to: point)
		}

		let strokedPath = path.copy(strokingWithWidth: lineWidth, 
											 lineCap: .round,
											 lineJoin: .round,
											 miterLimit: 0)
		return strokedPath
	}

	private func drawSegment(from start: MKMapPoint, 
									 to end: MKMapPoint,
									 color: UIColor,
									 in context: CGContext) {
		let startPoint = self.point(for: start)  	// Convert MKMapPoint to CGPoint
		let endPoint 	= self.point(for: end)     // Convert MKMapPoint to CGPoint

		let path = CGMutablePath()
		path.move(to: startPoint)
		path.addLine(to: endPoint)

		context.addPath(path)
		context.setStrokeColor(color.cgColor)
		context.strokePath()
	}
}
