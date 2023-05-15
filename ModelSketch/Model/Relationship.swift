//
//  Relationship.swift
//  ModelSketch
//
//  Created by Ben Oztalay on 4/26/23.
//

import Foundation

//
// Base Relationship Classes
//

enum RelationshipPriority: Int, Comparable {

    case fixed     = 0
    case userInput = 1
    
    static func < (lhs: RelationshipPriority, rhs: RelationshipPriority) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

class Relationship: Hashable {
    
    static var nextId: Int = 0
    
    static func getNextId() -> Int {
        let id = Relationship.nextId
        Relationship.nextId += 1
        return id
    }

    let id: Int
    let temporary: Bool
    var nodes: [ConstructionNode]
    
    init(temporary: Bool) {
        self.id = Relationship.getNextId()
        self.temporary = temporary
        self.nodes = []
    }
    
    func contains(_ node: ConstructionNode) -> Bool {
        return self.nodes.contains(node)
    }
    
    static func == (lhs: Relationship, rhs: Relationship) -> Bool {
        return (lhs.id == rhs.id)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
}

class InputRelationship: Relationship {
    
    let priority: RelationshipPriority
    
    var node: ConstructionNode {
        return self.nodes[0]
    }
    
    init(node: ConstructionNode, priority: RelationshipPriority, temporary: Bool) {
        self.priority = priority
        super.init(temporary: temporary)
        self.nodes.append(node)
    }
    
    func apply() {
        fatalError("apply must be implemented")
    }
    
    func propagate() {
        self.apply()
        self.node.resolveRelationships()
    }
}

class NodeToNodeRelationship: Relationship {
    
    var nodeA: ConstructionNode {
        return self.nodes[0]
    }
    
    var nodeB: ConstructionNode {
        return self.nodes[1]
    }

    init(nodeA: ConstructionNode, nodeB: ConstructionNode, temporary: Bool) {
        super.init(temporary: temporary)
        self.nodes.append(nodeA)
        self.nodes.append(nodeB)
        
        for node in self.nodes {
            node.add(relationship: self)
        }
    }
    
    func isSatisfied() -> Bool {
        fatalError("isSatisfied must be implemented")
    }
    
    func getOtherNode(_ node: ConstructionNode) -> ConstructionNode {
        if node == self.nodeA {
            return self.nodeB
        } else if node == self.nodeB {
            return self.nodeA
        } else {
            // TODO: Something more productive here
            fatalError()
        }
    }

    func removeFromNodes() {
        for node in self.nodes {
            node.remove(relationship: self)
        }
    }
}

//
// Relationships
//

class AffixRelationship: InputRelationship {
    
    let cgPoint: CGPoint
    
    init(node: ConstructionNode, cgPoint: CGPoint, priority: RelationshipPriority, temporary: Bool) {
        self.cgPoint = cgPoint
        super.init(node: node, priority: priority, temporary: temporary)
    }
    
    convenience init(node: ConstructionNode, cgPoint: CGPoint) {
        self.init(node: node, cgPoint: cgPoint, priority: .fixed, temporary: false)
    }

    override func apply() {
        self.node.fix(position: self.cgPoint)
    }
}

class FollowPencilRelationship: AffixRelationship {
    
    init(node: ConstructionNode, cgPoint: CGPoint) {
        super.init(node: node, cgPoint: cgPoint, priority: .userInput, temporary: true)
    }
}

class DistanceRelationship: NodeToNodeRelationship {
    
    static let epsilon = 0.00001
    
    var min: Double?
    var max: Double?
    
    var distance: Double {
        return self.nodeA.cgPoint.distance(to: self.nodeB.cgPoint)
    }
    
    var targetDistance: Double? {
        // TODO: Actually take min and max into account separately
        if let min = min, max != nil {
            return min
        }
        
        return nil
    }
    
    var error: Double {
        return abs(self.targetDistance! - self.distance)
    }
    
