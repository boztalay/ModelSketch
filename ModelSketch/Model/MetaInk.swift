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
        
    }
    
    static func == (lhs: MetaNode, rhs: MetaNode) -> Bool {
        return (lhs.id == rhs.id)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
}

class MetaDistanceNode: MetaNode {
    
    let nodeA: ConstructionNode
    let nodeB: ConstructionNode

    private(set) var spring: ConstructionSpring?
    private(set) var otherDistanceNode: MetaDistanceNode?
    
    var distance: Double {
        return self.nodeA.cgPoint.distance(to: self.nodeB.cgPoint)
    }
    
    init(nodeA: ConstructionNode, nodeB: ConstructionNode) {
        self.nodeA = nodeA
        self.nodeB = nodeB
    }
    
    func equate(to other: MetaDistanceNode) {
        self.otherDistanceNode = other
        self.spring = DistanceSpring(nodeA: self.nodeA, nodeB: self.nodeB, distance: self.otherDistanceNode!.distance)
        self.nodeA.graph.add(spring: self.spring!)
        
        if self.otherDistanceNode!.otherDistanceNode == nil {
            self.otherDistanceNode!.equate(to: self)
        }
    }
    
    override func update() {
        guard let spring = self.spring, let otherDistanceNode = self.otherDistanceNode else {
            return
        }

        spring.freeLength = otherDistanceNode.distance
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
