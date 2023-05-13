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
    
    func propagate() {
        if self.apply() {
            // TODO: Just getting this from nodes.last is a little hacky, could formalize this
            if let nodeOut = self.nodes.last {
                for relationship in nodeOut.relationships {
                    relationship.propagate()
                }
            }
        }
    }
    
    func contains(_ node: ConstructionNode) -> Bool {
        return self.nodes.contains(node)
    }

    func apply() -> Bool {
        fatalError("apply must be implemented")
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
            node.addRelationship(self)
        }
    }

    func removeFromNodes() {
        for node in self.nodes {
            node.removeRelationship(self)
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

    override func apply() -> Bool {
        // TODO: Use the canSet functions here?
        let couldSetX = self.node.set(x: self.cgPoint.x)
        let couldSetY = self.node.set(y: self.cgPoint.y)
        return (couldSetX || couldSetY)
    }
}

class FollowPencilRelationship: AffixRelationship {
    
    init(node: ConstructionNode, cgPoint: CGPoint) {
        super.init(node: node, cgPoint: cgPoint, priority: .userInput, temporary: true)
    }
}

class DistanceRelationship: NodeToNodeRelationship {
    
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
    
    override func apply() -> Bool {
        // TODO: Use the canSet functions here?

        var targetDistance = self.distance
        
        if let min = self.min, self.distance < min {
            targetDistance = min
        }
        
        if let max = self.max, self.distance > max {
            targetDistance = max
        }
        
        let run = self.nodeB.cgPoint.x - self.nodeA.cgPoint.x
        let rise = self.nodeB.cgPoint.y - self.nodeA.cgPoint.y
        let angle = atan2(rise, run)
        
        let newRun = targetDistance * cos(angle)
        let newRise = targetDistance * sin(angle)
        
        let couldSetX = self.nodeB.set(x: self.nodeA.cgPoint.x + newRun)
        let couldSetY = self.nodeB.set(y: self.nodeA.cgPoint.y + newRise)
        return (couldSetX || couldSetY)
    }
}
