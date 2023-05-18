//
//  ConstructionInk.swift
//  ModelSketch
//
//  Created by Ben Oztalay on 4/27/23.
//

import Foundation

class ConstructionSpring {
    
    let stiffness: Double
    let dampingCoefficient: Double
    let freeLength: Double
    
    let pointA: CGPoint?
    let nodeA: ConstructionNode?
    let nodeB: ConstructionNode
    
    let temporary: Bool
    
    var lastLength: Double
    var velocity: Double
    var force: Double
    
    var startPoint: CGPoint {
        return self.pointA ?? self.nodeA!.cgPoint
    }
    
    var endPoint: CGPoint {
        return self.nodeB.cgPoint
    }
    
    var length: Double {
        return self.startPoint.distance(to: self.endPoint)
    }
    
    var displacement: Double {
        return self.length - self.freeLength
    }
    
    init(stiffness: Double, dampingCoefficient: Double, nodeA: ConstructionNode, nodeB: ConstructionNode, freeLength: Double, temporary: Bool = false) {
        self.stiffness = stiffness
        self.dampingCoefficient = dampingCoefficient
        self.pointA = nil
        self.nodeA = nodeA
        self.nodeB = nodeB
        self.freeLength = freeLength
        self.lastLength = 0.0
        self.velocity = 0.0
        self.force = 0.0
        self.temporary = temporary
        
        self.nodeA!.add(spring: self)
        self.nodeB.add(spring: self)
    }
    
    init(stiffness: Double, dampingCoefficient: Double, pointA: CGPoint, nodeB: ConstructionNode, freeLength: Double, temporary: Bool = false) {
        self.stiffness = stiffness
        self.dampingCoefficient = dampingCoefficient
        self.pointA = pointA
        self.nodeA = nil
        self.nodeB = nodeB
        self.freeLength = freeLength
        self.lastLength = 0.0
        self.velocity = 0.0
        self.force = 0.0
        self.temporary = temporary

        self.nodeB.add(spring: self)
    }
    
    func resetForUpdate() {
        self.velocity = 0.0
        self.force = 0.0
        self.lastLength = self.length
    }
    
    func update() {
        // Calculate velocity assuming a constant dt
        self.velocity = self.length - self.lastLength
        self.lastLength = self.length
        
        // Calculate the spring's force
        let dampingForce = -1.0 * self.dampingCoefficient * self.velocity
        let displacementForce = -1.0 * self.displacement * self.stiffness
        self.force = dampingForce + displacementForce
     
        if self.nodeB.id == 1 {
            print("node \(self.nodeB.id) spring: (length \(self.length)), (velocity \(self.velocity)), (force \(self.force))")
        }
    }
    
    // TODO: Could be cleaner
    func otherPoint(for node: ConstructionNode) -> CGPoint? {
        if let pointA = self.pointA {
            if node == self.nodeB {
                return pointA
            }
        } else if let nodeA = self.nodeA {
            if node == nodeA {
                return self.nodeB.cgPoint
            } else if node == self.nodeB {
                return nodeA.cgPoint
            }
        }
        
        return nil
    }
    
    // TODO: Make an actual vector type
    func forceVector(for node: ConstructionNode) -> CGPoint {
        guard let otherPoint = self.otherPoint(for: node) else {
            // TODO: Something more productive
            fatalError()
        }

        let run = node.cgPoint.x - otherPoint.x
        let rise = node.cgPoint.y - otherPoint.y
        let angle = atan2(rise, run)

        return CGPoint(
            x: self.force * cos(angle),
            y: self.force * sin(angle)
        )
    }
    
    func hasSettled() -> Bool {
        return (abs(self.velocity) < 0.001)
    }
    
    func contains(_ node: ConstructionNode) -> Bool {
        if node == self.nodeB {
            return true
        }
        
        if let nodeA = self.nodeA {
            return (node == nodeA)
        }
        
        return false
    }
}

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
    private(set) var springs: [ConstructionSpring]
    
    private var velocity: CGPoint
    
    var cgPoint: CGPoint {
        return CGPoint(x: self.x, y: self.y)
    }
    
    init(graph: ConstructionGraph, location: CGPoint) {
        self.id = ConstructionNode.getNextId()
        self.graph = graph
        self.x = location.x
        self.y = location.y
        self.springs = []
        self.velocity = .zero
    }
    
    func add(spring: ConstructionSpring) {
        // TODO: Check if the spring is already in the list
        self.springs.append(spring)
    }
    
    func removeSprings(containing node: ConstructionNode) {
        self.springs.removeAll(where: { $0.contains(node) })
    }
    
    func resetForUpdate() {
        self.velocity = .zero
    }
    
    func update() {
        // NOTE: Mass is 1.0, so force is acceleration in this case
        let forceVector = self.springs.reduce(CGPoint.zero, { $0.adding($1.forceVector(for: self)) })
        
        if self.id == 1 {
            print("node 1 force vector: (\(forceVector.x), \(forceVector.y))")
        }
        
        self.velocity = self.velocity.adding(forceVector)
        
        self.x = self.x + self.velocity.x
        self.y = self.y + self.velocity.y
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
    private(set) var springs: [ConstructionSpring]
    
    init() {
        self.nodes = []
        self.connections = []
        self.springs = []
    }
    
    func createNode(at location: CGPoint) -> ConstructionNode {
        let node = ConstructionNode(graph: self, location: location)
        self.nodes.append(node)
        return node
    }
    
    func remove(node nodeToRemove: ConstructionNode) {
        guard let index = self.nodes.firstIndex(of: nodeToRemove) else {
            return
        }
        
        self.nodes.remove(at: index)
        self.connections.removeAll(where: { $0.contains(nodeToRemove) })
        self.springs.removeAll(where: { $0.contains(nodeToRemove) })
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
    
    func add(spring: ConstructionSpring) {
        // TODO: Check if the spring is already in the list
        self.springs.append(spring)
    }
    
    func haveAllSpringsSettled() -> Bool {
        return self.springs.reduce(true, { $0 && $1.hasSettled() })
    }
    
    func update() {
        print("update")
        
        for node in self.nodes {
            node.resetForUpdate()
        }
        
        for spring in self.springs {
            spring.resetForUpdate()
        }
        
        for spring in self.springs {
            spring.update()
        }
        
        while true {
            for node in self.nodes {
                node.update()
            }
            
            for spring in self.springs {
                spring.update()
            }
            
            if self.haveAllSpringsSettled() {
                break
            }
        }
        
        self.springs.removeAll(where: { $0.temporary })
    }
}
