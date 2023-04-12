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
    static let touchTargetScale = 3.0
    
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
        path.close()
        
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
        for node in model.nodes {
            if self.nodeViews[node] == nil {
                let nodeView = NodeView(modelView: self, node: node)
                self.nodeViews[node] = nodeView
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
    var modelView: ModelView
    var drawingModeLabel: UILabel
    var drawingMode: DrawingMode
    
    var nodeViewBeingMoved: NodeView?
    
    var drawingModeGestureRecognizer: InstantPanGestureRecognizer!
    var moveNodeGestureRecognizer: UIPanGestureRecognizer!
    var createNodeGestureRecognizer: UITapGestureRecognizer!
    
    init() {
        self.model = Model()
        self.drawingModeLabel = UILabel()
        self.drawingMode = .constructNodes
        self.modelView = ModelView(model: self.model, drawingMode: self.drawingMode)

        super.init(frame: CGRect.zero)

        self.isMultipleTouchEnabled = true
        
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
        
        self.moveNodeGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(self.moveNodeGestureRecognizerUpdate))
        self.moveNodeGestureRecognizer.delegate = self
        self.moveNodeGestureRecognizer.minimumNumberOfTouches = 1
        self.moveNodeGestureRecognizer.maximumNumberOfTouches = 1
        self.addGestureRecognizer(self.moveNodeGestureRecognizer)
        
        self.createNodeGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.createNodeGestureRecognizerUpdate))
        self.createNodeGestureRecognizer.delegate = self
        self.createNodeGestureRecognizer.numberOfTapsRequired = 2
        self.addGestureRecognizer(self.createNodeGestureRecognizer)
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
    
    @objc func drawingModeGestureRecognizerUpdate(_ gestureRecognizer : UIPanGestureRecognizer) {
        if gestureRecognizer.state == .began || gestureRecognizer.state == .changed {
            self.updateDrawingMode(DrawingMode.mode(for: gestureRecognizer.numberOfTouches)!)
        }
        
        if gestureRecognizer.state == .ended || gestureRecognizer.state == .cancelled {
            self.updateDrawingMode(DrawingMode.mode(for: 0)!)
        }
    }

    @objc func moveNodeGestureRecognizerUpdate(_ gestureRecognizer : UIPanGestureRecognizer) {
        let location = gestureRecognizer.location(in: self.modelView)

        if gestureRecognizer.state == .began {
            guard let nodeView = self.modelView.hitTest(location, with: nil) as? NodeView else {
                return
            }

            self.nodeViewBeingMoved = nodeView
        }
        
        if gestureRecognizer.state == .changed {
            guard let nodeViewBeingMoved = self.nodeViewBeingMoved else {
                return
            }
            
            nodeViewBeingMoved.node.cgPoint = location
            self.modelView.update()
        }
        
        if gestureRecognizer.state == .ended || gestureRecognizer.state == .cancelled {
            self.nodeViewBeingMoved = nil
        }
    }
    
    @objc func createNodeGestureRecognizerUpdate(_ gestureRecognizer : UIPanGestureRecognizer) {
        if gestureRecognizer.state == .ended {
            let location = gestureRecognizer.location(in: self)
            self.model.createNode(at: location)
            self.modelView.update()
        }
    }
    
    override func layoutSubviews() {
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
