//
//  PencilStrokeView.swift
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
    
    init(stroke: PencilStroke) {
        self.stroke = stroke

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
    
    func render() {
        guard let strokePath = self.stroke.path else {
            return
        }
        
        self.color.set()
        strokePath.lineWidth = PencilStroke.lineWidth
        strokePath.stroke()
        
        guard let walkPoints = self.stroke.walkPath(stride: 10.0) else {
            return
        }
        
        UIColor.systemRed.set()
        for point in walkPoints {
            UIBezierPath(ovalIn: CGRect(x: point.x - 1.0, y: point.y - 1.0, width: 2.0, height: 2.0)).fill()
        }
    }
}

class PencilStrokeView: UIView {
    
    var strokes: [AnimatedPencilStroke]
    var pencilGestureRecognizer: PencilGestureRecognizer!
    var animates = true
    
    var strokeCompletion: ((PencilStroke) -> ())?
    
    var currentStroke: AnimatedPencilStroke? {
        return self.strokes.last
    }
    
    init() {
        self.strokes = []
        
        super.init(frame: .zero)
        
        self.backgroundColor = .white
        
        self.pencilGestureRecognizer = PencilGestureRecognizer(target: self, action: #selector(pencilGestureRecognizerUpdate))
        self.pencilGestureRecognizer.minimumNumberOfTouches = 1
        self.pencilGestureRecognizer.maximumNumberOfTouches = 1
        self.addGestureRecognizer(self.pencilGestureRecognizer)
    }
    
    @objc func pencilGestureRecognizerUpdate(_ gestureRecognizer : PencilGestureRecognizer) {
        if gestureRecognizer.state == .began {
            let newStroke = AnimatedPencilStroke(stroke: gestureRecognizer.stroke!)
            newStroke.owningView = self
            
            if !self.animates && self.strokes.count > 0 {
                self.strokes.remove(at: 0)
            }
            
            self.strokes.append(newStroke)
        }
        
        if gestureRecognizer.state == .ended {
            if let currentStroke = self.currentStroke {
                if let strokeCompletion = self.strokeCompletion {
                    strokeCompletion(currentStroke.stroke)
                }
                
                if self.animates {
                    currentStroke.startAnimating()
                    currentStroke.animator.completion = { _ in
                        self.strokes.remove(at: 0)
                    }
                }
            }
        }
        
        if gestureRecognizer.state == .cancelled {
            self.strokes.remove(at: 0)
        }
        
        self.setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        for stroke in self.strokes {
            stroke.render()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
