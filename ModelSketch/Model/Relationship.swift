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

    case fixed           = 0
    case userInteraction = 1
    case normal          = 2
    
    static func < (lhs: RelationshipPriority, rhs: RelationshipPriority) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

class Relationship {

    let priority: RelationshipPriority
    let temporary: Bool
    
    init(priority: RelationshipPriority, temporary: Bool) {
        self.priority = priority
        self.temporary = temporary
    }
    
    func apply() {
        fatalError("Need to implement apply")
    }
    
    func contains(_ node: Node) -> Bool {
        fatalError("Need to implement contains")
    }
}

class SingleNodeRelationship: Relationship {
    
    let node: Node
    
    init(node: Node, priority: RelationshipPriority, temporary: Bool) {
        self.node = node
        super.init(priority: priority, temporary: temporary)
    }
    
    override func contains(_ node: Node) -> Bool {
        return (self.node == node)
    }
}

class NodeToNodeRelationship: Relationship {
    
    let nodeIn: Node
    let nodeOut: Node
    
    init(nodeIn: Node, nodeOut: Node, priority: RelationshipPriority, temporary: Bool) {
        self.nodeIn = nodeIn
        self.nodeOut = nodeOut
        super.init(priority: priority, temporary: temporary)
    }
    
    override func contains(_ node: Node) -> Bool {
        return (self.nodeIn == node || self.nodeOut == node)
    }
}

//
// Relationships
//

class AffixRelationship: SingleNodeRelationship {
    
    let cgPoint: CGPoint
    
    init(node: Node, cgPoint: CGPoint, temporary: Bool) {
        self.cgPoint = cgPoint
        super.init(node: node, priority: .fixed, temporary: temporary)
    }
    
    convenience init(node: Node, cgPoint: CGPoint) {
        self.init(node: node, cgPoint: cgPoint, temporary: false)
    }
    
    override func apply() {
        self.node.set(x: self.cgPoint.x, with: self)
        self.node.set(y: self.cgPoint.y, with: self)
    }
}

class TemporaryAffixRelationship: AffixRelationship {
    
    init(node: Node, cgPoint: CGPoint) {
        super.init(node: node, cgPoint: cgPoint, temporary: true)
    }
}

class EqualXRelationship: NodeToNodeRelationship {
    
    init(nodeIn: Node, nodeOut: Node) {
        super.init(nodeIn: nodeIn, nodeOut: nodeOut, priority: .normal, temporary: false)
    }
    
    override func apply() {
        self.nodeOut.set(x: self.nodeIn.x, with: self)
    }
}

class EqualYRelationship: NodeToNodeRelationship {
    
    init(nodeIn: Node, nodeOut: Node) {
        super.init(nodeIn: nodeIn, nodeOut: nodeOut, priority: .normal, temporary: false)
    }
    
    override func apply() {
        self.nodeOut.set(y: self.nodeIn.y, with: self)
    }
}