    init(nodeA: ConstructionNode, nodeB: ConstructionNode, min: Double? = nil, max: Double? = nil) {
        if let min = min, let max = max {
            if min > max {
                fatalError("min (\(min)) must be less than max (\(max))")
            }
        }
        
        self.min = min
        self.max = max

        super.init(nodeA: nodeA, nodeB: nodeB, temporary: false)
    }
    
    override func isSatisfied() -> Bool {
        if let min = self.min, self.distance < (min - DistanceRelationship.epsilon) {
            print("    not satisfied \(self.distance) < \(min)")
            return false
        }
        
        if let max = self.max, self.distance > (max + DistanceRelationship.epsilon) {
            print("    not satisfied \(self.distance) > \(max)")
            return false
        }
        
        return true
    }
    
    func closestPointTo(_ node: ConstructionNode) -> CGPoint {
        guard self.contains(node) else {
            // TODO: Something more productive here
            fatalError()
        }
        
        var targetDistance = self.distance
        
        if let min = self.min, self.distance < min {
            targetDistance = min
        }
        
        if let max = self.max, self.distance > max {
            targetDistance = max
        }
        
        let startNode = self.getOtherNode(node)
        let endNode = node
        
        guard endNode.canMove() else {
            // TODO: Something more productive here
            fatalError()
        }
        
        let run = endNode.cgPoint.x - startNode.cgPoint.x
        let rise = endNode.cgPoint.y - startNode.cgPoint.y
        let angle = atan2(rise, run)
        
        let newRun = targetDistance * cos(angle)
        let newRise = targetDistance * sin(angle)
        
        return CGPoint(x: startNode.cgPoint.x + newRun, y: startNode.cgPoint.y + newRise)
    }
    
    func intersections(with other: DistanceRelationship) -> [CGPoint] {
        var commonNode: ConstructionNode? = nil
        for node in self.nodes {
            if other.contains(node) {
                commonNode = node
                break
            }
        }
        
        guard let commonNode = commonNode else {
            // TODO: Something more productive here
            fatalError()
        }
        
        let selfCenterNode = self.getOtherNode(commonNode)
        let otherCenterNode = other.getOtherNode(commonNode)
        
        guard let selfDistance = self.targetDistance, let otherDistance = other.targetDistance else {
            // TODO: Something smarter here, if one of them has a target distance then return the closest point to the node?
            return []
        }
        
        let centerToCenterDistance = selfCenterNode.cgPoint.distance(to: otherCenterNode.cgPoint)
        guard centerToCenterDistance <= (selfDistance + otherDistance) else {
            return []
        }
        
        // https://gist.github.com/jupdike/bfe5eb23d1c395d8a0a1a4ddd94882ac
        
        let x1 = selfCenterNode.cgPoint.x
        let y1 = selfCenterNode.cgPoint.y
        let r1 = selfDistance
        let x2 = otherCenterNode.cgPoint.x
        let y2 = otherCenterNode.cgPoint.y
        let r2 = otherDistance

        let R = centerToCenterDistance
        let R2 = R * R
        let R4 = R2 * R2

        let a = ((r1 * r1) - (r2 * r2)) / (2.0 * R2)
        let r2r2 = ((r1 * r1) - (r2 * r2))
        let c = sqrt((2.0 * ((r1 * r1) + (r2 * r2)) / R2) - ((r2r2 * r2r2) / R4) - 1.0)

        let fx = ((x1 + x2) / 2.0) + (a * (x2 - x1))
        let gx = (c * (y2 - y1)) / 2.0
        let ix1 = fx + gx
        let ix2 = fx - gx

        let fy = ((y1 + y2) / 2.0) + (a * (y2 - y1))
        let gy = c * (x1 - x2) / 2.0
        let iy1 = fy + gy
        let iy2 = fy - gy

        return [CGPoint(x: ix1, y: iy1), CGPoint(x: ix2, y: iy2)]
    }
}
