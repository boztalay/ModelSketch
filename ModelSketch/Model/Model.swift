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
        
        self.constructionGraph.connect(nodeA: nodeA, nodeB: nodeB)
        self.constructionGraph.connect(nodeA: nodeB, nodeB: nodeC)
        self.constructionGraph.connect(nodeA: nodeC, nodeB: nodeD)
        
        self.constructionGraph.add(relationship: AffixRelationship(node: nodeA, cgPoint: CGPoint(x: 300.0, y: 300.0)))
        self.constructionGraph.add(relationship: FollowPencilRelationship(node: nodeB, cgPoint: CGPoint(x: 400.0, y: 300.0)))
        self.constructionGraph.add(relationship: FollowPencilRelationship(node: nodeC, cgPoint: CGPoint(x: 500.0, y: 300.0)))
        self.constructionGraph.add(relationship: FollowPencilRelationship(node: nodeD, cgPoint: CGPoint(x: 600.0, y: 300.0)))
        
        self.update()
        
        let abDistance = DistanceRelationship(nodeIn: nodeA, nodeOut: nodeB, min: 100, max: 100)
        let baDistance = DistanceRelationship(nodeIn: nodeB, nodeOut: nodeA, min: 100, max: 100)
        let bcDistance = DistanceRelationship(nodeIn: nodeB, nodeOut: nodeC, min: 100, max: 100)
        let cbDistance = DistanceRelationship(nodeIn: nodeC, nodeOut: nodeB, min: 100, max: 100)
        let cdDistance = DistanceRelationship(nodeIn: nodeC, nodeOut: nodeD, min: 100, max: 100)
        let dcDistance = DistanceRelationship(nodeIn: nodeD, nodeOut: nodeC, min: 100, max: 100)

        self.constructionGraph.add(relationship: abDistance)
        self.constructionGraph.add(relationship: baDistance)
        self.constructionGraph.add(relationship: bcDistance)
        self.constructionGraph.add(relationship: cbDistance)
        self.constructionGraph.add(relationship: cdDistance)
        self.constructionGraph.add(relationship: dcDistance)
        
        self.update()
    }
    
    func update() {
        self.metaGraph.update()
        self.constructionGraph.update()
    }
}
