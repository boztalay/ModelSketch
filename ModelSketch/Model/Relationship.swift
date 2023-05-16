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
    
    func apply() {
        fatalError("apply must be implemented")
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
    
    func propagate() {
        self.apply()

        let relationships = self.gatherAllRelationships(from: self.node)

        var iterations = 0
        while !self.areAllSatisfied(relationships) {
            for relationship in relationships.filter({ !$0.isSatisfied() }).map({ $0 as! DistanceRelationship }).sorted(by: { $0.getError() > $1.getError() }) {
                relationship.apply()
            }
            iterations += 1
        }
        print("\(iterations) iterations")
    }
    
    private func gatherAllRelationships(from node: ConstructionNode, existingRelationships: Set<NodeToNodeRelationship>? = nil) -> Set<NodeToNodeRelationship> {
        var relationships = Set<NodeToNodeRelationship>()
        
        if let existingRelationships = existingRelationships {
            relationships.formUnion(existingRelationships)
        }
        
        for relationship in node.relationships {
            guard !relationships.contains(relationship) else {
                continue
            }

            relationships.insert(relationship)
            let otherNode = relationship.getOtherNode(node)
            relationships.formUnion(self.gatherAllRelationships(from: otherNode, existingRelationships: relationships))
        }
        
        return relationships
    }
    
    private func areAllSatisfied(_ relationships: Set<NodeToNodeRelationship>) -> Bool {
        return relationships.map({ $0.isSatisfied() }).reduce(true, { $0 && $1 })
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
    
    static let epsilon = 0.05
    static let errorProportionPerApplication = 0.90
    
    var min: Double?
    var max: Double?
    
    var distance: Double {
        return self.nodeA.cgPoint.distance(to: self.nodeB.cgPoint)
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
            return false
        }
        
        if let max = self.max, self.distance > (max + DistanceRelationship.epsilon) {
            return false
        }
        
        return true
    }
    
    func getError() -> Double {
        var targetDistance = self.distance
        
        if let min = self.min, self.distance < min {
            targetDistance = min
        }
        
        if let max = self.max, self.distance > max {
            targetDistance = max
        }
        
        return targetDistance - self.distance
    }
    
    override func apply() {
        var targetDistance = self.distance
        
        if let min = self.min, self.distance < min {
            targetDistance = min
        }
        
        if let max = self.max, self.distance > max {
            targetDistance = max
        }
        
        var startNode = self.nodeA
        var endNode = self.nodeB
        
        if !endNode.canMove() || ((startNode.moveCount < endNode.moveCount) && startNode.canMove()) {
            let temp = startNode
            startNode = endNode
            endNode = temp
        }
        
        guard endNode.canMove() else {
            // TODO: Something more productive here
            fatalError()
        }
        
        let run = endNode.cgPoint.x - startNode.cgPoint.x
        let rise = endNode.cgPoint.y - startNode.cgPoint.y
        let angle = atan2(rise, run)
        
        let error = targetDistance - self.distance
        let distanceToApply = (error * DistanceRelationship.errorProportionPerApplication) + self.distance
        let newRun = distanceToApply * cos(angle)
        let newRise = distanceToApply * sin(angle)
        
        endNode.move(to: CGPoint(x: startNode.cgPoint.x + newRun, y: startNode.cgPoint.y + newRise))
    }
}
