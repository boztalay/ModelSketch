//
//  MetaInk.swift
//  ModelSketch
//
//  Created by Ben Oztalay on 4/27/23.
//

import Foundation

// circle gesture to open a menu to pick a relationship type
// could have the menu open with a scratch pad next to it to accept a gesture as shorthand

// define quanitites in meta ink, a MetaQuanitityNode
// then define constraints between those quantites
// and map those constraints to Relationships in the construction graph

// meta quantity nodes have either literal values for min and max, or are connected to other nodes to get those values
// plain meta nodes implement readQuantity by calling their connected node's readQuantity
//  - this makes the graph traversal simple
// plain meta nodes can connect to any number of other nodes? maybe just two?
//  - if there were more than two, how would you know which one to ask for a value?
//  - maybe it just sets up an equality constraint, per crosscut
//    - still not totally sure how this would be implemented

// need a way to set up relationships that aren't directly connected through nodes
//  - e.g. a distance relationship that queries another distance relationship and gets
//    updates when the source gets updates
//  - that might just be a "queried distance relationship" or something like that, a relationship
//    that takes in two nodes and another relationship
//  - then that "queried distance relationship" gets added as an outgoing relationship of the
//    nodeIn of the source relationship
//  - to keep it symmetric, say there's the source quantity with nodes A and B, and the
//    dependent quantity with nodes C and D, then you'd have two queried relationships,
//    one going from C to D and is an outgoing relationship on A (and taking in the A to B
//    relationship), and another going from D to C and is an outgoing relationship on B
//    (and taking in the B to A relationship)

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
    var equalNode: MetaQuantityNode?

    init(min: Double? = nil, max: Double? = nil, equalNode: MetaQuantityNode? = nil) {
        self.min = min
        self.max = max
        self.equalNode = equalNode

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
    var relationshipAB: DistanceRelationship?
    var relationshipBA: DistanceRelationship?
    
    init(nodeA: ConstructionNode, nodeB: ConstructionNode, min: Double? = nil, max: Double? = nil, equalNode: MetaQuantityNode? = nil) {
        self.nodeA = nodeA
        self.nodeB = nodeB
        self.relationshipAB = nil
        self.relationshipBA = nil

        super.init(min: min, max: max, equalNode: equalNode)
        
        self.relationshipAB = DistanceRelationship(nodeIn: self.nodeA, nodeOut: self.nodeB, min: self.min, max: self.max)
        self.relationshipBA = DistanceRelationship(nodeIn: self.nodeB, nodeOut: self.nodeA, min: self.min, max: self.max)
        let graph = self.nodeA.graph
        graph.add(relationship: self.relationshipAB!)
        graph.add(relationship: self.relationshipBA!)
//        self.updateRelationships()
    }
    
    override func updateRelationships() {
        let graph = self.nodeA.graph
        
//        if let relationshipAB = self.relationshipAB {
//            graph.remove(relationship: relationshipAB)
//            self.relationshipAB = nil
//        }
//
//        if let relationshipBA = self.relationshipBA {
//            graph.remove(relationship: relationshipBA)
//            self.relationshipBA = nil
//        }
//
//        self.relationshipAB = DistanceRelationship(nodeIn: self.nodeA, nodeOut: self.nodeB, min: self.min, max: self.max)
//        self.relationshipBA = DistanceRelationship(nodeIn: self.nodeB, nodeOut: self.nodeA, min: self.min, max: self.max)
//        graph.add(relationship: self.relationshipAB!)
//        graph.add(relationship: self.relationshipBA!)
        
        if let equalNode = self.equalNode as? MetaDistanceQuantityNode {
            self.relationshipAB!.setEqualRelationship(equalNode.relationshipAB!)
            self.relationshipBA!.setEqualRelationship(equalNode.relationshipBA!)
        }
        
        graph.update()
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
