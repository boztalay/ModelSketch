//
//  PencilDeleteGestureRecognizer.swift
//  ModelSketch
//
//  Created by Ben Oztalay on 4/12/23.
//

import UIKit

extension CGFloat {

    func isCloseToZero(epsilon: CGFloat? = nil) -> Bool {
        var epsilonToUse = 0.00001

        if let epsilon = epsilon {
            epsilonToUse = epsilon
        }
        
        return abs(self) < epsilonToUse
    }
}

class PencilLine {
    
    let start: CGPoint
    let end: CGPoint
    var error: CGFloat
    
    var slope: CGFloat {
        return (self.end.y - self.start.y) / (self.end.x - self.start.x)
    }
    
    var yIntercept: CGFloat {
        return self.start.y - (self.slope * self.start.x)
    }
    
    init(start: CGPoint, end: CGPoint) {
        self.start = start
        self.end = end
        self.error = 0.0
    }
    
    func calculateError(from points: [CGPoint]) {
        self.error = 0.0

        for point in points {
            let lineY = self.slope * point.x + self.yIntercept
            self.error += abs(lineY - point.y)
        }
    }
    
    func reflectedOverXYAxis() -> PencilLine {
        let reflectedLine = PencilLine(start: CGPoint(x: self.start.y, y: self.start.x), end: CGPoint(x: self.end.y, y: self.end.x))
        reflectedLine.error = self.error
        
        return reflectedLine
    }
    
    func contains(point: CGPoint) -> Bool {
        let lowerX = min(self.start.x, self.end.x)
        let upperX = max(self.start.x, self.end.x)
        let lowerY = min(self.start.y, self.end.y)
        let upperY = max(self.start.y, self.end.y)
        
        return (point.x >= lowerX && point.x <= upperX) && (point.y >= lowerY && point.y <= upperY)
    }
    
    func intersection(with other: PencilLine) -> CGPoint? {
        guard self.slope != other.slope else {
            return nil
        }
        
        // y1 = m1x1 + b1
        // y2 = m2x2 + b2
        // m1x + b1 = m2x + b2
        // m1x - m2x = b2 - b1
        // x = (b2 - b1) / (m1 - m2)
        let intersectionX = (other.yIntercept - self.yIntercept) / (self.slope - other.slope)
        let intersection = CGPoint(
            x: intersectionX,
            y: (self.slope * intersectionX) + self.yIntercept
        )
        
        guard self.contains(point: intersection) && other.contains(point: intersection) else {
            return nil
        }
        
        return intersection
    }
}

class PencilStroke {

    var points: [CGPoint]
    
    init() {
        self.points = []
    }
    
    func add(point: CGPoint) {
        self.points.append(point)
    }
    
    func snapToLine() -> PencilLine? {
        guard let originalBestFit = self.bestFitLine() else {
            return nil
        }
        
        guard let reflectedBestFit = self.reflectedOverXYAxis().bestFitLine() else {
            return nil
        }
        
        var bestFit = originalBestFit
        if reflectedBestFit.error < bestFit.error {
            bestFit = reflectedBestFit.reflectedOverXYAxis()
        }
        
        guard bestFit.error < 50.0 else {
            return nil
        }
        
        return bestFit
    }
    
    func bestFitLine() -> PencilLine? {
        guard self.points.count > 2 else {
            return nil
        }
        
        // Throw away the first and last points if possible (helps with linearity)
        var regressionPoints = self.points
        if regressionPoints.count > 5 {
            regressionPoints = Array<CGPoint>(regressionPoints.dropFirst())
            regressionPoints = Array<CGPoint>(regressionPoints.dropLast())
        }
        
        // Linear regression
        var sumXX: CGFloat = 0.0  // sum of X^2
        var sumXY: CGFloat = 0.0  // sum of X * Y
        var sumX: CGFloat = 0.0  // sum of X
        var sumY: CGFloat = 0.0  // sum of Y
        let count = CGFloat(regressionPoints.count)
        
        for point in regressionPoints {
            sumXX += point.x * point.x
            sumXY += point.x * point.y
            sumX += point.x
            sumY += point.y
        }
        
        // Calculate the slope's numerator and check if it's close to zero
        // (if it is, assume the line is roughly horizontal)
        let slopeNumerator = count * sumXY - sumX * sumY
        guard !slopeNumerator.isCloseToZero() else {
            let averageY = sumY / count
            let line = PencilLine(
                start: CGPoint(x: self.points.first!.x, y: averageY),
                end: CGPoint(x: self.points.last!.x, y: averageY)
            )
            
            line.calculateError(from: regressionPoints)
            return line
        }
        
        // Calculate the slope's numerator and check if it's close to zero
        // (if it is, assume the line is roughly vertical)
        let slopeDenominator = count * sumXX - sumX * sumX
        guard !slopeDenominator.isCloseToZero() else {
            let averageX = sumX / count
            let line = PencilLine(
                start: CGPoint(x: averageX, y: self.points.first!.y),
                end: CGPoint(x: averageX, y: self.points.last!.y)
            )
            
            line.calculateError(from: regressionPoints)
            return line
        }
        
        // Calculate the slope and Y intercept of the line
        let slope = slopeNumerator / slopeDenominator
        let yIntercept = (sumY - (slope * sumX)) / count
        
        // Construct a line from the line equation using the full set of points
        let line = PencilLine(
            start: CGPoint(
                x: self.points.first!.x,
                y: slope * self.points.first!.x + yIntercept
            ),
            end: CGPoint(
                x: self.points.last!.x,
                y: slope * self.points.last!.x + yIntercept
            )
        )
        
        line.calculateError(from: regressionPoints)
        return line
    }
    
    func reflectedOverXYAxis() -> PencilStroke {
        let reflectedStroke = PencilStroke()
        for point in self.points {
            reflectedStroke.add(point: CGPoint(x: point.y, y: point.x))
        }
        
        return reflectedStroke
    }
}

class PencilDeleteGestureRecognizer: InstantPanGestureRecognizer {
    
    static let strokeTimeout = 0.4
    
    var strokes: [PencilStroke]
    var lastStrokeEndedTime: Date?
    var intersection: CGPoint?
    
    override init(target: Any?, action: Selector?) {
        self.strokes = []
        
        super.init(target: target, action: action)

        self.minimumNumberOfTouches = 1
        self.maximumNumberOfTouches = 1
        self.allowedTouchTypes = [NSNumber(integerLiteral: UITouch.TouchType.pencil.rawValue)]
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)

        if let lastStrokeEndedTime = self.lastStrokeEndedTime {
            let elapsedTime = Date().timeIntervalSince(lastStrokeEndedTime)
            if elapsedTime > PencilDeleteGestureRecognizer.strokeTimeout {
                self.strokes = []
            }
        }
        
        self.intersection = nil
        
        if self.strokes.count > 2 {
            self.strokes = Array<PencilStroke>(self.strokes.dropFirst())
        }

        self.strokes.append(PencilStroke())
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)
        
        guard let currentStroke = self.strokes.last else {
            return
        }
        
        let location = self.location(in: self.view)
        currentStroke.add(point: location)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesEnded(touches, with: event)
        
        self.lastStrokeEndedTime = Date()
        
        guard self.strokes.count == 2 else {
            return
        }
        
        if let lineA = self.strokes[0].snapToLine(), let lineB = self.strokes[1].snapToLine() {
            self.intersection = lineA.intersection(with: lineB)
        }
        
        self.strokes = []
    }
}
