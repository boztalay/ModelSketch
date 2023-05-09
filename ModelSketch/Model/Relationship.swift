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
    case normal    = 1
    case userInput = 2
    
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
    let nodeIn: ConstructionNode?
    let nodeOut: ConstructionNode
    let priority: RelationshipPriority
    let temporary: Bool
    
    init(nodeIn: ConstructionNode?, nodeOut: ConstructionNode, priority: RelationshipPriority, temporary: Bool) {
        self.id = Relationship.getNextId()
        self.nodeIn = nodeIn
        self.nodeOut = nodeOut
        self.priority = priority
        self.temporary = temporary
    }
    
    func propagate() {
        if self.apply() {
            for relationship in self.nodeOut.outgoingRelationships {
                relationship.propagate()
            }
        }
    }
    
    func contains(_ node: ConstructionNode) -> Bool {
        if let nodeIn = self.nodeIn {
            if node == nodeIn {
                return true
            }
        }
        
        return (node == self.nodeOut)
    }

    func apply() -> Bool {
        fatalError("apply must be implemented")
    }
    
    func removeFromNodes() {
        fatalError("removeFromNodes must be implemented")
    }
    
    static func == (lhs: Relationship, rhs: Relationship) -> Bool {
        return (lhs.id == rhs.id)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
}

class InputRelationship: Relationship {
    
    init(node: ConstructionNode, priority: RelationshipPriority, temporary: Bool) {
        super.init(nodeIn: nil, nodeOut: node, priority: priority, temporary: temporary)
    }
    
    override func removeFromNodes() {

    }
}

class NodeToNodeRelationship: Relationship {

    init(nodeIn: ConstructionNode, nodeOut: ConstructionNode, priority: RelationshipPriority, temporary: Bool) {
        super.init(nodeIn: nodeIn, nodeOut: nodeOut, priority: priority, temporary: temporary)
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
        // TODO: Use the canSet functions here
        let couldSetX = self.nodeOut.set(x: self.cgPoint.x, with: self)
        let couldSetY = self.nodeOut.set(y: self.cgPoint.y, with: self)
        return (couldSetX || couldSetY)
    }
}

class FollowPencilRelationship: AffixRelationship {
    
    init(node: ConstructionNode, cgPoint: CGPoint) {
        super.init(node: node, cgPoint: cgPoint, priority: .userInput, temporary: true)
    }
}

class DistanceRelationship: NodeToNodeRelationship {
    
    let min: Double?
    let max: Double?
    let minRelationship: DistanceRelationship?
    let maxRelationship: DistanceRelationship?
    
    var distance: Double {
        return self.nodeIn!.cgPoint.distance(to: self.nodeOut.cgPoint)
    }
    
    var minDistance: Double? {
        return self.minRelationship?.distance ?? self.min
    }
    
    var maxDistance: Double? {
        return self.maxRelationship?.distance ?? self.max
    }
    
    init(nodeIn: ConstructionNode, nodeOut: ConstructionNode, min: Double? = nil, max: Double? = nil, minRelationship: DistanceRelationship? = nil, maxRelationship: DistanceRelationship? = nil) {
        guard min == nil || minRelationship == nil else {
            fatalError("Can't have both min and minRelationship set")
        }
        
        guard max == nil || maxRelationship == nil else {
            fatalError("Can't have both max and maxRelationship set")
        }
        
        if let min = min, let max = max {
            if min > max {
                fatalError("min (\(min)) must be less than max (\(max))")
            }
        }
        
        self.min = min
        self.max = max
        self.minRelationship = minRelationship
        self.maxRelationship = maxRelationship

        super.init(nodeIn: nodeIn, nodeOut: nodeOut, priority: .normal, temporary: false)
        
        self.nodeIn!.addOutgoingRelationship(self)
        
        if let minRelationship = self.minRelationship {
            minRelationship.nodeIn!.addOutgoingRelationship(self)
        }
        
        if let maxRelationship = self.maxRelationship {
            maxRelationship.nodeIn!.addOutgoingRelationship(self)
        }
    }
    
    override func apply() -> Bool {
        // TODO: Use the canSet functions here

        var targetDistance = self.distance
        
        if let min = self.minDistance, self.distance < min {
            targetDistance = min
        }
        
        if let max = self.maxDistance, self.distance > max {
            targetDistance = max
        }
        
        let run = self.nodeOut.cgPoint.x - self.nodeIn!.cgPoint.x
        let rise = self.nodeOut.cgPoint.y - self.nodeIn!.cgPoint.y
        let angle = atan2(rise, run)
        
        let newRun = targetDistance * cos(angle)
        let newRise = targetDistance * sin(angle)
        
        let couldSetX = self.nodeOut.set(x: self.nodeIn!.cgPoint.x + newRun, with: self)
        let couldSetY = self.nodeOut.set(y: self.nodeIn!.cgPoint.y + newRise, with: self)
        return (couldSetX || couldSetY)
    }
    
    
    override func removeFromNodes() {
        self.nodeIn!.removeRelationship(self)
        
        if let minRelationship = self.minRelationship {
            minRelationship.nodeIn!.removeRelationship(self)
        }
        
        if let maxRelationship = self.maxRelationship {
            maxRelationship.nodeIn!.removeRelationship(self)
        }
    }
}
