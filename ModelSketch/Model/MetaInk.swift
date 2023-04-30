//
//  MetaInk.swift
//  ModelSketch
//
//  Created by Ben Oztalay on 4/27/23.
//

import Foundation

// circle gesture to open a menu to pick a relationship type
// could have the menu open with a scratch pad next to it to accept a gesture as shorthand

/*
class MetaInkNode {

    static var nextId: Int = 0
    
    static func getNextId() -> Int {
        let id = MetaInkNode.nextId
        MetaInkNode.nextId += 1
        return id
    }

    let id: Int
    private(set) var x: Double
    private(set) var y: Double
    
    var cgPoint: CGPoint {
        return CGPoint(x: self.x, y: self.y)
    }
    
    init() {
        self.id = MetaInkNode.getNextId()
        self.x = 0.0
        self.y = 0.0
    }
    
    static func == (lhs: MetaInkNode, rhs: MetaInkNode) -> Bool {
        return (lhs.id == rhs.id)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
}

// kinda feels like meta ink nodes should contain relationships and organize
//   them from more of a UI perspective, but they're not the relationships
//   themselves (so a node can represent a bidirectional relationship by holding
//   the two unidirectional relationships)
// but then where are one-off relationships stored? separately in MetaInkGraph maybe?
// and how are they connected through the construction ink nodes? maybe move the
//   outgoing relationships list into the relationship class? that way it's more
//   self-contained and the meta and construction ink don't need to worry about it
// meta ink nodes can also organize the relationships, not a huge fan of them
//   being stored in the construction nodes
// also, ditch "Ink" from these class names (e.g. just MetaNode)

class MetaInkRelationshipNode: MetaInkNode {
    
    let nodeIn: ConstructionNode?
    let nodeOut: ConstructionNode
    let priority: MetaInkRelationshipPriority
    let temporary: Bool
    
    init(nodeIn: ConstructionNode?, nodeOut: ConstructionNode, priority: MetaInkRelationshipPriority, temporary: Bool) {
        self.nodeIn = nodeIn
        self.nodeOut = nodeOut
        self.priority = priority
        self.temporary = temporary
    }
}

class MetaInkGraph {
    
    let nodes: [MetaInkNode]
    let constructionGraph: ConstructionGraph
    
    init(constructionGraph: ConstructionGraph) {
        self.nodes = []
        self.constructionGraph = constructionGraph
    }
}
*/
