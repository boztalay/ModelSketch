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

class MetaConstraintNode: MetaNode {
    
    let nodeA: ConstructionNode
    let nodeB: ConstructionNode
    
    init(nodeA: ConstructionNode, nodeB: ConstructionNode) {
        self.nodeA = nodeA
        self.nodeB = nodeB
        super.init()
    }
}

class MetaDistanceConstraintNode: MetaConstraintNode {
    
    let distance: Double
    
    init(distance: Double, nodeA: ConstructionNode, nodeB: ConstructionNode) {
        self.distance = distance
        super.init(nodeA: nodeA, nodeB: nodeB)
    }
}

class MetaGraph {
    
    var nodes: [MetaNode]
    let constructionGraph: ConstructionGraph
    
    init(constructionGraph: ConstructionGraph) {
        self.nodes = []
        self.constructionGraph = constructionGraph
        
        let nodeA = self.constructionGraph.createNode()
        nodeA.x = 200.0
        nodeA.y = 200.0
        
        let nodeB = self.constructionGraph.createNode()
        nodeB.x = 300.0
        nodeB.y = 300.0
        
        let distanceConstraint = MetaDistanceConstraintNode(distance: 100.0, nodeA: nodeA, nodeB: nodeB)
        self.nodes.append(distanceConstraint)
    }
}
