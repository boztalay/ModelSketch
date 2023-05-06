//
//  Model.swift
//  ModelSketch
//
//  Created by Ben Oztalay on 4/11/23.
//

import Foundation

class Model {
    
    let constructionGraph: ConstructionGraph
    let metaGraph: MetaGraph
    
    init() {
        self.constructionGraph = ConstructionGraph()
        self.metaGraph = MetaGraph(constructionGraph: self.constructionGraph)
        
        let nodeA = self.constructionGraph.createNode()
        let nodeB = self.constructionGraph.createNode()
        let nodeC = self.constructionGraph.createNode()
        let nodeD = self.constructionGraph.createNode()
        
        self.constructionGraph.add(relationship: FollowPencilRelationship(node: nodeA, cgPoint: CGPoint(x: 200.0, y: 200.0)))
        self.constructionGraph.add(relationship: FollowPencilRelationship(node: nodeB, cgPoint: CGPoint(x: 300.0, y: 300.0)))
        self.constructionGraph.add(relationship: FollowPencilRelationship(node: nodeC, cgPoint: CGPoint(x: 400.0, y: 400.0)))
        self.constructionGraph.add(relationship: FollowPencilRelationship(node: nodeD, cgPoint: CGPoint(x: 500.0, y: 500.0)))
        self.update()
        
        let distanceNodeAB = MetaDistanceQuantityNode(nodeA: nodeA, nodeB: nodeB, min: 50.0, max: 150.0)
        self.metaGraph.add(node: distanceNodeAB)
        
        let distanceNodeCD = MetaDistanceQuantityNode(nodeA: nodeC, nodeB: nodeD, minNode: distanceNodeAB, maxNode: distanceNodeAB)
        self.metaGraph.add(node: distanceNodeCD)
        
        self.update()
    }
    
    func update() {
        self.metaGraph.update()
        self.constructionGraph.update()
    }
}
