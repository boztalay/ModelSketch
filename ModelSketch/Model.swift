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
    var x: Double
    var y: Double
    
    var cgPoint: CGPoint {
        get {
            return CGPoint(x: self.x, y: self.y)
        } set {
            self.x = newValue.x
            self.y = newValue.y
        }
    }
    
    init(cgPoint: CGPoint) {
        self.id = Node.getNextId()
        self.x = cgPoint.x
        self.y = cgPoint.y
    }
    
    init(x: Double, y: Double) {
        self.id = Node.getNextId()
        self.x = x
        self.y = y
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
    
    static func == (lhs: Connection, rhs: Connection) -> Bool {
        return ((lhs.nodeA == rhs.nodeA) && (lhs.nodeB == rhs.nodeB)) || ((lhs.nodeA == rhs.nodeB) && (lhs.nodeB == rhs.nodeA))
    }
}

class Model {

    private(set) var nodes: [Node]
    private(set) var connections: [Connection]
    
    init() {
        self.nodes = []
        self.connections = []
    }
    
    func createNode(at cgPoint: CGPoint) {
        self.nodes.append(Node(cgPoint: cgPoint))
    }
    
    func createNode(at x: Double, _ y: Double) {
        self.nodes.append(Node(x: x, y: y))
    }
    
    func connect(between nodeA: Node, _ nodeB: Node) {
        let connection = Connection(nodeA: nodeA, nodeB: nodeB)
        guard !self.connections.contains(connection) else {
            return
        }
        
        self.connections.append(connection)
    }
}
