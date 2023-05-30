//
//  MetaInk.swift
//  ModelSketch
//
//  Created by Ben Oztalay on 4/27/23.
//

import Foundation

// circle gesture to open a menu to pick a relationship type
// could have the menu open with a scratch pad next to it to accept a gesture as shorthand

class MetaNode: Hashable {

    static var nextId: Int = 0
    
    static func getNextId() -> Int {
        let id = MetaNode.nextId
        MetaNode.nextId += 1
        return id
    }

    let id: Int
    var x: Double
    var y: Double
    
    var cgPoint: CGPoint {
        set {
            self.x = newValue.x
            self.y = newValue.y
        }
        get {
            return CGPoint(x: self.x, y: self.y)
        }
    }
    
    init() {
        self.id = MetaNode.getNextId()
        self.x = 0.0
        self.y = 0.0
    }
    
    func update() {
        fatalError("update must be implemented")
    }
    
    func removeReferences(to other: MetaNode) {
        fatalError("removeReferences must be implemented")
    }
    
    func removeConstructionSprings() {
        fatalError("removeConstructionSprings must be implemented")
    }
    
    static func == (lhs: MetaNode, rhs: MetaNode) -> Bool {
        return (lhs.id == rhs.id)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
}

class MetaQuantityNode: MetaNode {
    
    var min: Double? {
        if let minValue = self.minValue {
            return minValue
        } else if let minNode = self.minNode {
            return minNode.readQuantity()
        } else {
            return nil
        }
    }
    
    var max: Double? {
        if let maxValue = self.maxValue {
            return maxValue
        } else if let maxNode = self.maxNode {
            return maxNode.readQuantity()
        } else {
            return nil
        }
    }
    
    private(set) var minValue: Double?
    private(set) var maxValue: Double?
    private(set) var minNode: MetaQuantityNode?
    private(set) var maxNode: MetaQuantityNode?
    
    func setMin(to value: Double) {
        self.minValue = value
        self.minNode = nil
    }
    
    func setMax(to value: Double) {
        self.maxValue = value
        self.maxNode = nil
    }
    
    func setMin(to node: MetaDistanceNode) {
        self.minValue = nil
        self.minNode = node
    }
    
    func setMax(to node: MetaDistanceNode) {
        self.maxValue = nil
        self.maxNode = node
    }
    
    override func removeReferences(to other: MetaNode) {
        if self.minNode == other {
            self.minNode = nil
        }
        
        if self.maxNode == other {
            self.maxNode = nil
        }
    }
    
    // TODO: Better type system things
    func readQuantity() -> Double {
        fatalError("readQuantity must be implemented")
    }
}

class MetaDistanceNode: MetaQuantityNode {
    
    let nodeA: ConstructionNode
    let nodeB: ConstructionNode

    let spring: DistanceSpring
    
    init(nodeA: ConstructionNode, nodeB: ConstructionNode) {
        self.nodeA = nodeA
        self.nodeB = nodeB

        self.spring = DistanceSpring(nodeA: self.nodeA, nodeB: self.nodeB)
        self.nodeA.graph.add(spring: self.spring)
    }
    
    override func readQuantity() -> Double {
        return self.nodeA.cgPoint.distance(to: self.nodeB.cgPoint)
    }
    
    override func removeConstructionSprings() {
        self.nodeA.graph.remove(spring: self.spring)
    }
    
    override func update() {
        if let min = self.min {
            self.spring.minFreeLength = min
        }
        
        if let max = self.max {
            self.spring.maxFreeLength = max
        }
    }
}

class MetaAngleNode: MetaQuantityNode {
    
    let nodeA: ConstructionNode
    let nodeB: ConstructionNode
    let pivot: ConstructionNode
    let angleInDegrees: Double
    
    let spring: DistanceSpring
    
    var angleInRadians: Double {
        return (self.angleInDegrees * Double.pi) / 180.0
    }
    
    init(nodeA: ConstructionNode, nodeB: ConstructionNode, pivot: ConstructionNode, angleInDegrees: Double) {
        self.nodeA = nodeA
        self.nodeB = nodeB
        self.pivot = pivot
        self.angleInDegrees = angleInDegrees
        
        self.spring = DistanceSpring(nodeA: self.nodeA, nodeB: self.nodeB)
        self.nodeA.graph.add(spring: self.spring)
    }
    
    override func readQuantity() -> Double {
        let angleToA = self.pivot.cgPoint.angleOfLine(to: self.nodeA.cgPoint)
        let angleToB = self.pivot.cgPoint.angleOfLine(to: self.nodeB.cgPoint)
        return (angleToA - angleToB)
    }
    
    override func removeConstructionSprings() {
        self.nodeA.graph.remove(spring: self.spring)
    }
    
    override func update() {
        // TODO: Actual support for min and max angles
        let targetAngle = self.angleInRadians
        
        // Law of cosines given SAS (known angle between two known sides) to
        // find the length the spring between nodeA and nodeB should be
        let sideALength = self.pivot.cgPoint.distance(to: self.nodeA.cgPoint)
        let sideBLength = self.pivot.cgPoint.distance(to: self.nodeB.cgPoint)
        let sideCLength = sqrt(pow(sideALength, 2.0) + pow(sideBLength, 2.0) - (2.0 * sideALength * sideBLength * cos(targetAngle)))
        
        self.spring.minFreeLength = sideCLength
        self.spring.maxFreeLength = sideCLength
    }
}

class MetaGraph {
    
    var nodes: [MetaNode]
    let constructionGraph: ConstructionGraph
    
    init(constructionGraph: ConstructionGraph) {
        self.nodes = []
        self.constructionGraph = constructionGraph
    }
    
    func add(node: MetaNode) {
        self.nodes.append(node)
    }
    
    func update() {
        for node in self.nodes {
            node.update()
        }
    }
}
