//
//  PencilStrokeView.swift
//  ModelSketch
//
//  Created by Ben Oztalay on 4/13/23.
//

import UIKit
import Wave

class AnimatedPencilStroke {
    
    let stroke: PencilStroke
    var color: UIColor
    var animator: SpringAnimator<CGFloat>
    var owningView: UIView?
    
    init() {
        self.stroke = PencilStroke()
        self.color = UIColor.lightGray
        self.animator = SpringAnimator<CGFloat>(spring: Spring.defaultAnimated)
        self.animator.value = 1.0
        self.animator.target = 0.0
        
        self.animator.valueChanged = { [weak self] value in
            if let unwrappedSelf = self {
                unwrappedSelf.color = UIColor(white: 0.70, alpha: value)
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
    var panGestureRecognizer: UIPanGestureRecognizer!
    
    var currentStroke: AnimatedPencilStroke? {
        return self.strokes.last
    }
    
    init() {
        self.strokes = []
        
        super.init(frame: .zero)
        
        self.backgroundColor = .white
        
        self.panGestureRecognizer = InstantPanGestureRecognizer(target: self, action: #selector(panGestureRecognizerUpdate))
        self.panGestureRecognizer.minimumNumberOfTouches = 1
        self.panGestureRecognizer.maximumNumberOfTouches = 1
    }
    
    @objc func panGestureRecognizerUpdate(_ gestureRecognizer : UIPanGestureRecognizer) {
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
                currentStroke.startAnimating()
                currentStroke.animator.completion = { _ in
                    self.strokes.remove(at: 0)
                }
            }
        }
        
        self.setNeedsDisplay()
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
