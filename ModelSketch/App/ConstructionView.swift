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
        
        var color: UIColor {
            switch self {
                case .normal:
                    return UIColor.darkGray
                case .startOfConnection:
                    return UIColor.systemBlue
            }
        }
    }
    
    static let radius = 7.0
    static let touchTargetScale = 1.5

    let node: ConstructionNode
    var highlightState: HighlightState
    
    init(node: ConstructionNode) {
        self.node = node
        self.highlightState = .normal
        
        super.init(frame: CGRect.zero)
        
        self.backgroundColor = .white
        self.setHighlightState(self.highlightState)
    }
    
    func setHighlightState(_ highlightState: HighlightState) {
        self.highlightState = highlightState
        self.layer.borderColor = self.highlightState.color.cgColor
    }
    
    func update(in superview: UIView) {
        self.frame = CGRect(
            origin: CGPoint(
                x: self.node.x - ConstructionNodeView.radius,
                y: self.node.y - ConstructionNodeView.radius
            ),
            size: CGSize(
                width: ConstructionNodeView.radius * 2.0,
                height: ConstructionNodeView.radius * 2.0
            )
        )
        
        self.layer.cornerRadius = ConstructionNodeView.radius
        self.layer.borderColor = self.highlightState.color.cgColor
        self.layer.borderWidth = 3.0
        
        if self.superview != superview {
            self.removeFromSuperview()
            superview.addSubview(self)
        }
        
        self.superview!.setNeedsDisplay()
    }
    
    func containsPoint(_ point: CGPoint) -> Bool {
        return (point.distance(to: self.node.cgPoint) < (ConstructionNodeView.radius * ConstructionNodeView.touchTargetScale))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class ConstructionView: UIView {
    
    let graph: ConstructionGraph
    var nodeViews: [ConstructionNode : ConstructionNodeView]
    var partialConnections: [ConstructionNodeView : CGPoint]
    
    init(graph: ConstructionGraph) {
        self.graph = graph
        self.nodeViews = [:]
        self.partialConnections = [:]

        super.init(frame: CGRect.zero)
        
        self.backgroundColor = .clear
    }
    
    func getNodeView(at point: CGPoint) -> ConstructionNodeView? {
        for nodeView in self.nodeViews.values {
            if nodeView.containsPoint(point) {
                return nodeView
            }
        }
        
        return nil
    }
    
    func startConnection(from nodeView: ConstructionNodeView, at location: CGPoint) {
        self.partialConnections[nodeView] = location
        self.setNeedsDisplay()
    }
    
    func updateConnection(from nodeView: ConstructionNodeView, at location: CGPoint) {
        self.partialConnections[nodeView] = location
        self.setNeedsDisplay()
    }
    
    func completeConnection(from nodeView: ConstructionNodeView, at location: CGPoint) {
        if let endNodeView = self.getNodeView(at: location) {
            self.graph.connect(nodeA: nodeView.node, nodeB: endNodeView.node)
        }
        
        self.partialConnections.removeValue(forKey: nodeView)
        self.update()
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
        
        for (nodeView, endPoint) in self.partialConnections {
            let startPoint = nodeView.node.cgPoint
            self.drawLine(start: startPoint, end: endPoint, lineWidth: 3.0, color: .lightGray)
        }
        
        for connection in self.graph.connections {
            let startPoint = connection.nodeA.cgPoint
            let endPoint = connection.nodeB.cgPoint
            self.drawLine(start: startPoint, end: endPoint, lineWidth: 3.0, color: .darkGray)
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
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
