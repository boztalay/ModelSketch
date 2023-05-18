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
    case inheritedFixed = 1
    case userInput = 2
    case inheritedUserInput = 3
    
    static func < (lhs: RelationshipPriority, rhs: RelationshipPriority) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
    
    var inheritedPriority: RelationshipPriority {
        switch self {
            case .fixed:
                return .inheritedFixed
            case .inheritedFixed:
                return .inheritedFixed
            case .userInput:
                return .inheritedUserInput
            case .inheritedUserInput:
                return .inheritedUserInput
        }
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
    var inheritedPriority: RelationshipPriority?
    
    init(temporary: Bool) {
        self.id = Relationship.getNextId()
        self.temporary = temporary
        self.nodes = []
    }
    
    func propagate(with priority: RelationshipPriority? = nil) {
        if let inheritedPriority = self.inheritedPriority {
            if let priority = priority, priority < inheritedPriority {
                self.inheritedPriority = priority
            }
        } else {
            self.inheritedPriority = priority
        }
        
        guard !self.isSatisfied() else {
            return
        }

        if self.apply() {
            // TODO: Just getting this from nodes.last is a little hacky, could formalize this
            if let nodeOut = self.nodes.last {
                for relationship in nodeOut.outgoingRelationships {
                    relationship.propagate(with: self.inheritedPriority?.inheritedPriority)
                }
            }
        }
    }
    
    func contains(_ node: ConstructionNode) -> Bool {
        return self.nodes.contains(node)
    }
    
    func resetForPropagation() {
        self.inheritedPriority = nil
    }

    func isSatisfied() -> Bool {
        fatalError("isSatisfied must be implemented")
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
    
    let priority: RelationshipPriority
    
    var node: ConstructionNode {
        return self.nodes[0]
    }
    
    init(node: ConstructionNode, priority: RelationshipPriority, temporary: Bool) {
        self.priority = priority
        super.init(temporary: temporary)
        self.nodes.append(node)
    }
    
    func propagateWithPriority() {
        self.propagate(with: self.priority)
    }
    
    override func isSatisfied() -> Bool {
        return false
    }
    
    override func removeFromNodes() {

    }
}

class NodeToNodeRelationship: Relationship {
    
    var nodeIn: ConstructionNode {
        return self.nodes[0]
    }
    
    var nodeOut: ConstructionNode {
        return self.nodes[1]
    }

    init(nodeIn: ConstructionNode, nodeOut: ConstructionNode, temporary: Bool) {
        super.init(temporary: temporary)
        self.nodes.append(nodeIn)
        self.nodes.append(nodeOut)
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
        let couldSetX = self.node.set(x: self.cgPoint.x, with: self)
        let couldSetY = self.node.set(y: self.cgPoint.y, with: self)
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
    var equalRelationship: DistanceRelationship?
    
    var distance: Double {
        return self.nodeIn.cgPoint.distance(to: self.nodeOut.cgPoint)
    }
    
    var targetDistance: Double {
        var targetDistance = self.distance
        
        if let equalRelationship = self.equalRelationship, equalRelationship.inheritedPriority != nil {
            targetDistance = equalRelationship.distance
        } else {
            if let min = self.min, self.distance < min {
                targetDistance = min
            }
            
            if let max = self.max, self.distance > max {
                targetDistance = max
            }
        }
        
        return targetDistance
    }
    
    var error: Double {
        return self.targetDistance - self.distance
    }
    
    init(nodeIn: ConstructionNode, nodeOut: ConstructionNode, min: Double? = nil, max: Double? = nil) {
        if let min = min, let max = max {
            if min > max {
                fatalError("min (\(min)) must be less than max (\(max))")
            }
        }
        
        self.min = min
        self.max = max

        super.init(nodeIn: nodeIn, nodeOut: nodeOut, temporary: false)
        
        self.nodeIn.addOutgoingRelationship(self)
    }
    
    func setEqualRelationship(_ other: DistanceRelationship) {
        self.equalRelationship = other
        self.equalRelationship!.nodeIn.addOutgoingRelationship(self)
    }
    
    override func isSatisfied() -> Bool {
        return abs(self.error) < 0.1
    }
    
    override func apply() -> Bool {
        // TODO: Use the canSet functions here
        let newDistance = (self.error * 0.50) + self.distance
        
        let run = self.nodeOut.cgPoint.x - self.nodeIn.cgPoint.x
        let rise = self.nodeOut.cgPoint.y - self.nodeIn.cgPoint.y
        let angle = atan2(rise, run)
        
        let newRun = newDistance * cos(angle)
        let newRise = newDistance * sin(angle)
        
        let couldSetX = self.nodeOut.set(x: self.nodeIn.cgPoint.x + newRun, with: self)
        let couldSetY = self.nodeOut.set(y: self.nodeIn.cgPoint.y + newRise, with: self)
        return (couldSetX || couldSetY)
    }
    
    override func removeFromNodes() {
        self.nodeIn.removeRelationship(self)
        self.equalRelationship?.nodeIn.removeRelationship(self)
    }
}
