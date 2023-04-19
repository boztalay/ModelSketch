//
//  GestureView.swift
//  ModelSketch
//
//  Created by Ben Oztalay on 4/18/23.
//

import SwiftUI
import UIKit

class GestureView: UIView {
    
    static let nodeViewSpacing = 25.0
    
    var pencilStrokeView: PencilStrokeView!
    var nodeViews: [NodeView]!
    
    init() {
        super.init(frame: .zero)
        
        self.pencilStrokeView = PencilStrokeView()
        self.pencilStrokeView.animates = false
        self.addSubview(self.pencilStrokeView)
        
        self.nodeViews = [
            NodeView(node: Node(x: 0.0, y: 0.0)),
            NodeView(node: Node(x: 0.0, y: 0.0)),
            NodeView(node: Node(x: 0.0, y: 0.0)),
            NodeView(node: Node(x: 0.0, y: 0.0))
        ]
        
        for nodeView in self.nodeViews {
            nodeView.isUserInteractionEnabled = false
            self.addSubview(nodeView)
        }
    }
    
    override func layoutSubviews() {
        self.pencilStrokeView.frame = self.bounds
        
        self.nodeViews[0].node.x = self.center.x + GestureView.nodeViewSpacing
        self.nodeViews[0].node.y = self.center.y + GestureView.nodeViewSpacing
        
        self.nodeViews[1].node.x = self.center.x - GestureView.nodeViewSpacing
        self.nodeViews[1].node.y = self.center.y + GestureView.nodeViewSpacing
        
        self.nodeViews[2].node.x = self.center.x + GestureView.nodeViewSpacing
        self.nodeViews[2].node.y = self.center.y - GestureView.nodeViewSpacing
        
        self.nodeViews[3].node.x = self.center.x - GestureView.nodeViewSpacing
        self.nodeViews[3].node.y = self.center.y - GestureView.nodeViewSpacing
        
        for nodeView in self.nodeViews {
            nodeView.update(in: self)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct RepresentedGestureView: UIViewRepresentable {
    typealias UIViewType = GestureView
    
    @State var strokeCompletion: (PencilStroke) -> ()

    func makeUIView(context: Context) -> GestureView {
        let view = GestureView()
        view.pencilStrokeView.strokeCompletion = self.strokeCompletion
        return view
    }
    
    func updateUIView(_ uiView: GestureView, context: Context) {

    }
}
