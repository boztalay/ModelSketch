//
//  GestureView.swift
//  ModelSketch
//
//  Created by Ben Oztalay on 4/18/23.
//

import SwiftUI
import UIKit

class MockNodeView: UIView {
    
    func set(position: CGPoint) {
        self.backgroundColor = .clear
        
        let frameRadius = ConstructionNodeView.radius + ConstructionNodeView.lineWidth
        
        self.frame = CGRect(
            origin: CGPoint(
                x: position.x - frameRadius,
                y: position.y - frameRadius
            ),
            size: CGSize(
                width: frameRadius * 2.0,
                height: frameRadius * 2.0
            )
        )
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        let circlePath = UIBezierPath(
            ovalIn: CGRect(
                x: (self.frame.width / 2.0) - ConstructionNodeView.radius,
                y: (self.frame.height / 2.0) - ConstructionNodeView.radius,
                width: 2.0 * ConstructionNodeView.radius,
                height: 2.0 * ConstructionNodeView.radius
            )
        )

        ConstructionNodeView.HighlightState.normal.strokeColor.setStroke()
        UIColor.white.setFill()
        circlePath.lineWidth = ConstructionNodeView.lineWidth
        circlePath.fill()
        circlePath.stroke()
    }
}

class GestureView: UIView {
    
    static let nodeViewSpacing = 25.0
    
    var pencilStrokeView: PencilStrokeView!
    var nodeViews: [MockNodeView]!
    
    init() {
        super.init(frame: .zero)
        
        self.pencilStrokeView = PencilStrokeView()
        self.pencilStrokeView.animates = false
        self.addSubview(self.pencilStrokeView)
        
        self.nodeViews = [
            MockNodeView(),
            MockNodeView(),
            MockNodeView(),
            MockNodeView()
        ]
        
        for nodeView in self.nodeViews {
            nodeView.isUserInteractionEnabled = false
            self.addSubview(nodeView)
        }
    }
    
    override func layoutSubviews() {
        self.pencilStrokeView.frame = self.bounds
        
        self.nodeViews[0].set(
            position: CGPoint(
                x: self.center.x + GestureView.nodeViewSpacing,
                y: self.center.y + GestureView.nodeViewSpacing
            )
        )
        
        self.nodeViews[1].set(
            position: CGPoint(
                x: self.center.x - GestureView.nodeViewSpacing,
                y: self.center.y + GestureView.nodeViewSpacing
            )
        )
        
        self.nodeViews[2].set(
            position: CGPoint(
                x: self.center.x + GestureView.nodeViewSpacing,
                y: self.center.y - GestureView.nodeViewSpacing
            )
        )
        
        self.nodeViews[3].set(
            position: CGPoint(
                x: self.center.x - GestureView.nodeViewSpacing,
                y: self.center.y - GestureView.nodeViewSpacing
            )
        )
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
