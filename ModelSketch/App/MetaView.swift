//
//  MetaView.swift
//  ModelSketch
//
//  Created by Ben Oztalay on 4/29/23.
//

import UIKit

class MetaNodeView: UIView {
    
    static func view(for node: MetaNode) -> MetaNodeView? {
        if let distanceQuantityNode = node as? MetaDistanceQuantityNode {
            return MetaDistanceQuantityNodeView(node: distanceQuantityNode)
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

class MetaDistanceQuantityNodeView: MetaNodeView {
    
    let label: UILabel
    
    var quantityNode: MetaDistanceQuantityNode {
        return self.node as! MetaDistanceQuantityNode
    }
    
    init(node: MetaDistanceQuantityNode) {
        self.label = UILabel(frame: .zero)

        super.init(node: node)

        self.backgroundColor = .clear
        
        self.addSubview(self.label)
        self.label.font = UIFont.systemFont(ofSize: 10.0)
        self.label.textColor = .systemYellow
        self.label.backgroundColor = .white
        self.label.textAlignment = .center
    }
    
    override func update(in superview: UIView) {
        super.update(in: superview)
        
        let minX = min(self.quantityNode.nodeA.x, self.quantityNode.nodeB.x)
        let minY = min(self.quantityNode.nodeA.y, self.quantityNode.nodeB.y)
        let maxX = max(self.quantityNode.nodeA.x, self.quantityNode.nodeB.x)
        let maxY = max(self.quantityNode.nodeA.y, self.quantityNode.nodeB.y)

        self.frame = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY).insetBy(dx: -2.0, dy: -2.0)
        self.quantityNode.cgPoint = self.center
        
        self.label.text = "\(Int(round(self.quantityNode.getQuantity())))"
        self.label.sizeToFit()
        self.label.frame = self.label.frame.insetBy(dx: -2.0, dy: -1.0)
        self.label.layer.cornerRadius = self.label.frame.height / 3.0
        self.label.layer.masksToBounds = true
        self.label.center = self.center.subtracting(self.frame.origin)

        self.setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(self.bounds)
        
        let path = UIBezierPath()
        path.move(to: self.quantityNode.nodeA.cgPoint.subtracting(self.frame.origin))
        path.addLine(to: self.quantityNode.nodeB.cgPoint.subtracting(self.frame.origin))

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
