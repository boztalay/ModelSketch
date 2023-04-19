//
//  PencilGestureView.swift
//  ModelSketch
//
//  Created by Ben Oztalay on 4/13/23.
//

import CoreML
import SwiftUI
import UIKit
import Wave

class AnimatedPencilStroke {
    
    static let startingWhite = 0.70
    static let startingAlpha = 0.70
    
    let stroke: PencilStroke
    var color: UIColor
    var animator: SpringAnimator<CGFloat>
    var owningView: UIView?
    
    init() {
        self.stroke = PencilStroke()
        self.color = UIColor(white: AnimatedPencilStroke.startingWhite, alpha: AnimatedPencilStroke.startingAlpha)
        self.animator = SpringAnimator<CGFloat>(spring: Spring.defaultAnimated)
        self.animator.value = AnimatedPencilStroke.startingAlpha
        self.animator.target = 0.0
        
        self.animator.valueChanged = { [weak self] value in
            if let unwrappedSelf = self {
                unwrappedSelf.color = UIColor(white: AnimatedPencilStroke.startingWhite, alpha: value)
                unwrappedSelf.owningView?.setNeedsDisplay()
            }
        }
    }
    
    func startAnimating() {
        self.animator.start()
    }
}

class PencilStrokeView: UIView {
    
    var strokes: [AnimatedPencilStroke]
    var panGestureRecognizer: PencilInstantPanGestureRecognizer!
    let model: ModelSketchGestureClassifier
    
    var strokeCompletion: ((UIImage) -> ())?
    
    var currentStroke: AnimatedPencilStroke? {
        return self.strokes.last
    }
    
    init() {
        self.strokes = []
        self.model = try! ModelSketchGestureClassifier(configuration: MLModelConfiguration())
        
        super.init(frame: .zero)
        
        self.backgroundColor = .white
        
        self.panGestureRecognizer = PencilInstantPanGestureRecognizer(target: self, action: #selector(panGestureRecognizerUpdate))
        self.panGestureRecognizer.minimumNumberOfTouches = 1
        self.panGestureRecognizer.maximumNumberOfTouches = 1
    }
    
    @objc func panGestureRecognizerUpdate(_ gestureRecognizer : PencilInstantPanGestureRecognizer) {
        let location = gestureRecognizer.location(in: self)

        if gestureRecognizer.state == .began {
            let newStroke = AnimatedPencilStroke()
            newStroke.owningView = self
            self.strokes.append(newStroke)
        }
        
        if gestureRecognizer.state == .changed {
            if let currentStroke = self.currentStroke {
                currentStroke.stroke.add(point: location)
            }
        }
        
        if gestureRecognizer.state == .ended || gestureRecognizer.state == .cancelled {
            if let currentStroke = self.currentStroke {
                self.getStrokeImage()

                currentStroke.startAnimating()
                currentStroke.animator.completion = { _ in
                    self.strokes.remove(at: 0)
                }
            }
        }
        
        self.setNeedsDisplay()
    }
    
    func getStrokeImage() {
        guard let currentStroke = self.currentStroke, let strokeCompletion = self.strokeCompletion else {
            return
        }
        
        guard currentStroke.stroke.points.count > 1 else {
            return
        }
        
        let points = currentStroke.stroke.points
        var minX = points.first!.x
        var minY = points.first!.y
        var maxX = minX
        var maxY = minY
        
        for point in points {
            minX = min(point.x, minX)
            minY = min(point.y, minY)
            maxX = max(point.x, maxX)
            maxY = max(point.y, maxY)
        }
        
        let bounds = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY).insetBy(dx: -2.0, dy: -2.0)
        
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        let image = renderer.image { rendererContext in
            self.layer.render(in: rendererContext.cgContext)
        }

        let label = try! self.model.prediction(image: image.pixelBuffer()!)
        print(label.classLabel)
        print(label.classLabelProbs)

        strokeCompletion(image)
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        for stroke in self.strokes {
            guard stroke.stroke.points.count > 1 else {
                continue
            }
            
            let strokePath = UIBezierPath()
            strokePath.move(to: stroke.stroke.points.first!)
            for point in stroke.stroke.points.dropFirst() {
                strokePath.addLine(to: point)
            }
            
            stroke.color.set()
            strokePath.lineWidth = 2.0
            strokePath.stroke()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
