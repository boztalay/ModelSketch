//
//  MetaView.swift
//  ModelSketch
//
//  Created by Ben Oztalay on 4/29/23.
//

import UIKit

class MetaView: UIView, Sketchable, NodePanGestureRecognizerDelegate {

    let graph: MetaGraph
    
    init(graph: MetaGraph) {
        self.graph = graph

        super.init(frame: CGRect.zero)
    }
    
    func getNodeView(at location: CGPoint) -> UIView? {
        // TODO
        return nil
    }
    
    func hardPressStatusChanged(_ gestureRecognizer: NodePanGestureRecognizer) {
        // TODO
    }

    func handleNodePanGestureUpdate(_ gestureRecognizer: NodePanGestureRecognizer) {
        // TODO
    }
    
    func handleCreateGesture(at location: CGPoint) {
        // TODO
    }
    
    func handleScratchGesture(along points: [CGPoint]) {
        // TODO
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
