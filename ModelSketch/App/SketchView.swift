//
//  SketchView.swift
//  ModelSketch
//
//  Created by Ben Oztalay on 4/10/23.
//

import SwiftUI
import UIKit

enum NodeViewHighlightState {
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

class NodeView: UIView {
    
    static let radius = 7.0
    static let touchTargetScale = 1.5

    let node: Node
    var highlightState: NodeViewHighlightState
    
    init(node: Node) {
        self.node = node
        self.highlightState = .normal
        
        super.init(frame: CGRect.zero)
        
        self.backgroundColor = .white
        self.setHighlightState(self.highlightState)
    }
    
    func setHighlightState(_ highlightState: NodeViewHighlightState) {
        self.highlightState = highlightState
        self.layer.borderColor = self.highlightState.color.cgColor
    }
    
    func update(in superview: UIView) {
        self.frame = CGRect(
            origin: CGPoint(
                x: self.node.x - NodeView.radius,
                y: self.node.y - NodeView.radius
            ),
            size: CGSize(
                width: NodeView.radius * 2.0,
                height: NodeView.radius * 2.0
            )
        )
        
        self.layer.cornerRadius = NodeView.radius
        self.layer.borderColor = self.highlightState.color.cgColor
        self.layer.borderWidth = 3.0
        
        if self.superview != superview {
            self.removeFromSuperview()
            superview.addSubview(self)
        }
        
        self.superview!.setNeedsDisplay()
    }
    
    func containsPoint(_ point: CGPoint) -> Bool {
        return (point.distance(to: self.node.cgPoint) < (NodeView.radius * NodeView.touchTargetScale))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class ModelView: UIView {
    
    let model: Model
    var nodeViews: [Node : NodeView]
    var partialConnections: [NodeView : CGPoint]
    
    init(model: Model) {
        self.model = model
        self.nodeViews = [:]
        self.partialConnections = [:]

        super.init(frame: CGRect.zero)
        
        self.backgroundColor = .clear
    }
    
    func getNodeView(at point: CGPoint) -> NodeView? {
        for nodeView in self.nodeViews.values {
            if nodeView.containsPoint(point) {
                return nodeView
            }
        }
        
        return nil
    }
    
    func startConnection(from nodeView: NodeView, at location: CGPoint) {
        self.partialConnections[nodeView] = location
        self.setNeedsDisplay()
    }
    
    func updateConnection(from nodeView: NodeView, at location: CGPoint) {
        self.partialConnections[nodeView] = location
        self.setNeedsDisplay()
    }
    
    func completeConnection(from nodeView: NodeView, at location: CGPoint) {
        if let endNodeView = self.getNodeView(at: location) {
            self.model.connect(between: nodeView.node, endNodeView.node)
        }
        
        self.partialConnections.removeValue(forKey: nodeView)
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
        
        for (nodeView, endPoint) in self.partialConnections {
            let startPoint = nodeView.node.cgPoint
            self.drawLine(start: startPoint, end: endPoint, lineWidth: 3.0, color: .lightGray)
        }
        
        for connection in self.model.connections {
            let startPoint = connection.nodeA.cgPoint
            let endPoint = connection.nodeB.cgPoint
            self.drawLine(start: startPoint, end: endPoint, lineWidth: 3.0, color: .darkGray)
        }
    }
    
    func update() {
        for node in self.model.nodes {
            if self.nodeViews[node] == nil {
                let nodeView = NodeView(node: node)
                self.nodeViews[node] = nodeView
            }
        }

        for node in self.nodeViews.keys {
            if !self.model.nodes.contains(node) {
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

class SketchView: UIView, UIGestureRecognizerDelegate {
 
    var model: Model

    var pencilStrokeView: PencilStrokeView
    var modelView: ModelView
    var nodePanGestureRecognizer: UIPanGestureRecognizer!
    
    init() {
        self.model = Model()
        self.pencilStrokeView = PencilStrokeView()
        self.modelView = ModelView(model: self.model)

        super.init(frame: .zero)

        self.isMultipleTouchEnabled = true
        self.backgroundColor = .white
        
        self.addSubview(self.pencilStrokeView)
        self.pencilStrokeView.strokeCompletion = self.strokeCompletion
        self.pencilStrokeView.pencilGestureRecognizer.delegate = self
        
        self.addSubview(self.modelView)
        self.modelView.isUserInteractionEnabled = false
        self.modelView.update()

        self.nodePanGestureRecognizer = NodePanGestureRecognizer(modelView: self.modelView, target: self, action: #selector(self.nodePanGestureRecognizerUpdate))
        self.nodePanGestureRecognizer.delegate = self
        self.addGestureRecognizer(self.nodePanGestureRecognizer)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == self.pencilStrokeView.pencilGestureRecognizer && otherGestureRecognizer == self.nodePanGestureRecognizer {
            return true
        }
        
        return false
    }

    @objc func nodePanGestureRecognizerUpdate(_ gestureRecognizer : NodePanGestureRecognizer) {
        guard let nodeView = gestureRecognizer.nodeView else {
            return
        }

        let location = gestureRecognizer.location(in: self.modelView)

        if gestureRecognizer.state == .began {
            if gestureRecognizer.isHardPress {
                self.modelView.startConnection(from: nodeView, at: location)
            }
        }
        
        if gestureRecognizer.state == .changed {
            if gestureRecognizer.isHardPress {
                self.modelView.updateConnection(from: nodeView, at: location)
            } else {
                nodeView.node.cgPoint = location
                self.modelView.update()
            }
        }
        
        if gestureRecognizer.state == .ended || gestureRecognizer.state == .cancelled {
            if gestureRecognizer.isHardPress {
                self.modelView.completeConnection(from: nodeView, at: location)
            }
        }
    }
    
    func strokeCompletion(_ stroke: PencilStroke) {
        guard let gesture = stroke.gesture else {
            return
        }
        
        let location = stroke.pathFrame!.center
        print("\(gesture) at \(location)")
        
        switch gesture {
            case .create:
                self.model.createNode(at: location)
            case .scratch:
                self.handleScratchGesture(stroke)
            default:
                return
        }
        
        self.modelView.update()
    }
    
    func handleScratchGesture(_ stroke: PencilStroke) {
        guard let points = stroke.walkPath(stride: NodeView.radius) else {
            return
        }
        
        for point in points {
            var nodesToDelete = [Node]()
            for nodeView in self.modelView.nodeViews.values {
                if nodeView.containsPoint(point) {
                    nodesToDelete.append(nodeView.node)
                }
            }
            
            for node in nodesToDelete {
                self.model.deleteNode(node)
            }
        }
    }

    override func layoutSubviews() {
        self.pencilStrokeView.frame = self.bounds
        self.modelView.frame = self.bounds
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct RepresentedSketchView: UIViewRepresentable {
    typealias UIViewType = SketchView

    func makeUIView(context: Context) -> SketchView {
        return SketchView()
    }
    
    func updateUIView(_ uiView: SketchView, context: Context) {

    }
}
