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

        let nodeA = self.constructionGraph.createNode(at: CGPoint(x: 300.0, y: 300.0))
        self.constructionGraph.add(spring: AffixSpring(node: nodeA, to: nodeA.cgPoint))
        
        let nodeB = self.constructionGraph.createNode(at: CGPoint(x: 400.0, y: 400.0))
        let nodeC = self.constructionGraph.createNode(at: CGPoint(x: 500.0, y: 400.0))
        self.constructionGraph.connect(nodeA: nodeB, nodeB: nodeC)
        self.constructionGraph.add(spring: DistanceSpring(nodeA: nodeB, nodeB: nodeC, distance: 100.0))

        self.update()
    }
    
    func update() {
        self.metaGraph.update()
    }
}
