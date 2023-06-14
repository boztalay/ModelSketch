//
//  MetaView.swift
//  ModelSketch
//
//  Created by Ben Oztalay on 4/29/23.
//

import UIKit

class MetaQuanitityLabel: UILabel {
    
    func containsPoint(_ point: CGPoint) -> Bool {
        return (point.distance(to: self.center) < (MetaTerminalView.radius * MetaTerminalView.touchTargetScale))
    }
}

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
        if let distanceNode = node as? MetaDistanceNode {
            return MetaDistanceNodeView(node: distanceNode)
        } else if let angleNode = node as? MetaAngleNode {
            return MetaAngleNodeView(node: angleNode)
        } else if let railNode = node as? MetaRailNode {
            return MetaRailNodeView(node: railNode)
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

class MetaDistanceNodeView: MetaNodeView {
    
    var label: MetaQuanitityLabel!
    
    var quantityNode: MetaDistanceNode {
        return self.node as! MetaDistanceNode
    }
    
    init(node: MetaDistanceNode) {
        super.init(node: node)

        self.backgroundColor = .clear
        
        self.label = MetaQuanitityLabel(frame: .zero)
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
    
    override func view(at location: CGPoint) -> UIView? {
        if self.label.containsPoint(location.subtracting(self.frame.origin)) {
            return self.label
        }
        
        return nil
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class MetaAngleNodeView: MetaNodeView {
    // TODO
}

class MetaRailNodeView: MetaNodeView {
    // TODO
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
                let startView = self.partialConnection?.0
                
                if let startNodeView = startView as? ConstructionNodeView {
                    if let endNodeView = self.constructionView.getNodeView(at: location) as? ConstructionNodeView {
                        let distanceNode = MetaDistanceNode(nodeA: startNodeView.node, nodeB: endNodeView.node)
                        self.graph.add(node: distanceNode)
                    }
                    
                    startNodeView.setHighlightState(.normal)
                } else if let startQuantityLabel = startView as? MetaQuanitityLabel {
                    if let endQuantityLabel = self.getNodeView(at: location) as? MetaQuanitityLabel {
                        let startDistanceNodeView = startQuantityLabel.superview as! MetaDistanceNodeView
                        let endDistanceNodeView = endQuantityLabel.superview as! MetaDistanceNodeView
                        
                        let startNode = startDistanceNodeView.quantityNode
                        let endNode = endDistanceNodeView.quantityNode
                        
                        startNode.setMin(to: endNode)
                        startNode.setMax(to: endNode)
                    }
                }
                
                self.partialConnection = nil
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
        path.setLineDash([3.0, 3.0], count: 2, phase: 0)
        path.stroke()
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(self.bounds)
        
        if let partialConnection = self.partialConnection {
            var start: CGPoint? = nil
            var end: CGPoint? = nil
            
            if let (nodeView, endPoint) = partialConnection as? (ConstructionNodeView, CGPoint) {
                start = nodeView.node.cgPoint
                end = endPoint
            } else if let (terminalView, endPoint) = partialConnection as? (MetaTerminalView, CGPoint) {
                start = terminalView.center.adding(terminalView.superview!.frame.origin)
                end = endPoint
            } else if let (quantityLabel, endPoint) = partialConnection as? (MetaQuanitityLabel, CGPoint) {
                start = quantityLabel.center.adding(quantityLabel.superview!.frame.origin)
                end = endPoint
            }
            
            if let start = start, let end = end {
                self.drawLine(start: start, end: end, lineWidth: 2.0, color: .systemYellow)
            }
        }

        for node in self.nodeViews.keys {
            guard let distanceNode = node as? MetaDistanceNode else {
                continue
            }
            
            guard let otherDistanceNode = distanceNode.minNode as? MetaDistanceNode else {
                continue
            }
            
            self.drawLine(start: distanceNode.cgPoint, end: otherDistanceNode.cgPoint, lineWidth: 2.0, color: .systemYellow)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
