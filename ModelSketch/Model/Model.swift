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
        
        for i in 0 ..< 10 {
            let node = self.constructionGraph.createNode()
            self.constructionGraph.add(inputRelationship: FollowPencilRelationship(node: node, cgPoint: CGPoint(x: 200.0 + (CGFloat(i) * 50.0), y: 300.0)))
        }
        
        self.update()
    }
    
    func update() {
        self.metaGraph.update()
        self.constructionGraph.update()
    }
}
