//
//  GestureTrainerView.swift
//  ModelSketch
//
//  Created by Ben Oztalay on 4/18/23.
//

import SwiftUI
import UIKit

class GestureTrainerView: UIView {
    
    var pencilStrokeView: PencilStrokeView
    
    init() {
        self.pencilStrokeView = PencilStrokeView()
        
        super.init(frame: .zero)
        
        self.addSubview(self.pencilStrokeView)
        self.addGestureRecognizer(self.pencilStrokeView.panGestureRecognizer)
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
    
    @State var strokeCompletion: (UIImage) -> ()

    func makeUIView(context: Context) -> GestureTrainerView {
        let view = GestureTrainerView()
        view.pencilStrokeView.strokeCompletion = self.strokeCompletion
        return view
    }
    
    func updateUIView(_ uiView: GestureTrainerView, context: Context) {

    }
}
