//
//  PencilGestureRecognizer.swift
//  ModelSketch
//
//  Created by Ben Oztalay on 4/12/23.
//

import CoreML
import UIKit

extension CGPoint {
    
    func intermediatePoints(to other: CGPoint, stride: CGFloat) -> [CGPoint] {
        var points = [CGPoint]()
        points.append(self)

        let angle = atan2(other.y - self.y, other.x - self.x)
        let rise = stride * sin(angle)
        let run = stride * cos(angle)
        
        while true {
            let startPoint = points.last!
            guard startPoint.distance(to: other) > stride else {
                break
            }
            
            points.append(CGPoint(x: startPoint.x + run, y: startPoint.y + rise))
        }
        
        return points
    }
    
    func adding(_ other: CGPoint) -> CGPoint {
        return CGPoint(
            x: self.x + other.x,
            y: self.y + other.y
        )
    }
    
    func subtracting(_ other: CGPoint) -> CGPoint {
        return CGPoint(
            x: self.x - other.x,
            y: self.y - other.y
        )
    }
    
    func scaled(by scalar: CGFloat) -> CGPoint {
        return CGPoint(
            x: scalar * self.x,
            y: scalar * self.y
        )
    }
}

extension CGRect {
    
    var center: CGPoint {
        return CGPoint(x: self.origin.x + self.width / 2.0, y: self.origin.y + self.height / 2.0)
    }
}

extension UITouch {

    var perpendicularForce: CGFloat {
        if self.type == .pencil {
            return self.force / sin(self.altitudeAngle)
        } else {
            return self.force
        }
    }
}

enum PencilGesture: String, CaseIterable, Identifiable {
    var id: Self { self }
    
    case create
    case scratch
    case line
    case curve
    
    var friendlyName: String {
        switch self {
            case .create:
                return "Create 'O'"
            case .scratch:
                return "Scratch"
            case .line:
                return "Line"
            case .curve:
                return "Curve"
        }
    }
}

class PencilStroke {

    static let minSize = 10.0
    static let maxSize = 200.0
    static let lineWidth = 2.0
    
    static let model = try! ModelSketchGestureClassifier(configuration: MLModelConfiguration())
    static let gestureClassProbabilityThreshold = 0.85

    let view: UIView
    private(set) var points: [CGPoint]
    private(set) var path: UIBezierPath?
    private(set) var image: UIImage?
    private(set) var gesture: PencilGesture?
    
    var pathFrame: CGRect? {
        guard points.count > 1 else {
            return nil
        }

        var minX = self.points.first!.x
        var minY = self.points.first!.y
        var maxX = minX
        var maxY = minY
        
        for point in points {
            minX = min(point.x, minX)
            minY = min(point.y, minY)
            maxX = max(point.x, maxX)
            maxY = max(point.y, maxY)
        }
        
        let pointsFrame = CGRect(
            x: minX,
            y: minY,
            width: maxX - minX,
            height: maxY - minY
        )
        
        return pointsFrame.insetBy(dx: -PencilStroke.lineWidth, dy: -PencilStroke.lineWidth)
    }
    
    init(view: UIView) {
        self.view = view
        self.points = []
    }
    
    func add(point: CGPoint) {
        guard self.image == nil else {
            fatalError("Tried to add a point to a PencilStroke after rendering it!")
        }
        
        self.points.append(point)
        
        if let path = self.path {
            path.addLine(to: point)
        } else {
            self.path = UIBezierPath()
            self.path!.move(to: point)
        }
    }
    
    func renderImage() -> UIImage? {
        guard self.image == nil else {
            return self.image
        }

        guard let pathFrame = self.pathFrame else {
            return nil
        }
        
        guard pathFrame.width >= PencilStroke.minSize || pathFrame.height >= PencilStroke.minSize else {
            return nil
        }
        
        guard pathFrame.width <= PencilStroke.maxSize && pathFrame.height <= PencilStroke.maxSize else {
            return nil
        }
        
        let renderer = UIGraphicsImageRenderer(bounds: pathFrame)
        self.image = renderer.image { rendererContext in
            self.view.layer.render(in: rendererContext.cgContext)
        }
        
        return self.image
    }
    
    func classify() -> PencilGesture? {
        guard self.gesture == nil else {
            return self.gesture
        }

        guard let image = self.renderImage() else {
            return nil
        }

        let prediction = try! PencilStroke.model.prediction(image: image.pixelBuffer()!)
        let gestureClass = PencilGesture(rawValue: prediction.classLabel)!
        
        let gestureProbability = prediction.classLabelProbs[gestureClass.rawValue]!
        guard gestureProbability >= PencilStroke.gestureClassProbabilityThreshold else {
            return nil
        }
        
        self.gesture = gestureClass
        return self.gesture
    }
    
    func walkPath(stride: CGFloat) -> [CGPoint]? {
        guard self.points.count > 1 else {
            return nil
        }
        
        var pointsAlongPath = [CGPoint]()
        
        for (i, point) in self.points.dropLast().enumerated() {
            let nextPoint = self.points[i + 1]
            pointsAlongPath.append(contentsOf: point.intermediatePoints(to: nextPoint, stride: stride))
        }
        
        return pointsAlongPath
    }
}

class PencilGestureRecognizer: InstantPanGestureRecognizer {
    
    var stroke: PencilStroke?
    var gesture: PencilGesture?
    
    override init(target: Any?, action: Selector?) {
        super.init(target: target, action: action)

        self.minimumNumberOfTouches = 1
        self.maximumNumberOfTouches = 1
//        self.allowedTouchTypes = [NSNumber(integerLiteral: UITouch.TouchType.pencil.rawValue)]
    }
    
    func addLocationToStroke() {
        guard let stroke = self.stroke else {
            return
        }

        stroke.add(point: self.location(in: self.view))
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)

        self.stroke = PencilStroke(view: self.view!)
        self.gesture = nil

        self.addLocationToStroke()
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)
        self.addLocationToStroke()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesEnded(touches, with: event)
        
        guard let stroke = self.stroke else {
            return
        }

        self.gesture = stroke.classify()
    }
}
