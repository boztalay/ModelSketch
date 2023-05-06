//
//  MetaView.swift
//  ModelSketch
//
//  Created by Ben Oztalay on 4/29/23.
//

import UIKit

class MetaTerminalView: UIView {
    
    static let radius = 5.0
    static let touchTargetScale = 1.5
    
    init() {
        super.init(frame: CGRect(x: 0.0, y: 0.0, width: MetaTerminalView.radius * 2.0, height: MetaTerminalView.radius * 2.0))
        
        self.backgroundColor = .white
        self.layer.borderColor = UIColor.systemYellow.cgColor
        self.layer.cornerRadius = ConstructionNodeView.radius
        self.layer.borderWidth = 2.0
    }
    
    func containsPoint(_ point: CGPoint) -> Bool {
        return (point.distance(to: self.center) < (MetaTerminalView.radius * MetaTerminalView.touchTargetScale))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

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
    
    func view(at point: CGPoint) -> UIView? {
        return nil
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class MetaDistanceQuantityNodeView: MetaNodeView {
    
    var label: UILabel!
    var minTerminalView: MetaTerminalView!
    var maxTerminalView: MetaTerminalView!
    
    var quantityNode: MetaDistanceQuantityNode {
        return self.node as! MetaDistanceQuantityNode
    }
    
    init(node: MetaDistanceQuantityNode) {
        super.init(node: node)

        self.backgroundColor = .clear
        
        self.label = UILabel(frame: .zero)
        self.addSubview(self.label)
        self.label.font = UIFont.systemFont(ofSize: 10.0)
        self.label.textColor = .systemYellow
        self.label.backgroundColor = .white
        self.label.textAlignment = .center
        
        self.minTerminalView = MetaTerminalView()
        self.addSubview(self.minTerminalView)
        
        self.maxTerminalView = MetaTerminalView()
        self.addSubview(self.maxTerminalView)
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
        
        let delta = CGPoint(
            x: self.quantityNode.nodeB.x - self.quantityNode.nodeA.x,
            y: self.quantityNode.nodeB.y - self.quantityNode.nodeA.y
        )

        self.minTerminalView.center = self.quantityNode.nodeA.cgPoint.adding(delta.scaled(by: 0.25)).subtracting(self.frame.origin)
        self.maxTerminalView.center = self.quantityNode.nodeA.cgPoint.adding(delta.scaled(by: 0.75)).subtracting(self.frame.origin)

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
    
    override func view(at location: CGPoint) -> UIView? {
        if self.minTerminalView.containsPoint(location.subtracting(self.frame.origin)) {
            return self.minTerminalView
        }
        
        if self.maxTerminalView.containsPoint(location.subtracting(self.frame.origin)) {
            return self.maxTerminalView
        }
        
        return nil
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
        for nodeView in self.nodeViews.values {
            if let view = nodeView.view(at: location) {
                return view
            }
        }

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
                // TODO: Move the current node around, if it's movable
            }
        }
        
        if gestureRecognizer.state == .ended || gestureRecognizer.state == .cancelled {
            if gestureRecognizer.isHardPress {
                if let startNodeView = self.partialConnection?.0 as? ConstructionNodeView {
                    if let endNodeView = self.constructionView.getNodeView(at: location) as? ConstructionNodeView {
                        let distanceNode = MetaDistanceQuantityNode(nodeA: startNodeView.node, nodeB: endNodeView.node, min: 50.0, max: 150.0)
                        self.graph.add(node: distanceNode)
                    }
                    
                    startNodeView.setHighlightState(.normal)
                }
                
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
        
        var start: CGPoint? = nil
        var end: CGPoint? = nil
        
        if let (nodeView, endPoint) = self.partialConnection as? (ConstructionNodeView, CGPoint) {
            start = nodeView.node.cgPoint
            end = endPoint
        } else if let (terminalView, endPoint) = self.partialConnection as? (MetaTerminalView, CGPoint) {
            start = terminalView.center.adding(terminalView.superview!.frame.origin)
            end = endPoint
        }
        
        if let start = start, let end = end {
            self.drawLine(start: start, end: end, lineWidth: 3.0, color: .systemYellow)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
