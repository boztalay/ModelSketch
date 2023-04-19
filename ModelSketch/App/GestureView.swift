//
//  GestureView.swift
//  ModelSketch
//
//  Created by Ben Oztalay on 4/18/23.
//

import SwiftUI
import UIKit

class GestureView: UIView {
    
    var pencilStrokeView: PencilStrokeView!
    var nodeView: NodeView!
    
    init() {
        super.init(frame: .zero)
        
        self.pencilStrokeView = PencilStrokeView()
        self.pencilStrokeView.animates = false
        self.addSubview(self.pencilStrokeView)
        
        self.nodeView = NodeView(node: Node(x: 0.0, y: 0.0))
        self.nodeView.isUserInteractionEnabled = false
        self.addSubview(self.nodeView)
    }
    
    override func layoutSubviews() {
        self.pencilStrokeView.frame = self.bounds
        self.nodeView.node.x = self.center.x
        self.nodeView.node.y = self.center.y
        self.nodeView.update(in: self)
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
