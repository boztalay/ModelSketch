//
//  NodePanGestureRecognizer.swift
//  ModelSketch
//
//  Created by Ben Oztalay on 4/19/23.
//

import UIKit

protocol NodePanGestureRecognizerDelegate {
    func getNodeView(at location: CGPoint) -> UIView?
    func hardPressStatusChanged(_ gestureRecognizer: NodePanGestureRecognizer)
}

class NodePanGestureRecognizer: UIPanGestureRecognizer {
    
    static let hardPressForceThreshold = 1.5
    
    var nodeDelegate: NodePanGestureRecognizerDelegate?
    var hysteresis: CGFloat = ConstructionNodeView.radius

    var nodeView: UIView?
    var isHardPress: Bool
    var lastLocation: CGPoint?
    var translationDelta: CGPoint?

    override init(target: Any?, action: Selector?) {
        self.isHardPress = false

        super.init(target: target, action: action)

        self.minimumNumberOfTouches = 1
        self.maximumNumberOfTouches = 1
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        guard let nodeDelegate = self.nodeDelegate else {
            return
        }

        self.nodeView = nil
        self.isHardPress = false
        self.lastLocation = nil
        self.translationDelta = nil
    
        let location = self.location(in: self.view)
        guard let nodeView = nodeDelegate.getNodeView(at: location) else {
            self.state = .failed
            return
        }

        self.nodeView = nodeView
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)
        guard let nodeDelegate = self.nodeDelegate else {
            return
        }
        
        let location = self.location(in: self.view)
        if let lastLocation = self.lastLocation {
            self.translationDelta = location.subtracting(lastLocation)
        }
 
        self.lastLocation = location
        
        if self.state == .possible {
            let force = touches.first!.perpendicularForce
            self.isHardPress = (force > NodePanGestureRecognizer.hardPressForceThreshold)
            
            nodeDelegate.hardPressStatusChanged(self)

            let distanceMoved = self.translation(in: self.view).distance(to: .zero)
            if distanceMoved > self.hysteresis {
                self.state = .began
            }
        } else if self.state == .began {
            self.state = .changed
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesEnded(touches, with: event)
    }
}
