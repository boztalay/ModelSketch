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
        self.constructionGraph.add(spring: ConstructionSpring(stiffness: 0.1, dampingCoefficient: 0.1, pointA: nodeA.cgPoint, nodeB: nodeA, freeLength: 0.0))

        self.update()
    }
    
    func update() {
        self.metaGraph.update()
        self.constructionGraph.update()
    }
}
