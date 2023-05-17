//
//  ConstructionInk.swift
//  ModelSketch
//
//  Created by Ben Oztalay on 4/27/23.
//

import Foundation

class ConstructionNode: Hashable {

    static var nextId: Int = 0
    
    static func getNextId() -> Int {
        let id = ConstructionNode.nextId
        ConstructionNode.nextId += 1
        return id
    }

    let id: Int
    let graph: ConstructionGraph
    private(set) var x: Double
    private(set) var y: Double
    private(set) var relationships: [NodeToNodeRelationship]

    private(set) var moveCount: Int
    private(set) var inputPriority: RelationshipPriority?
    
    var cgPoint: CGPoint {
        return CGPoint(x: self.x, y: self.y)
    }
    
    init(graph: ConstructionGraph) {
        self.id = ConstructionNode.getNextId()
        self.graph = graph
        self.x = 0.0
        self.y = 0.0
        self.relationships = []
        self.moveCount = 0
    }
    
    func resetForPropagation() {
        self.moveCount = 0
        self.inputPriority = nil
    }
    
    func add(relationship: NodeToNodeRelationship) {
        guard relationship.contains(self) else {
            return
        }

        guard !self.relationships.contains(relationship) else {
            return
        }

        self.relationships.append(relationship)
    }
    
    func remove(relationship: NodeToNodeRelationship) {
        guard let index = self.relationships.firstIndex(of: relationship) else {
            return
        }
        
        self.relationships.remove(at: index)
    }
    
    func removeRelationships(containing other: ConstructionNode) {
        self.relationships.removeAll(where: { $0.contains(other) })
    }
    
    func areAllRelationshipsSatisfied() -> Bool {
        return self.relationships.map({ $0.isSatisfied() }).reduce(true, { $0 && $1 })
    }
    
    func fix(to position: CGPoint, with priority: RelationshipPriority) {
        self.move(to: position)
        self.inputPriority = priority
    }
    
    func move(to position: CGPoint) {
        self.x = position.x
        self.y = position.y
        self.moveCount += 1
    }
    
    func shouldBeMovedBefore(_ other: ConstructionNode) -> Bool {
        if self.inputPriority == nil && other.inputPriority == nil {
            return self.moveCount < other.moveCount
        }
        
        if self.inputPriority != nil && other.inputPriority == nil {
            return false
        }
        
        if self.inputPriority == nil && other.inputPriority != nil {
            return true
        }
        
        let selfPriority = self.inputPriority!
        let otherPriority = other.inputPriority!
        
        if selfPriority < otherPriority {
            return true
        }
        
        if otherPriority > selfPriority {
            return false
        }
        
        return self.moveCount < other.moveCount
    }
    
    static func == (lhs: ConstructionNode, rhs: ConstructionNode) -> Bool {
        return (lhs.id == rhs.id)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
}

class ConstructionConnection: Hashable {
    
    let nodeA: ConstructionNode
    let nodeB: ConstructionNode
    
    init(nodeA: ConstructionNode, nodeB: ConstructionNode) {
        guard nodeA != nodeB else {
            fatalError("Can't connect a node to itself!")
        }
        
        self.nodeA = nodeA
        self.nodeB = nodeB
    }
    
    func contains(_ node: ConstructionNode) -> Bool {
        return (self.nodeA == node || self.nodeB == node)
    }
    
    static func == (lhs: ConstructionConnection, rhs: ConstructionConnection) -> Bool {
        return ((lhs.nodeA == rhs.nodeA) && (lhs.nodeB == rhs.nodeB)) || ((lhs.nodeA == rhs.nodeB) && (lhs.nodeB == rhs.nodeA))
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.nodeA.id)
        hasher.combine(self.nodeB.id)
    }
}

class ConstructionGraph {
    
    private(set) var nodes: [ConstructionNode]
    private(set) var connections: [ConstructionConnection]
    private(set) var inputRelationships: [InputRelationship]
    private(set) var nodeToNodeRelationships: [NodeToNodeRelationship]
    
    init() {
        self.nodes = []
        self.connections = []
        self.inputRelationships = []
        self.nodeToNodeRelationships = []
    }
    
    func createNode() -> ConstructionNode {
        let node = ConstructionNode(graph: self)
        self.nodes.append(node)
        return node
    }
    
    func remove(node nodeToRemove: ConstructionNode) {
        guard let index = self.nodes.firstIndex(of: nodeToRemove) else {
            return
        }
        
        self.nodes.remove(at: index)
        self.connections.removeAll(where: { $0.contains(nodeToRemove) })
        
        for node in self.nodes {
            node.removeRelationships(containing: nodeToRemove)
        }

        self.inputRelationships.removeAll(where: { $0.contains(nodeToRemove) })
        self.nodeToNodeRelationships.removeAll(where: { $0.contains(nodeToRemove) })
    }
    
    func connect(nodeA: ConstructionNode, nodeB: ConstructionNode) {
        guard nodeA != nodeB else {
            return
        }
        
        let connection = ConstructionConnection(nodeA: nodeA, nodeB: nodeB)
        guard !self.connections.contains(connection) else {
            return
        }
        
        self.connections.append(connection)
    }

    func add(inputRelationship: InputRelationship) {
        // TODO: Maybe validate that the relationship contains valid nodes?
        self.inputRelationships.append(inputRelationship)
        
        // Sorts by lowest priority first
        self.inputRelationships.sort(by: { $0.priority > $1.priority })
    }
    
    func remove(inputRelationship: InputRelationship) {
        guard let index = self.inputRelationships.firstIndex(of: inputRelationship) else {
            return
        }
        
        self.inputRelationships.remove(at: index)
    }
    
    func add(nodeToNodeRelationship: NodeToNodeRelationship) {
        // TODO: Maybe validate that the relationship contains valid nodes?
        self.nodeToNodeRelationships.append(nodeToNodeRelationship)
    }
    
    func remove(nodeToNodeRelationship: NodeToNodeRelationship) {
        guard let index = self.nodeToNodeRelationships.firstIndex(of: nodeToNodeRelationship) else {
            return
        }
        
        self.nodeToNodeRelationships.remove(at: index)
    }
    
    func areAllNodeToNodeRelationshipsSatisfied() -> Bool {
        return self.nodeToNodeRelationships.map({ $0.isSatisfied() }).reduce(true, { $0 && $1 })
    }
    
    func update() {
        for node in self.nodes {
            node.resetForPropagation()
        }
        
        for inputRelationship in self.inputRelationships {
            inputRelationship.apply()
        }
        
        var iterations = 0
        while !self.areAllNodeToNodeRelationshipsSatisfied() {
            let relationship = self.nodeToNodeRelationships.filter({ !$0.isSatisfied() }).map({ $0 as! DistanceRelationship }).sorted(by: { $0.getError() > $1.getError() }).first!
            relationship.apply()
            
//            for relationship in self.nodeToNodeRelationships.filter({ !$0.isSatisfied() }).map({ $0 as! DistanceRelationship }).sorted(by: { $0.getError() > $1.getError() }) {
//                relationship.apply()
//            }
            iterations += 1
        }
        print("\(iterations) iterations")
        
        self.inputRelationships.removeAll(where: { $0.temporary })
    }
}
