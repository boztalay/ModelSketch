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
    
    private var lastRelationshipPriorityX: RelationshipPriority?
    private var lastRelationshipPriorityY: RelationshipPriority?
    
    var cgPoint: CGPoint {
        return CGPoint(x: self.x, y: self.y)
    }
    
    init() {
        self.id = Node.getNextId()
        self.x = 0.0
        self.y = 0.0
    }
    
    func set(x value: Double, with relationship: Relationship) {
        if let lastRelationshipPriorityX = self.lastRelationshipPriorityX {
            if relationship.priority >= lastRelationshipPriorityX {
                return
            }
        }
        
        self.x = value
        self.lastRelationshipPriorityX = relationship.priority
    }

    func set(y value: Double, with relationship: Relationship) {
        if let lastRelationshipPriorityY = self.lastRelationshipPriorityY {
            if relationship.priority >= lastRelationshipPriorityY {
                return
            }
        }
        
        self.y = value
        self.lastRelationshipPriorityY = relationship.priority
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
    
    func createNode(at cgPoint: CGPoint) {
        let node = Node()
        self.nodes.append(node)
        self.relationships.append(TemporaryAffixRelationship(node: node, cgPoint: cgPoint))
    }
    
    func createNode(at x: Double, _ y: Double) {
        self.createNode(at: CGPoint(x: x, y: y))
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
            relationship.apply()
        }
        
        self.relationships.removeAll(where: { $0.temporary })
    }
}
