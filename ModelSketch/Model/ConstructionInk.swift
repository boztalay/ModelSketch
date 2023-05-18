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
    private(set) var outgoingRelationships: [Relationship]
    
    private var lastXRelationshipPriority: RelationshipPriority?
    private var lastYRelationshipPriority: RelationshipPriority?
    
    var cgPoint: CGPoint {
        return CGPoint(x: self.x, y: self.y)
    }
    
    init(graph: ConstructionGraph) {
        self.id = ConstructionNode.getNextId()
        self.graph = graph
        self.x = 0.0
        self.y = 0.0
        self.outgoingRelationships = []
    }
    
    func update() {
        self.lastXRelationshipPriority = nil
        self.lastYRelationshipPriority = nil
    }
    
    func addOutgoingRelationship(_ relationship: Relationship) {
        // TODO: Some validation that this relationship involves this node?
        guard !self.outgoingRelationships.contains(relationship) else {
            return
        }

        self.outgoingRelationships.append(relationship)
    }
    
    func removeRelationship(_ relationship: Relationship) {
        guard let index = self.outgoingRelationships.firstIndex(of: relationship) else {
            return
        }
        
        self.outgoingRelationships.remove(at: index)
    }
    
    func removeRelationships(containing other: ConstructionNode) {
        self.outgoingRelationships.removeAll(where: { $0.contains(other) })
    }
    
    func canSetX(with relationship: Relationship) -> Bool {
        guard let lastXRelationshipPriority = self.lastXRelationshipPriority else {
            return true
        }
        
        return (relationship.inheritedPriority! <= lastXRelationshipPriority)
    }
    
    func canSetY(with relationship: Relationship) -> Bool {
        guard let lastYRelationshipPriority = self.lastYRelationshipPriority else {
            return true
        }
        
        return (relationship.inheritedPriority! <= lastYRelationshipPriority)
    }
    
    func set(x value: Double, with relationship: Relationship) -> Bool {
        guard self.canSetX(with: relationship) else {
            return false
        }
        
        self.x = value
        self.lastXRelationshipPriority = relationship.inheritedPriority!
        
        return true
    }
    
    func set(y value: Double, with relationship: Relationship) -> Bool {
        guard self.canSetY(with: relationship) else {
            return false
        }
        
        self.y = value
        self.lastYRelationshipPriority = relationship.inheritedPriority!
        
        return true
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
    private(set) var relationships: [Relationship]
    
    init() {
        self.nodes = []
        self.connections = []
        self.relationships = []
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
        
        self.relationships.removeAll(where: { $0.contains(nodeToRemove) })
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

    func add(relationship: Relationship) {
        // TODO: Maybe validate that the relationship contains valid nodes?
        self.relationships.append(relationship)
    }
    
    func remove(relationship: Relationship) {
        guard let index = self.relationships.firstIndex(of: relationship) else {
            return
        }
        
        self.relationships.remove(at: index)
        relationship.removeFromNodes()
    }
    
    func areAllNodeToNodeRelationshipsSatisfied() -> Bool {
        let nodeToNodeRelationships = self.relationships.filter({ ($0 as? NodeToNodeRelationship) != nil }).map({ $0 as! NodeToNodeRelationship })
        return nodeToNodeRelationships.map({ $0.isSatisfied() }).reduce(true, { $0 && $1 })
    }
    
    func update() {
        for node in self.nodes {
            node.update()
        }
        
        // Sort input relationships by lowest priority first
        var inputRelationships = self.relationships.filter({ ($0 as? InputRelationship) != nil }).map({ $0 as! InputRelationship })
        inputRelationships.sort(by: { $0.priority > $1.priority })
        
        for relationship in inputRelationships {
            for relationship in self.relationships {
                relationship.resetForPropagation()
            }
            
            relationship.propagateWithPriority()
        }
        
        // TODO: This could be more efficient
        for relationship in self.relationships.filter({ $0.temporary }) {
            for node in self.nodes {
                node.removeRelationship(relationship)
            }
        }
        
        self.relationships.removeAll(where: { $0.temporary })
    }
}
