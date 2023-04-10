//
//  SketchView.swift
//  ModelSketch
//
//  Created by Ben Oztalay on 4/10/23.
//

import SwiftUI
import UIKit

class Node: Hashable {
    
    static var nextId = 0

    let id: Int
    var x: CGFloat
    var y: CGFloat
    
    init(x: CGFloat, y: CGFloat) {
        self.id = Node.nextId
        self.x = x
        self.y = y
        
        Node.nextId += 1
    }
    
    static func == (lhs: Node, rhs: Node) -> Bool {
        return (lhs.id == rhs.id)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
}

class Connection: Equatable {
    
    let nodeA: Node
    let nodeB: Node
    
    init(nodeA: Node, nodeB: Node) {
        self.nodeA = nodeA
        self.nodeB = nodeB
    }
    
    static func == (lhs: Connection, rhs: Connection) -> Bool {
        return ((lhs.nodeA == rhs.nodeA) && (lhs.nodeB == rhs.nodeB)) || ((lhs.nodeA == rhs.nodeB) && (lhs.nodeB == rhs.nodeA))
    }
}

class Model {

    private(set) var nodes: [Node]
    private(set) var connections: [Connection]
    
    init() {
        self.nodes = []
        self.connections = []
    }
    
    func createNode(at x: CGFloat, _ y: CGFloat) {
        self.nodes.append(Node(x: x, y: y))
    }
    
    func addConnection(between nodeA: Node, _ nodeB: Node) {
        let connection = Connection(nodeA: nodeA, nodeB: nodeB)
        guard !self.connections.contains(connection) else {
            return
        }
        
        self.connections.append(connection)
    }
}

class ModelView: UIView {
    
    let model: Model
    var drawingMode: DrawingMode
    var nodeViews: [Node : NodeView]
    var partialConnections: [NodeView : CGPoint]
    var gestureRecognizerDelegate: UIGestureRecognizerDelegate!
    
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
        for nodeView in self.nodeViews.values {
            nodeView.setDrawingMode(self.drawingMode)
        }
        
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
            self.model.addConnection(between: nodeView.node, endNodeView.node)
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
            let startPoint = CGPoint(x: nodeView.node.x, y: nodeView.node.y)
            self.drawLine(start: startPoint, end: endPoint, lineWidth: 3.0, color: .lightGray)
        }
        
