//
//  MetaView.swift
//  ModelSketch
//
//  Created by Ben Oztalay on 4/29/23.
//

import UIKit

class MetaNodeView: UIView {
    
    static func view(for node: MetaNode) -> MetaNodeView? {
        if let distanceConstraintNode = node as? MetaDistanceConstraintNode {
            return MetaDistanceConstraintNodeView(node: distanceConstraintNode)
        }
        
        return nil
    }
    
    let node: MetaNode
    
    init(node: MetaNode) {
        self.node = node
        super.init(frame: .zero)
    }
    
    func update(in superview: UIView) {
        if self.superview != superview {
            self.removeFromSuperview()
            superview.addSubview(self)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class MetaDistanceConstraintNodeView: MetaNodeView {
    
    var constraintNode: MetaDistanceConstraintNode {
        return self.node as! MetaDistanceConstraintNode
    }
    
    init(node: MetaDistanceConstraintNode) {
        super.init(node: node)
        self.backgroundColor = .clear
    }
    
    override func update(in superview: UIView) {
        super.update(in: superview)
        
        let minX = min(self.constraintNode.nodeA.x, self.constraintNode.nodeB.x)
        let minY = min(self.constraintNode.nodeA.y, self.constraintNode.nodeB.y)
        let maxX = max(self.constraintNode.nodeA.x, self.constraintNode.nodeB.x)
        let maxY = max(self.constraintNode.nodeA.y, self.constraintNode.nodeB.y)

        self.frame = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
        self.constraintNode.cgPoint = self.center

        self.setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(self.bounds)
        
        let path = UIBezierPath()
        path.move(to: self.constraintNode.nodeA.cgPoint.subtracting(self.frame.origin))
        path.addLine(to: self.constraintNode.nodeB.cgPoint.subtracting(self.frame.origin))

        UIColor.systemYellow.set()
        path.lineWidth = 2.0
        path.setLineDash([3.0, 3.0], count: 2, phase: 0)
        path.stroke()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class MetaView: UIView, Sketchable, NodePanGestureRecognizerDelegate {

    let graph: MetaGraph
    var nodeViews: [MetaNode : MetaNodeView]
    
    init(graph: MetaGraph) {
        self.graph = graph
        self.nodeViews = [:]

        super.init(frame: CGRect.zero)
        
        self.update()
    }
    
    func getNodeView(at location: CGPoint) -> UIView? {
        // TODO
        return nil
    }
    
    func hardPressStatusChanged(_ gestureRecognizer: NodePanGestureRecognizer) {
        // TODO
    }

    func handleNodePanGestureUpdate(_ gestureRecognizer: NodePanGestureRecognizer) {
        // TODO
    }
    
    func handleCreateGesture(at location: CGPoint) {
        // TODO
    }
    
    func handleScratchGesture(along points: [CGPoint]) {
        // TODO
    }
    
    func update() {
        for node in self.graph.nodes {
            if self.nodeViews[node] == nil {
                let nodeView = MetaNodeView.view(for: node)!
                self.nodeViews[node] = nodeView
            }
        }

        for node in self.nodeViews.keys {
            if !self.graph.nodes.contains(node) {
                let nodeView = self.nodeViews[node]!
                nodeView.removeFromSuperview()
                self.nodeViews.removeValue(forKey: node)
            }
        }
        
        for nodeView in self.nodeViews.values {
            nodeView.update(in: self)
        }
        
        self.setNeedsDisplay()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
