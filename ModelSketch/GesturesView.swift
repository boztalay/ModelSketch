//
//  GesturesView.swift
//  ModelSketch
//
//  Created by Ben Oztalay on 4/18/23.
//

import SwiftUI
import UIKit

class GesturesView: UIView {
    
    init() {
        super.init(frame: .zero)
        
        self.backgroundColor = .red
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct RepresentedGesturesView: UIViewRepresentable {
    typealias UIViewType = GesturesView

    func makeUIView(context: Context) -> GesturesView {
        return GesturesView()
    }
    
    func updateUIView(_ uiView: GesturesView, context: Context) {

    }
}
