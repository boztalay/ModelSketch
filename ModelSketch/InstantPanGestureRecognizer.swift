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

class PencilInstantPanGestureRecognizer: InstantPanGestureRecognizer {
    
    override init(target: Any?, action: Selector?) {
        super.init(target: target, action: action)

        self.minimumNumberOfTouches = 1
        self.maximumNumberOfTouches = 1
        self.allowedTouchTypes = [NSNumber(integerLiteral: UITouch.TouchType.pencil.rawValue)]
    }
}
