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
        
        self.label.text = "\(Int(round(self.quantityNode.readQuantity())))"
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
    let constructionView: ConstructionView
    var nodeViews: [MetaNode : MetaNodeView]
    var partialConnection: (UIView, CGPoint)?
    
    init(graph: MetaGraph, constructionView: ConstructionView) {
        self.graph = graph
        self.constructionView = constructionView
        self.nodeViews = [:]

        super.init(frame: CGRect.zero)
        
        self.backgroundColor = .clear
    }
    
    func getNodeView(at location: CGPoint) -> UIView? {
        // TODO
        return self.constructionView.getNodeView(at: location)
    }
    
    func hardPressStatusChanged(_ gestureRecognizer: NodePanGestureRecognizer) {
        if let nodeView = gestureRecognizer.nodeView as? ConstructionNodeView {
            if gestureRecognizer.isHardPress {
                nodeView.setHighlightState(.startOfMetaQuantity)
            } else {
                nodeView.setHighlightState(.normal)
            }
        }
    }

    func handleNodePanGestureUpdate(_ gestureRecognizer: NodePanGestureRecognizer) {
        let location = gestureRecognizer.location(in: self)

        if gestureRecognizer.state == .began {
            if gestureRecognizer.isHardPress {
                if let nodeView = gestureRecognizer.nodeView {
                    self.partialConnection = (nodeView, location)
                    self.setNeedsDisplay()
                }
            }
        }
        
        if gestureRecognizer.state == .changed {
            if gestureRecognizer.isHardPress {
                if let nodeView = gestureRecognizer.nodeView {
                    self.partialConnection = (nodeView, location)
                    self.setNeedsDisplay()
                }
            } else if let translationDelta = gestureRecognizer.translationDelta {
                // TODO: Move the current node around
            }
        }
        
        if gestureRecognizer.state == .ended || gestureRecognizer.state == .cancelled {
            if gestureRecognizer.isHardPress {
                guard let startNodeView = self.partialConnection?.0 as? ConstructionNodeView else {
                    return
                }
                
                if let endNodeView = self.constructionView.getNodeView(at: location) as? ConstructionNodeView {
                    let distanceNode = MetaDistanceQuantityNode(nodeA: startNodeView.node, nodeB: endNodeView.node)
                    self.graph.add(node: distanceNode)
                }
                
                startNodeView.setHighlightState(.normal)
                
                self.partialConnection = nil
                self.update()
            }
        }
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
    
    func drawLine(start: CGPoint, end: CGPoint, lineWidth: CGFloat, color: UIColor) {
        let path = UIBezierPath()
        path.move(to: start)
        path.addLine(to: end)
        
        color.set()
        path.lineWidth = lineWidth
        path.stroke()
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(self.bounds)
        
        if let (nodeView, endPoint) = self.partialConnection as? (ConstructionNodeView, CGPoint) {
            let startPoint = nodeView.node.cgPoint
            self.drawLine(start: startPoint, end: endPoint, lineWidth: 3.0, color: .systemYellow)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
