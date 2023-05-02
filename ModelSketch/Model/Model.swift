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
        
        self.constructionGraph.add(relationship: FollowPencilRelationship(node: nodeA, cgPoint: CGPoint(x: 200.0, y: 200.0)))
        self.constructionGraph.add(relationship: FollowPencilRelationship(node: nodeB, cgPoint: CGPoint(x: 300.0, y: 300.0)))
        self.constructionGraph.update()
        
        self.constructionGraph.add(relationship: DistanceRelationship(nodeIn: nodeA, nodeOut: nodeB, min: 50.0, max: 150.0))
        self.constructionGraph.add(relationship: DistanceRelationship(nodeIn: nodeB, nodeOut: nodeA, min: 50.0, max: 150.0))
        self.constructionGraph.add(relationship: AffixRelationship(node: nodeB, cgPoint: CGPoint(x: 300.0, y: 300.0)))
        self.constructionGraph.update()
    }
    
    func update() {
        self.metaGraph.update()
        self.constructionGraph.update()
    }
}
