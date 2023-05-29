//
//  SketchView.swift
//  ModelSketch
//
//  Created by Ben Oztalay on 4/10/23.
//

import SwiftUI
import UIKit

protocol Sketchable {
    func handleNodePanGestureUpdate(_ gestureRecognizer: NodePanGestureRecognizer)
    func handleCreateGesture(at location: CGPoint)
    func handleScratchGesture(along points: [CGPoint])
}

class SketchView: UIView, UIGestureRecognizerDelegate {
    
    enum DrawingMode: CaseIterable, Identifiable {
        var id: Self { self }

        case construction
        case meta
        
        var friendlyName: String {
            switch (self) {
                case .construction:
                    return "Construction"
                case .meta:
                    return "Meta"
            }
        }
    }
 
    let model: Model

    var pencilStrokeView: PencilStrokeView!
    var metaView: MetaView!
    var constructionView: ConstructionView!
    var nodePanGestureRecognizer: NodePanGestureRecognizer!
    var displayLink: CADisplayLink?
    
    var drawingMode: DrawingMode
    
    init() {
        self.model = Model()
        self.drawingMode = .construction

        super.init(frame: .zero)

        self.isMultipleTouchEnabled = true
        self.backgroundColor = .white
        
        self.pencilStrokeView = PencilStrokeView()
        self.addSubview(self.pencilStrokeView)
        self.pencilStrokeView.strokeCompletion = self.strokeCompletion
        self.pencilStrokeView.pencilGestureRecognizer.delegate = self
        
        self.constructionView = ConstructionView(graph: self.model.constructionGraph)
        self.metaView = MetaView(graph: self.model.metaGraph, constructionView: self.constructionView)
        self.addSubview(self.metaView)
        self.metaView.isUserInteractionEnabled = false

        self.addSubview(self.constructionView)
        self.constructionView.isUserInteractionEnabled = false

        self.nodePanGestureRecognizer = NodePanGestureRecognizer(target: self, action: #selector(self.nodePanGestureRecognizerUpdate))
        self.nodePanGestureRecognizer.delegate = self
        self.addGestureRecognizer(self.nodePanGestureRecognizer)
        
        self.setDrawingMode(drawingMode: .construction)
        self.metaView.update()
        self.constructionView.update()
    }
    
    func setDrawingMode(drawingMode: DrawingMode) {
        self.drawingMode = drawingMode

        switch self.drawingMode {
            case .construction:
                self.nodePanGestureRecognizer.nodeDelegate = self.constructionView
            case .meta:
                self.nodePanGestureRecognizer.nodeDelegate = self.metaView
        }
    }
    
    func start() {
        self.displayLink = CADisplayLink(target: self, selector: #selector(update))
        self.displayLink!.add(to: .current, forMode: .common)
    }
    
    func stop() {
        if let displayLink = self.displayLink {
            displayLink.invalidate()
            displayLink.remove(from: .current, forMode: .common)
        }

        self.displayLink = nil
    }
    
    @objc func update() {
        guard let displayLink = self.displayLink else {
            return
        }
        
        let dt = displayLink.targetTimestamp - displayLink.timestamp

        self.model.update(dt: dt)
        self.constructionView.update()
        self.metaView.update()
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
        switch self.drawingMode {
            case .construction:
                self.constructionView.handleNodePanGestureUpdate(gestureRecognizer)
            case .meta:
                self.metaView.handleNodePanGestureUpdate(gestureRecognizer)
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
                self.handleCreateGesture(at: location)
            case .scratch:
                self.handleScratchGesture(stroke)
            default:
                return
        }
    }
    
    func handleCreateGesture(at location: CGPoint) {
        switch self.drawingMode {
            case .construction:
                self.constructionView.handleCreateGesture(at: location)
            case .meta:
                self.metaView.handleCreateGesture(at: location)
        }
    }
    
    func handleScratchGesture(_ stroke: PencilStroke) {
        guard let points = stroke.walkPath(stride: ConstructionNodeView.radius) else {
            return
        }

        switch self.drawingMode {
            case .construction:
                self.constructionView.handleScratchGesture(along: points)
            case .meta:
                self.metaView.handleScratchGesture(along: points)
        }
    }

    override func layoutSubviews() {
        self.pencilStrokeView.frame = self.bounds
        self.metaView.frame = self.bounds
        self.constructionView.frame = self.bounds
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct RepresentedSketchView: UIViewRepresentable {
    typealias UIViewType = SketchView
    
    @Binding var drawingMode: SketchView.DrawingMode
    @Binding var isVisible: Bool

    func makeUIView(context: Context) -> SketchView {
        return SketchView()
    }

    func updateUIView(_ uiView: SketchView, context: Context) {
        uiView.setDrawingMode(drawingMode: self.drawingMode)
        
        if self.isVisible {
            uiView.start()
        } else {
            uiView.stop()
        }
    }
}
