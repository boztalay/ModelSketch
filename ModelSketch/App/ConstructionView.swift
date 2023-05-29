//
//  ConstructionView.swift
//  ModelSketch
//
//  Created by Ben Oztalay on 4/29/23.
//

import UIKit

class ConstructionNodeView: UIView {
    
    enum HighlightState {
        case normal
        case startOfConnection
        case startOfMetaQuantity
        
        var color: UIColor {
            switch self {
                case .normal:
                    return .darkGray
                case .startOfConnection:
                    return .systemBlue
                case .startOfMetaQuantity:
                    return .systemYellow
            }
        }
    }
    
    static let radius = 7.0
    static let touchTargetScale = 1.5
    static let lineWidth = 3.0

    let node: ConstructionNode
    var highlightState: HighlightState

    init(node: ConstructionNode) {
        self.node = node
        self.highlightState = .normal
        
        super.init(frame: CGRect.zero)
        
        self.backgroundColor = .clear
        self.setHighlightState(self.highlightState)
    }
    
    func setHighlightState(_ highlightState: HighlightState) {
        self.highlightState = highlightState
        self.setNeedsDisplay()
    }
    
    func update(in superview: UIView) {
        let frameRadius = ConstructionNodeView.radius + ConstructionNodeView.lineWidth
        
        self.frame = CGRect(
            origin: CGPoint(
                x: self.node.x - frameRadius,
                y: self.node.y - frameRadius
            ),
            size: CGSize(
                width: frameRadius * 2.0,
                height: frameRadius * 2.0
            )
        )
        
        if self.superview != superview {
            self.removeFromSuperview()
            superview.addSubview(self)
        }
        
        self.superview!.setNeedsDisplay()
        self.setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        let circlePath = UIBezierPath(
            ovalIn: CGRect(
                x: (self.frame.width / 2.0) - ConstructionNodeView.radius,
                y: (self.frame.height / 2.0) - ConstructionNodeView.radius,
                width: 2.0 * ConstructionNodeView.radius,
                height: 2.0 * ConstructionNodeView.radius
            )
        )

        self.highlightState.color.setStroke()
        UIColor.white.setFill()
        circlePath.lineWidth = ConstructionNodeView.lineWidth
        circlePath.fill()
        circlePath.stroke()
    }
    
    func containsPoint(_ point: CGPoint) -> Bool {
        return (point.distance(to: self.node.cgPoint) < (ConstructionNodeView.radius * ConstructionNodeView.touchTargetScale))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class ConstructionView: UIView, Sketchable, NodePanGestureRecognizerDelegate {
    
    let graph: ConstructionGraph
    var nodeViews: [ConstructionNode : ConstructionNodeView]
    var partialConnection: (ConstructionNodeView, CGPoint)?
    var pencilSpring: ConstructionSpring?
    
    init(graph: ConstructionGraph) {
        self.graph = graph
        self.nodeViews = [:]

        super.init(frame: CGRect.zero)
        
        self.backgroundColor = .clear
    }
    
    func getNodeView(at location: CGPoint) -> UIView? {
        for nodeView in self.nodeViews.values {
            if nodeView.containsPoint(location) {
                return nodeView
            }
        }
        
        return nil
    }
    
    func hardPressStatusChanged(_ gestureRecognizer: NodePanGestureRecognizer) {
        guard let nodeView = gestureRecognizer.nodeView as? ConstructionNodeView else {
            return
        }
        
        if gestureRecognizer.isHardPress {
            nodeView.setHighlightState(.startOfConnection)
        } else {
            nodeView.setHighlightState(.normal)
        }
    }
    
    func handleNodePanGestureUpdate(_ gestureRecognizer: NodePanGestureRecognizer) {
        guard let nodeView = gestureRecognizer.nodeView as? ConstructionNodeView else {
            return
        }
        
        let location = gestureRecognizer.location(in: self)

        if gestureRecognizer.state == .began {
            if gestureRecognizer.isHardPress {
                self.partialConnection = (nodeView, location)
            } else {
                if let pencilSpring = self.pencilSpring {
                    pencilSpring.set(pointA: location)
                } else {
                    self.pencilSpring = FollowPencilSpring(node: nodeView.node, location: location)
                    self.graph.add(spring: self.pencilSpring!)
                }
            }
        }
        
        if gestureRecognizer.state == .changed {
            if gestureRecognizer.isHardPress {
                self.partialConnection = (nodeView, location)
            } else {
                self.pencilSpring!.set(pointA: location)
            }
        }
        
        if gestureRecognizer.state == .ended || gestureRecognizer.state == .cancelled {
            if gestureRecognizer.isHardPress {
                if let endNodeView = self.getNodeView(at: location) as? ConstructionNodeView {
                    self.graph.connect(nodeA: nodeView.node, nodeB: endNodeView.node)
                }
                
                nodeView.setHighlightState(.normal)
                
                self.partialConnection = nil
            } else {
                self.graph.remove(spring: self.pencilSpring!)
                self.pencilSpring = nil
            }
        }
    }
    
    func handleCreateGesture(at location: CGPoint) {
        _ = self.graph.createNode(at: location)
    }
    
    func handleScratchGesture(along points: [CGPoint]) {
        var nodesToDelete = [ConstructionNode]()

        for point in points {
            for nodeView in self.nodeViews.values {
                if nodeView.containsPoint(point) && !nodesToDelete.contains(nodeView.node) {
                    nodesToDelete.append(nodeView.node)
                }
            }
        }
        
        for node in nodesToDelete {
            self.graph.remove(node: node)
        }
    }

    func update() {
        for node in self.graph.nodes {
            if self.nodeViews[node] == nil {
                let nodeView = ConstructionNodeView(node: node)
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
        
        if let (nodeView, endPoint) = self.partialConnection {
            let startPoint = nodeView.node.cgPoint
            self.drawLine(start: startPoint, end: endPoint, lineWidth: 3.0, color: .lightGray)
        }
        
        for connection in self.graph.connections {
            let startPoint = connection.nodeA.cgPoint
            let endPoint = connection.nodeB.cgPoint
            self.drawLine(start: startPoint, end: endPoint, lineWidth: 3.0, color: .darkGray)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
