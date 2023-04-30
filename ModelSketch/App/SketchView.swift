//
//  SketchView.swift
//  ModelSketch
//
//  Created by Ben Oztalay on 4/10/23.
//

import SwiftUI
import UIKit

class SketchView: UIView, UIGestureRecognizerDelegate {
 
    var model: Model

    var pencilStrokeView: PencilStrokeView!
    var metaView: MetaView!
    var constructionView: ConstructionView!
    var nodePanGestureRecognizer: UIPanGestureRecognizer!
    
    init() {
        self.model = Model()

        super.init(frame: .zero)

        self.isMultipleTouchEnabled = true
        self.backgroundColor = .white
        
        self.pencilStrokeView = PencilStrokeView()
        self.addSubview(self.pencilStrokeView)
        self.pencilStrokeView.strokeCompletion = self.strokeCompletion
        self.pencilStrokeView.pencilGestureRecognizer.delegate = self
        
        self.metaView = MetaView(graph: self.model.metaGraph)
        self.addSubview(self.metaView)
        self.metaView.isUserInteractionEnabled = false
        
        self.constructionView = ConstructionView(graph: self.model.constructionGraph)
        self.addSubview(self.constructionView)
        self.constructionView.isUserInteractionEnabled = false
        self.constructionView.update()

        self.nodePanGestureRecognizer = NodePanGestureRecognizer(modelView: self.constructionView, target: self, action: #selector(self.nodePanGestureRecognizerUpdate))
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

        let location = gestureRecognizer.location(in: self.constructionView)

        if gestureRecognizer.state == .began {
            if gestureRecognizer.isHardPress {
                self.constructionView.startConnection(from: nodeView, at: location)
            }
        }
        
        if gestureRecognizer.state == .changed {
            if gestureRecognizer.isHardPress {
                self.constructionView.updateConnection(from: nodeView, at: location)
            } else if let translationDelta = gestureRecognizer.translationDelta {
                nodeView.node.cgPoint = nodeView.node.cgPoint.adding(translationDelta)
                self.constructionView.update()
            }
        }
        
        if gestureRecognizer.state == .ended || gestureRecognizer.state == .cancelled {
            if gestureRecognizer.isHardPress {
                self.constructionView.completeConnection(from: nodeView, at: location)
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
                let node = self.model.constructionGraph.createNode()
                node.cgPoint = location
            case .scratch:
                self.handleScratchGesture(stroke)
            default:
                return
        }
        
        self.constructionView.update()
    }
    
    func handleScratchGesture(_ stroke: PencilStroke) {
        guard let points = stroke.walkPath(stride: ConstructionNodeView.radius) else {
            return
        }
        
        for point in points {
            var nodesToDelete = [ConstructionNode]()
            for nodeView in self.constructionView.nodeViews.values {
                if nodeView.containsPoint(point) {
                    nodesToDelete.append(nodeView.node)
                }
            }
            
            for node in nodesToDelete {
                self.model.constructionGraph.remove(node: node)
            }
        }
        
        self.constructionView.update()
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

    func makeUIView(context: Context) -> SketchView {
        return SketchView()
    }
    
    func updateUIView(_ uiView: SketchView, context: Context) {

    }
}
