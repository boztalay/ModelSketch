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
        
        self.constructionGraph.add(inputRelationship: FollowPencilRelationship(node: nodeA, cgPoint: CGPoint(x: 300.0, y: 300.0)))
        self.constructionGraph.add(inputRelationship: FollowPencilRelationship(node: nodeB, cgPoint: CGPoint(x: 400.0, y: 300.0)))
        self.constructionGraph.add(inputRelationship: FollowPencilRelationship(node: nodeC, cgPoint: CGPoint(x: 400.0, y: 400.0)))
        self.constructionGraph.add(inputRelationship: FollowPencilRelationship(node: nodeD, cgPoint: CGPoint(x: 300.0, y: 400.0)))
        
        self.update()
    }
    
    func update() {
        self.metaGraph.update()
        self.constructionGraph.update()
    }
}
