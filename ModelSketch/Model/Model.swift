//
//  Model.swift
//  ModelSketch
//
//  Created by Ben Oztalay on 4/11/23.
//

import Foundation

class Node: Hashable {
    
    static var nextId: Int = 0
    
    static func getNextId() -> Int {
        let id = Node.nextId
        Node.nextId += 1
        return id
    }

    let id: Int
    private(set) var x: Double
    private(set) var y: Double
    private(set) var outgoingRelationshipsX: [Relationship]
    private(set) var outgoingRelationshipsY: [Relationship]
    
    private var lastRelationshipPriorityX: RelationshipPriority?
    private var lastRelationshipPriorityY: RelationshipPriority?
    
    var cgPoint: CGPoint {
        return CGPoint(x: self.x, y: self.y)
    }
    
    init() {
        self.id = Node.getNextId()
        self.x = 0.0
        self.y = 0.0
        self.outgoingRelationshipsX = []
        self.outgoingRelationshipsY = []
    }
    
    func add(outgoingRelationshipX relationship: Relationship) {
        self.outgoingRelationshipsX.append(relationship)
    }
    
    func add(outgoingRelationshipY relationship: Relationship) {
        self.outgoingRelationshipsY.append(relationship)
    }
    
    func remove(relationship: Relationship) {
        if let index = self.outgoingRelationshipsX.firstIndex(of: relationship) {
            self.outgoingRelationshipsX.remove(at: index)
        }
        
        if let index = self.outgoingRelationshipsY.firstIndex(of: relationship) {
            self.outgoingRelationshipsY.remove(at: index)
        }
    }
    
    func set(x value: Double, with relationship: Relationship) -> Bool {
        if let lastRelationshipPriorityX = self.lastRelationshipPriorityX {
            if relationship.priority >= lastRelationshipPriorityX {
                return false
            }
        }
        
        self.x = value
        self.lastRelationshipPriorityX = relationship.priority
        
        return true
    }

    func set(y value: Double, with relationship: Relationship) -> Bool {
        if let lastRelationshipPriorityY = self.lastRelationshipPriorityY {
            if relationship.priority >= lastRelationshipPriorityY {
                return false
            }
        }
        
        self.y = value
        self.lastRelationshipPriorityY = relationship.priority
        
        return true
    }
    
    func update() {
        self.lastRelationshipPriorityX = nil
        self.lastRelationshipPriorityY = nil
    }
    
    static func == (lhs: Node, rhs: Node) -> Bool {
        return (lhs.id == rhs.id)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
}

class Connection: Equatable {
    
    let nodeA: Node
    let nodeB: Node
    
    init(nodeA: Node, nodeB: Node) {
        self.nodeA = nodeA
        self.nodeB = nodeB
    }
    
    func contains(_ node: Node) -> Bool {
        return (self.nodeA == node || self.nodeB == node)
    }
    
    static func == (lhs: Connection, rhs: Connection) -> Bool {
        return ((lhs.nodeA == rhs.nodeA) && (lhs.nodeB == rhs.nodeB)) || ((lhs.nodeA == rhs.nodeB) && (lhs.nodeB == rhs.nodeA))
    }
}

class Model {

    private(set) var nodes: [Node]
    private(set) var connections: [Connection]
    private(set) var relationships: [Relationship]
    
    init() {
        self.nodes = []
        self.connections = []
        self.relationships = []
    }
    
    func createNode(at cgPoint: CGPoint) -> Node {
        let node = Node()
        self.nodes.append(node)
        self.add(relationship: FollowPencilRelationship(node: node, cgPoint: cgPoint))
        return node
    }
    
    func createNode(at x: Double, _ y: Double) -> Node {
        return self.createNode(at: CGPoint(x: x, y: y))
    }
    
    func deleteNode(_ node: Node) {
        guard let index = self.nodes.firstIndex(of: node) else {
            return
        }
        
        self.nodes.remove(at: index)
        self.connections.removeAll(where: { $0.contains(node) })
        self.relationships.removeAll(where: { $0.contains(node) })
    }
    
    func connect(between nodeA: Node, _ nodeB: Node) {
        guard nodeA != nodeB else {
            return
        }
        
        let connection = Connection(nodeA: nodeA, nodeB: nodeB)
        guard !self.connections.contains(connection) else {
            return
        }
        
        self.connections.append(connection)
    }
    
    func add(relationship: Relationship) {
        // TODO: Maybe validate that the relationship contains valid nodes?
        self.relationships.append(relationship)
    }
    
    func update() {
        for node in self.nodes {
            node.update()
        }

        for relationship in self.relationships {
            if relationship.nodeIn == nil {
                relationship.propagate()
            }
        }
        
        // TODO: This could be more efficient
        for relationship in self.relationships.filter({ $0.temporary }) {
            for node in self.nodes {
                node.remove(relationship: relationship)
            }
        }
        
        self.relationships.removeAll(where: { $0.temporary })
    }
}
