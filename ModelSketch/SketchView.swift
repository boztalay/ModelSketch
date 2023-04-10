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

class Model {

    private(set) var nodes: [Node]
    
    init() {
        self.nodes = []
    }
    
    func createNode(at x: CGFloat, _ y: CGFloat) {
        self.nodes.append(Node(x: x, y: y))
    }
}


class ModelView: UIView {
    
    let model: Model
    var gestureRecognizerDelegate: UIGestureRecognizerDelegate!
    var nodeViews: [Node : NodeView]
    
    init(model: Model) {
        self.model = model
        self.nodeViews = [:]

        super.init(frame: CGRect.zero)
    }
    
    func update() {
        for node in model.nodes {
            if self.nodeViews[node] == nil {
                let nodeView = NodeView(node: node, gestureRecognizerDelegate: self.gestureRecognizerDelegate)
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
    
    let node: Node
    
    init(node: Node, gestureRecognizerDelegate: UIGestureRecognizerDelegate) {
        self.node = node
        
        super.init(frame: CGRect.zero)
        
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(self.panGestureRecognizerUpdate))
        panGestureRecognizer.delegate = gestureRecognizerDelegate
        panGestureRecognizer.minimumNumberOfTouches = 1
        panGestureRecognizer.maximumNumberOfTouches = 1
        self.addGestureRecognizer(panGestureRecognizer)
    }
    
    @objc func panGestureRecognizerUpdate(_ gestureRecognizer : UIPanGestureRecognizer) {
        guard let superview = self.superview else {
            return
        }
        
        if gestureRecognizer.state == .changed {
            let location = gestureRecognizer.location(in: superview)
            self.node.x = location.x
            self.node.y = location.y
            self.update(in: superview)
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
        self.layer.borderColor = .init(gray: 0.25, alpha: 1.0)
        self.layer.borderWidth = 3.0
        
        if self.superview != superview {
            self.removeFromSuperview()
            superview.addSubview(self)
        }
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
        self.modelView = ModelView(model: self.model)
        self.modeLabel = UILabel()
        self.drawingMode = .constructNodes

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
