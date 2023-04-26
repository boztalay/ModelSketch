//
//  NodePanGestureRecognizer.swift
//  ModelSketch
//
//  Created by Ben Oztalay on 4/19/23.
//

import UIKit

class NodePanGestureRecognizer: UIPanGestureRecognizer {
    
    static let hardPressForceThreshold = 1.5
    
    let modelView: ModelView
    var hysteresis: CGFloat = NodeView.radius

    var nodeView: NodeView?
    var isHardPress: Bool
    var lastLocation: CGPoint?
    var translationDelta: CGPoint?

    init(modelView: ModelView, target: Any?, action: Selector?) {
        self.modelView = modelView
        self.isHardPress = false

        super.init(target: target, action: action)

        self.minimumNumberOfTouches = 1
        self.maximumNumberOfTouches = 1
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)

        self.nodeView = nil
        self.isHardPress = false
        self.lastLocation = nil
        self.translationDelta = nil
    
        let location = self.location(in: self.view)
        guard let nodeView = self.modelView.getNodeView(at: location) else {
            self.state = .failed
            return
        }

        self.nodeView = nodeView
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)
        
        guard let nodeView = self.nodeView else {
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
            
            if self.isHardPress {
                nodeView.setHighlightState(.startOfConnection)
            } else {
                nodeView.setHighlightState(.normal)
            }
            
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
        
        guard let nodeView = self.nodeView else {
            return
        }
        
        nodeView.setHighlightState(.normal)
    }
}
