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
    
    static func == (lhs: MetaNode, rhs: MetaNode) -> Bool {
        return (lhs.id == rhs.id)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
}

class MetaQuantityNode: MetaNode {

    var min: Double?
    var max: Double?

    init(min: Double? = nil, max: Double? = nil) {
        self.min = min
        self.max = max

        super.init()
    }
    
    func readQuantity() -> Double {
        fatalError("readQuantity must be implemented")
    }
    
    func updateRelationships() {
        fatalError("updateRelationships must be implemented")
    }
}

class MetaDistanceQuantityNode: MetaQuantityNode {
    
    let nodeA: ConstructionNode
    let nodeB: ConstructionNode
    
    init(nodeA: ConstructionNode, nodeB: ConstructionNode, min: Double? = nil, max: Double? = nil) {
        self.nodeA = nodeA
        self.nodeB = nodeB

        super.init(min: min, max: max)
    }
    
    override func readQuantity() -> Double {
        return self.nodeA.cgPoint.distance(to: self.nodeB.cgPoint)
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
        self.constructionGraph.update()
    }
}
