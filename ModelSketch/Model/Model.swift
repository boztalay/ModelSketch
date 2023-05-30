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
        
        let nodeA = self.constructionGraph.createNode(at: CGPoint(x: 400.0, y: 300.0))
        let nodeB = self.constructionGraph.createNode(at: CGPoint(x: 400.0, y: 400.0))
        let pivot = self.constructionGraph.createNode(at: CGPoint(x: 300.0, y: 400.0))
        
        self.constructionGraph.connect(nodeA: pivot, nodeB: nodeA)
        self.constructionGraph.connect(nodeA: pivot, nodeB: nodeB)
        
        self.metaGraph.add(node: MetaAngleNode(nodeA: nodeA, nodeB: nodeB, pivot: pivot, angleInDegrees: 45.0))
    }
    
    func update(dt: Double) {
        self.metaGraph.update()
        self.constructionGraph.update(dt: dt)
    }
}
