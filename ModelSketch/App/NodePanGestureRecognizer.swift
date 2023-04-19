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
    var startPoint: CGPoint?
    var nodeView: NodeView?
    var isHardPress: Bool

    init(modelView: ModelView, target: Any?, action: Selector?) {
        self.modelView = modelView
        self.isHardPress = false

        super.init(target: target, action: action)
        
        // TODO: Allow non-pencil touches
        self.minimumNumberOfTouches = 1
        self.maximumNumberOfTouches = 1
        self.allowedTouchTypes = [NSNumber(integerLiteral: UITouch.TouchType.pencil.rawValue)]
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        
        self.startPoint = nil
        self.nodeView = nil
        self.isHardPress = false
    
        let location = self.location(in: self.view)
        guard let nodeView = self.modelView.getNodeView(at: location) else {
            self.state = .failed
            return
        }
        
        self.startPoint = location
        self.nodeView = nodeView
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)
        
        guard let nodeView = self.nodeView else {
            return
        }
        
        if state == .possible {
            let translation = self.translation(in: self.view).distance(to: .zero)

            let force = touches.first!.force
            self.isHardPress = (force > NodePanGestureRecognizer.hardPressForceThreshold)
            
            if self.isHardPress {
                nodeView.setHighlightState(.startOfConnection)
            } else {
                nodeView.setHighlightState(.normal)
            }
            
            if translation > self.hysteresis {
                self.state = .began
            }
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
