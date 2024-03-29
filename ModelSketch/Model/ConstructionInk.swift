//
//  ConstructionInk.swift
//  ModelSketch
//
//  Created by Ben Oztalay on 4/27/23.
//

import Foundation

class ConstructionSpring: Hashable {
    
    let stiffness: Double
    let dampingCoefficient: Double

    var minFreeLength: Double?
    var maxFreeLength: Double?
    
    private(set) var pointA: CGPoint?
    let nodeA: ConstructionNode?
    let nodeB: ConstructionNode
    
    // TODO: Rename this, it's the angle of the line that the force vector
    // TODO: should only be applied perpendicular to
    var perpendicularAngle: Double?
    
    var lastDisplacement: Double
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
        if let minFreeLength = self.minFreeLength {
            if self.length < minFreeLength {
                return self.length - minFreeLength
            }
        }
        
        if let maxFreeLength = self.maxFreeLength {
            if self.length > maxFreeLength {
                return self.length - maxFreeLength
            }
        }
        
        return 0.0
    }
    
    init(stiffness: Double, dampingCoefficient: Double, nodeA: ConstructionNode, nodeB: ConstructionNode, minFreeLength: Double? = nil, maxFreeLength: Double? = nil) {
        self.stiffness = stiffness
        self.dampingCoefficient = dampingCoefficient
        self.pointA = nil
        self.nodeA = nodeA
        self.nodeB = nodeB
        self.minFreeLength = minFreeLength
        self.maxFreeLength = maxFreeLength
        self.lastDisplacement = 0.0
        self.velocity = 0.0
        self.force = 0.0
        
        self.nodeA!.add(spring: self)
        self.nodeB.add(spring: self)

        self.lastDisplacement = self.displacement
    }
    
    init(stiffness: Double, dampingCoefficient: Double, pointA: CGPoint, nodeB: ConstructionNode, minFreeLength: Double? = nil, maxFreeLength: Double? = nil) {
        self.stiffness = stiffness
        self.dampingCoefficient = dampingCoefficient
        self.pointA = pointA
        self.nodeA = nil
        self.nodeB = nodeB
        self.minFreeLength = minFreeLength
        self.maxFreeLength = maxFreeLength
        self.lastDisplacement = 0.0
        self.velocity = 0.0
        self.force = 0.0

        self.nodeB.add(spring: self)
        
        self.lastDisplacement = self.displacement
    }

    func set(pointA: CGPoint) {
        guard self.nodeA == nil else {
            // TODO: Something more productive here
            fatalError()
        }
        
        self.pointA = pointA
    }
    
    func update(dt: Double) {
        // Calculate the spring's displacement velocity
        self.velocity = (self.displacement - self.lastDisplacement) / dt
        self.lastDisplacement = self.displacement
        
        // Calculate the spring's force
        let dampingForce = -1.0 * self.dampingCoefficient * self.velocity
        let displacementForce = -1.0 * self.displacement * self.stiffness
        self.force = dampingForce + displacementForce
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
        
        var force = CGPoint(
            x: self.force * cos(angle),
            y: self.force * sin(angle)
        )
        
        if let perpendicularAngle = self.perpendicularAngle {
            let minAngle = perpendicularAngle - (Double.pi / 2.0)
            let maxAngle = perpendicularAngle + (Double.pi / 2.0)
            let minDelta = abs(angle - minAngle)
            let maxDelta = abs(angle - maxAngle)
            let applyAngle = (minDelta < maxDelta) ? minAngle : maxAngle
            
            // Dot product to project the force vector onto the perpendicular angle
            let appliedForce = (cos(applyAngle) * force.x) + (sin(applyAngle) * force.y)
            force.x = appliedForce * cos(applyAngle)
            force.y = appliedForce * sin(applyAngle)
        }
        
        return force
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
    
    static func == (lhs: ConstructionSpring, rhs: ConstructionSpring) -> Bool {
        return (lhs.pointA == rhs.pointA) && (lhs.nodeA == rhs.nodeA) && (lhs.nodeB == rhs.nodeB)
    }
    
    func hash(into hasher: inout Hasher) {
        if let pointA = self.pointA {
            hasher.combine(pointA.x)
            hasher.combine(pointA.y)
        }
        
        if let nodeA = self.nodeA {
            hasher.combine(nodeA.hashValue)
        }
        
        hasher.combine(self.nodeB.hashValue)
    }
}

class AffixSpring: ConstructionSpring {
    
    init(node: ConstructionNode, to point: CGPoint) {
        super.init(stiffness: 5000.0, dampingCoefficient: 141.0 / 1.5, pointA: point, nodeB: node, minFreeLength: 0.0, maxFreeLength: 0.0)
    }
}

class DistanceSpring: ConstructionSpring {
    
    init(nodeA: ConstructionNode, nodeB: ConstructionNode) {
        super.init(stiffness: 2500.0, dampingCoefficient: 100.0 / 1.5, nodeA: nodeA, nodeB: nodeB)
    }
}

class FollowPencilSpring: ConstructionSpring {
    
    init(node: ConstructionNode, location: CGPoint) {
        super.init(stiffness: 5000.0, dampingCoefficient: 141.0 / 1.5, pointA: location, nodeB: node, minFreeLength: 0.0, maxFreeLength: 0.0)
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
    
    func remove(spring: ConstructionSpring) {
        self.springs.removeAll(where: { $0 == spring })
    }
    
    func update(dt: Double) {
        let springForce = self.springs.reduce(CGPoint.zero, { $0.adding($1.forceVector(for: self)) })
        let frictionForce = self.velocity.scaled(by: -3.0) // TODO: Make this a static let parameter or tunable, also needs to be scaled to the spring force somehow?
        let totalForce = springForce.adding(frictionForce)
        
        // NOTE: Mass is 1.0, so force is acceleration in this case
        self.velocity = self.velocity.adding(totalForce.scaled(by: dt))
        
        self.x = self.x + (self.velocity.x * dt)
        self.y = self.y + (self.velocity.y * dt)
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
        
        for node in self.nodes {
            node.removeSprings(containing: nodeToRemove)
        }
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
    
    func remove(spring: ConstructionSpring) {
        for node in self.nodes {
            node.remove(spring: spring)
        }
        
        self.springs.removeAll(where: { $0 == spring })
    }
    
    func update(dt: Double) {
        // TODO: Try to meet a maximum dt instead of just dividing by
        // TODO: subframeCount, this would keep the physics steadier
        // TODO: with varying frame rates
        let subframeCount = 25

        for _ in 0 ..< subframeCount {
            let subframeDt = dt / Double(subframeCount)
            
            for spring in self.springs {
                spring.update(dt: subframeDt)
            }
            
            for node in self.nodes {
                node.update(dt: subframeDt)
            }
        }
    }
}
