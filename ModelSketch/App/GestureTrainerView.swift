//
//  GestureTrainerView.swift
//  ModelSketch
//
//  Created by Ben Oztalay on 4/18/23.
//

import SwiftUI
import UIKit

class GestureTrainerView: UIView {
    
    var pencilStrokeView: PencilStrokeView!
    
    init() {
        super.init(frame: .zero)
        
        self.pencilStrokeView = PencilStrokeView()
        self.addSubview(self.pencilStrokeView)
    }
    
    override func layoutSubviews() {
        self.pencilStrokeView.frame = self.bounds
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct RepresentedGestureTrainerView: UIViewRepresentable {
    typealias UIViewType = GestureTrainerView
    
    @State var strokeCompletion: (PencilStroke) -> ()

    func makeUIView(context: Context) -> GestureTrainerView {
        let view = GestureTrainerView()
        view.pencilStrokeView.strokeCompletion = self.strokeCompletion
        return view
    }
    
    func updateUIView(_ uiView: GestureTrainerView, context: Context) {

    }
}