        for connection in self.model.connections {
            let startPoint = CGPoint(x: connection.nodeA.x, y: connection.nodeA.y)
            let endPoint = CGPoint(x: connection.nodeB.x, y: connection.nodeB.y)
            self.drawLine(start: startPoint, end: endPoint, lineWidth: 3.0, color: .darkGray)
        }
    }
    
    func update() {
        for node in model.nodes {
            if self.nodeViews[node] == nil {
                let nodeView = NodeView(modelView: self, node: node, drawingMode: self.drawingMode, gestureRecognizerDelegate: self.gestureRecognizerDelegate)
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

class NodeView: UIView {
    
    static let radius = 7.0
    static let touchTargetScale = 2.0
    
    let modelView: ModelView
    let node: Node
    var drawingMode: DrawingMode
    var panGestureRecognizer: UIPanGestureRecognizer!
    
    init(modelView: ModelView, node: Node, drawingMode: DrawingMode, gestureRecognizerDelegate: UIGestureRecognizerDelegate) {
        self.modelView = modelView
        self.node = node
        self.drawingMode = drawingMode
        
        super.init(frame: CGRect.zero)
        
        self.backgroundColor = .white
        
        self.panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(self.panGestureRecognizerUpdate))
        self.panGestureRecognizer.delegate = gestureRecognizerDelegate
        self.panGestureRecognizer.minimumNumberOfTouches = 1
        self.panGestureRecognizer.maximumNumberOfTouches = 1
        self.addGestureRecognizer(self.panGestureRecognizer)
    }
    
    func setDrawingMode(_ drawingMode: DrawingMode) {
        self.drawingMode = drawingMode
        self.panGestureRecognizer.isEnabled = false
        self.panGestureRecognizer.isEnabled = true
    }
    
    @objc func panGestureRecognizerUpdate(_ gestureRecognizer : UIPanGestureRecognizer) {
        let location = gestureRecognizer.location(in: self.modelView)
        
        if gestureRecognizer.state == .began {
            if self.drawingMode == .connectNodes {
                self.modelView.startConnection(from: self, at: location)
            }
        } else if gestureRecognizer.state == .changed {
            if self.drawingMode == .connectNodes {
                self.modelView.updateConnection(from: self, at: location)
            } else if self.drawingMode == .constructNodes {
                let location = gestureRecognizer.location(in: superview)
                self.node.x = location.x
                self.node.y = location.y
                self.update(in: self.modelView)
            }
        } else {
            if self.drawingMode == .connectNodes {
                self.modelView.completeConnection(from: self, at: location)
            }
        }
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

enum DrawingMode: String, CaseIterable {
    case constructNodes = "Construct Nodes"
    case connectNodes = "Connect Nodes"
    
    static let maxTouchCount = DrawingMode.allCases.count - 1
    
    static func mode(for touchCount: Int) -> DrawingMode? {
        switch touchCount {
            case 0:
                return .constructNodes
            case 1:
                return .connectNodes
            default:
                return nil
        }
    }
}

class DrawingModeGestureRecognizer: UIGestureRecognizer, UIGestureRecognizerDelegate {
    
    var mode: DrawingMode = .constructNodes
    var trackedTouches: Set<UITouch> = []
    
    override init(target: Any?, action: Selector?) {
        super.init(target: target, action: action)
        self.delegate = self
        self.allowedTouchTypes = [NSNumber(integerLiteral: UITouch.TouchType.direct.rawValue)]
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard !self.trackedTouches.contains(touch) else {
            return true
        }

        guard self.trackedTouches.count < DrawingMode.maxTouchCount else {
            return false
        }

        return true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        var newTouches = self.trackedTouches.union(touches).subtracting(self.trackedTouches)
        while !newTouches.isEmpty && (self.trackedTouches.count < DrawingMode.maxTouchCount) {
            self.trackedTouches.insert(newTouches.popFirst()!)
        }
        
        guard self.trackedTouches.count > 0 else {
            if self.state == .possible {
                self.state = .failed
            } else {
                self.state = .cancelled
            }

            return
        }
        
        self.updateMode()
        
        if self.state == .possible {
            self.state = .began
        } else {
            self.state = .changed
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        let touchesToIgnore = touches.subtracting(self.trackedTouches)
        for touch in touchesToIgnore {
            self.ignore(touch, for: event)
        }
        
        self.trackedTouches.subtract(touches)
        
        if self.trackedTouches.count > 0 {
            self.state = .changed
        } else {
            self.state = .failed
        }
        
        self.updateMode()
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesCancelled(touches, with: event)
        self.trackedTouches.subtract(touches)
        
        if self.trackedTouches.count > 0 {
            self.state = .changed
        } else {
            self.state = .failed
        }
        
        self.updateMode()
    }
    
    override func reset() {
        super.reset()
        self.trackedTouches = []
        self.updateMode()
    }
    
    func updateMode() {
        guard let mode = DrawingMode.mode(for: self.trackedTouches.count) else {
            self.mode = .constructNodes
            return
        }
        
        self.mode = mode
    }
}

class SketchView: UIView, UIGestureRecognizerDelegate {
 
    var model: Model
    var modelView: ModelView
    var modeLabel: UILabel
    
    var drawingMode: DrawingMode
    var drawingModeGestureRecognizer: DrawingModeGestureRecognizer!
    var doubleTapGestureRecognizer: UITapGestureRecognizer!
    
    init() {
        self.model = Model()
        self.modeLabel = UILabel()
        self.drawingMode = .constructNodes
        self.modelView = ModelView(model: self.model, drawingMode: self.drawingMode)

        super.init(frame: CGRect.zero)

        self.isMultipleTouchEnabled = true
        
        self.addSubview(self.modelView)
        self.modelView.gestureRecognizerDelegate = self
        self.modelView.update()
        
        self.addSubview(self.modeLabel)
        self.modeLabel.text = self.drawingMode.rawValue
        self.modeLabel.textAlignment = .center
        
        self.drawingModeGestureRecognizer = DrawingModeGestureRecognizer(target: self, action: #selector(self.drawingModeGestureRecognizerUpdate))
        self.addGestureRecognizer(self.drawingModeGestureRecognizer)
        
        self.doubleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.doubleTapGestureRecognizerUpdate))
        self.doubleTapGestureRecognizer.delegate = self
        self.doubleTapGestureRecognizer.numberOfTapsRequired = 2
        self.doubleTapGestureRecognizer.allowedTouchTypes = [NSNumber(integerLiteral: UITouch.TouchType.pencil.rawValue)]
        self.addGestureRecognizer(self.doubleTapGestureRecognizer)
    }
    
    @objc func doubleTapGestureRecognizerUpdate(_ gestureRecognizer : UIPanGestureRecognizer) {
        if gestureRecognizer.state == .ended {
            let location = gestureRecognizer.location(in: self)
            self.model.createNode(at: location.x, location.y)
            self.modelView.update()
        }
    }
    
    @objc func drawingModeGestureRecognizerUpdate(_ gestureRecognizer : DrawingModeGestureRecognizer) {
        self.drawingMode = gestureRecognizer.mode
        self.modeLabel.text = self.drawingMode.rawValue
        
        switch (self.drawingMode) {
            case .constructNodes:
                self.doubleTapGestureRecognizer.isEnabled = true
            case .connectNodes:
                self.doubleTapGestureRecognizer.isEnabled = false
        }
        
        self.modelView.setDrawingMode(self.drawingMode)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    override func layoutSubviews() {
        self.modelView.frame = self.bounds
        self.modeLabel.frame = CGRect(origin: CGPoint.zero, size: CGSize(width: 200.0, height: 50.0))
        self.modeLabel.center = CGPoint(
            x: self.center.x,
            y: self.frame.height - (self.modeLabel.frame.height / 2.0)
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
