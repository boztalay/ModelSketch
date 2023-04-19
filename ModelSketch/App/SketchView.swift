//
//  SketchView.swift
//  ModelSketch
//
//  Created by Ben Oztalay on 4/10/23.
//

import SwiftUI
import UIKit

enum DrawingMode: String, CaseIterable {
    case constructNodes = "Construct Nodes"
    case connectNodes = "Connect Nodes"
    
    static let minTouchCount = 2
    static let maxTouchCount = DrawingMode.minTouchCount + DrawingMode.allCases.count - 2
    
    static func mode(for touchCount: Int) -> DrawingMode? {
        switch touchCount {
            case DrawingMode.minTouchCount:
                return .connectNodes
            default:
                return .constructNodes
        }
    }
}

class NodeView: UIView {
    
    static let radius = 7.0
    static let touchTargetScale = 1.5
    
    let modelView: ModelView
    let node: Node
    
    init(modelView: ModelView, node: Node) {
        self.modelView = modelView
        self.node = node
        
        super.init(frame: CGRect.zero)
        
        self.backgroundColor = .white
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
        self.layer.borderColor = UIColor.darkGray.cgColor
        self.layer.borderWidth = 3.0
        
        if self.superview != superview {
            self.removeFromSuperview()
            superview.addSubview(self)
        }
        
        self.superview!.setNeedsDisplay()
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let extraSpace = NodeView.radius * (NodeView.touchTargetScale - 1.0)
        return bounds.insetBy(dx: -extraSpace, dy: -extraSpace).contains(point)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class ModelView: UIView {
    
    let model: Model
    var drawingMode: DrawingMode
    var nodeViews: [Node : NodeView]
    var partialConnections: [NodeView : CGPoint]
    
    init(model: Model, drawingMode: DrawingMode) {
        self.model = model
        self.drawingMode = drawingMode
        self.nodeViews = [:]
        self.partialConnections = [:]

        super.init(frame: CGRect.zero)
        
        self.backgroundColor = .clear
    }
    
    func setDrawingMode(_ drawingMode: DrawingMode) {
        self.drawingMode = drawingMode
        
        if self.drawingMode != .connectNodes {
            self.partialConnections = [:]
        }
        
        self.setNeedsDisplay()
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
        if let endNodeView = self.hitTest(location, with: nil) as? NodeView {
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
                let nodeView = NodeView(modelView: self, node: node)
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
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class SketchView: UIView, UIGestureRecognizerDelegate {
 
    var model: Model

    var pencilStrokeView: PencilStrokeView
    var modelView: ModelView
    var drawingModeLabel: UILabel

    var drawingMode: DrawingMode
    var nodeViewBeingPanned: NodeView?
    
    var drawingModeGestureRecognizer: InstantPanGestureRecognizer!
    var nodePanGestureRecognizer: UIPanGestureRecognizer!
    
    init() {
        self.model = Model()
        self.pencilStrokeView = PencilStrokeView()
        self.drawingModeLabel = UILabel()
        self.drawingMode = .constructNodes
        self.modelView = ModelView(model: self.model, drawingMode: self.drawingMode)

        super.init(frame: .zero)

        self.isMultipleTouchEnabled = true
        self.backgroundColor = .white
        
        self.addSubview(self.pencilStrokeView)
        self.pencilStrokeView.pencilGestureRecognizer.delegate = self
        
        self.addSubview(self.modelView)
        self.modelView.update()
        
        self.addSubview(self.drawingModeLabel)
        self.drawingModeLabel.text = self.drawingMode.rawValue
        self.drawingModeLabel.textAlignment = .center
        
        self.drawingModeGestureRecognizer = InstantPanGestureRecognizer(target: self, action: #selector(self.drawingModeGestureRecognizerUpdate))
        self.drawingModeGestureRecognizer.delegate = self
        self.drawingModeGestureRecognizer.minimumNumberOfTouches = DrawingMode.minTouchCount
        self.drawingModeGestureRecognizer.maximumNumberOfTouches = DrawingMode.maxTouchCount
        self.addGestureRecognizer(self.drawingModeGestureRecognizer)
        
        self.nodePanGestureRecognizer = InstantPanGestureRecognizer(target: self, action: #selector(self.nodePanGestureRecognizerUpdate))
        self.nodePanGestureRecognizer.delegate = self
        self.nodePanGestureRecognizer.minimumNumberOfTouches = 1
        self.nodePanGestureRecognizer.maximumNumberOfTouches = 1
        self.addGestureRecognizer(self.nodePanGestureRecognizer)
    }
    
    func updateDrawingMode(_ drawingMode: DrawingMode) {
        guard self.drawingMode != drawingMode else {
            return
        }
        
        self.drawingMode = drawingMode
        self.drawingModeLabel.text = self.drawingMode.rawValue
        
        self.modelView.setDrawingMode(self.drawingMode)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    @objc func drawingModeGestureRecognizerUpdate(_ gestureRecognizer : InstantPanGestureRecognizer) {
        if gestureRecognizer.state == .began || gestureRecognizer.state == .changed {
            self.updateDrawingMode(DrawingMode.mode(for: gestureRecognizer.numberOfTouches)!)
        }
        
        if gestureRecognizer.state == .ended || gestureRecognizer.state == .cancelled {
            self.updateDrawingMode(DrawingMode.mode(for: 0)!)
        }
    }

    @objc func nodePanGestureRecognizerUpdate(_ gestureRecognizer : UIPanGestureRecognizer) {
        let location = gestureRecognizer.location(in: self.modelView)

        if gestureRecognizer.state == .began {
            guard let nodeView = self.modelView.hitTest(location, with: nil) as? NodeView else {
                gestureRecognizer.isEnabled = false
                gestureRecognizer.isEnabled = true
                return
            }

            self.nodeViewBeingPanned = nodeView
            
            if self.drawingMode == .connectNodes {
                self.modelView.startConnection(from: nodeView, at: location)
            }
        }
        
        if gestureRecognizer.state == .changed {
            guard let nodeViewBeingPanned = self.nodeViewBeingPanned else {
                return
            }
            
            if self.drawingMode == .constructNodes {
                nodeViewBeingPanned.node.cgPoint = location
                self.modelView.update()
            } else if self.drawingMode == .connectNodes {
                self.modelView.updateConnection(from: nodeViewBeingPanned, at: location)
            }
        }
        
        if gestureRecognizer.state == .ended || gestureRecognizer.state == .cancelled {
            guard let nodeViewBeingPanned = self.nodeViewBeingPanned else {
                return
            }
            
            if self.drawingMode == .connectNodes {
                self.modelView.completeConnection(from: nodeViewBeingPanned, at: location)
            }
            
            self.nodeViewBeingPanned = nil
        }
    }
    
    /*
    @objc func createNodeGestureRecognizerUpdate(_ gestureRecognizer : PencilCircleGestureRecognizer) {
        if gestureRecognizer.state == .ended {
            if let circleCenter = gestureRecognizer.circleCenter {
                self.model.createNode(at: circleCenter)
                self.modelView.update()
            }
        }
    }
    
    @objc func deleteGestureRecognizerUpdate(_ gestureRecognizer : PencilDeleteGestureRecognizer) {
        if gestureRecognizer.state == .ended {
            if let intersection = gestureRecognizer.intersection {
                if let nodeView = self.modelView.hitTest(intersection, with: nil) as? NodeView {
                    self.model.deleteNode(nodeView.node)
                    self.modelView.update()
                }
            }
        }
    }
     */
    
    override func layoutSubviews() {
        self.pencilStrokeView.frame = self.bounds
        self.modelView.frame = self.bounds
        self.drawingModeLabel.frame = CGRect(origin: CGPoint.zero, size: CGSize(width: 200.0, height: 50.0))
        self.drawingModeLabel.center = CGPoint(
            x: self.center.x,
            y: self.frame.height - (self.drawingModeLabel.frame.height / 2.0)
        )
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
