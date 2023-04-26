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
    case normal    = 2
    
    static func < (lhs: RelationshipPriority, rhs: RelationshipPriority) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

class Relationship: Hashable {
    
    static var nextId: Int = 0
    
    static func getNextId() -> Int {
        let id = Node.nextId
        Node.nextId += 1
        return id
    }

    let id: Int
    let nodeIn: Node?
    let nodeOut: Node
    let priority: RelationshipPriority
    let temporary: Bool
    
    init(nodeIn: Node?, nodeOut: Node, priority: RelationshipPriority, temporary: Bool) {
        self.id = Relationship.getNextId()
        self.nodeIn = nodeIn
        self.nodeOut = nodeOut
        self.priority = priority
        self.temporary = temporary
    }
    
    func propagate() {
        let (affectedX, affectedY) = self.apply()
        
        if affectedX {
            for relationship in self.nodeOut.outgoingRelationshipsX {
                relationship.propagate()
            }
        }
        
        if affectedY {
            for relationship in self.nodeOut.outgoingRelationshipsY {
                relationship.propagate()
            }
        }
    }
    
    func apply() -> (Bool, Bool) {
        fatalError("Need to implement apply")
    }
    
    func contains(_ node: Node) -> Bool {
        if let nodeIn = self.nodeIn {
            if node == nodeIn {
                return true
            }
        }
        
        return (node == self.nodeOut)
    }
    
    static func == (lhs: Relationship, rhs: Relationship) -> Bool {
        return (lhs.id == rhs.id)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
}

class InputRelationship: Relationship {
    
    init(node: Node, priority: RelationshipPriority, temporary: Bool) {
        super.init(nodeIn: nil, nodeOut: node, priority: priority, temporary: temporary)
    }
}

class NodeToNodeRelationship: Relationship {

    init(nodeIn: Node, nodeOut: Node, priority: RelationshipPriority, temporary: Bool) {
        super.init(nodeIn: nodeIn, nodeOut: nodeOut, priority: priority, temporary: temporary)
    }
}

//
// Relationships
//

class AffixRelationship: InputRelationship {
    
    let cgPoint: CGPoint
    
    init(node: Node, cgPoint: CGPoint, priority: RelationshipPriority, temporary: Bool) {
        self.cgPoint = cgPoint
        super.init(node: node, priority: priority, temporary: temporary)
    }
    
    convenience init(node: Node, cgPoint: CGPoint) {
        self.init(node: node, cgPoint: cgPoint, priority: .fixed, temporary: false)
    }

    override func apply() -> (Bool, Bool) {
        return (self.nodeOut.set(x: self.cgPoint.x, with: self),
                self.nodeOut.set(y: self.cgPoint.y, with: self))
    }
}

class FollowPencilRelationship: AffixRelationship {
    
    init(node: Node, cgPoint: CGPoint) {
        super.init(node: node, cgPoint: cgPoint, priority: .userInput, temporary: true)
    }
}

class EqualXXRelationship: NodeToNodeRelationship {
    
    init(nodeIn: Node, nodeOut: Node) {
        super.init(nodeIn: nodeIn, nodeOut: nodeOut, priority: .normal, temporary: false)
        nodeIn.add(outgoingRelationshipX: self)
    }
    
    override func apply() -> (Bool, Bool) {
        return (self.nodeOut.set(x: self.nodeIn!.x, with: self), false)
    }
}

class EqualYYRelationship: NodeToNodeRelationship {
    
    init(nodeIn: Node, nodeOut: Node) {
        super.init(nodeIn: nodeIn, nodeOut: nodeOut, priority: .normal, temporary: false)
        nodeIn.add(outgoingRelationshipY: self)
    }
    
    override func apply() -> (Bool, Bool) {
        return (false, self.nodeOut.set(y: self.nodeIn!.y, with: self))
    }
}

class EqualXYRelationship: NodeToNodeRelationship {
    
    init(nodeIn: Node, nodeOut: Node) {
        super.init(nodeIn: nodeIn, nodeOut: nodeOut, priority: .normal, temporary: false)
        nodeIn.add(outgoingRelationshipX: self)
    }
    
    override func apply() -> (Bool, Bool) {
        return (false, self.nodeOut.set(y: self.nodeIn!.x, with: self))
    }
}

class EqualYXRelationship: NodeToNodeRelationship {
    
    init(nodeIn: Node, nodeOut: Node) {
        super.init(nodeIn: nodeIn, nodeOut: nodeOut, priority: .normal, temporary: false)
        nodeIn.add(outgoingRelationshipY: self)
    }
    
    override func apply() -> (Bool, Bool) {
        return (self.nodeOut.set(x: self.nodeIn!.y, with: self), false)
    }
}

