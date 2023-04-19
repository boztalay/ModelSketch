//
//  InstantPanGestureRecognizer.swift
//  ModelSketch
//
//  Created by Ben Oztalay on 4/11/23.
//

import UIKit

class InstantPanGestureRecognizer: UIPanGestureRecognizer {

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        state = .began
    }
}
