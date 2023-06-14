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
        let captive1 = self.constructionGraph.createNode(at: CGPoint(x: 300.0, y: 325.0))
        let captive2 = self.constructionGraph.createNode(at: CGPoint(x: 300.0, y: 350.0))
        let captive3 = self.constructionGraph.createNode(at: CGPoint(x: 300.0, y: 375.0))
        
        let railNode = MetaRailNode(nodeA: nodeA, nodeB: nodeB)
        railNode.add(captiveNode: captive1)
        railNode.add(captiveNode: captive2)
        railNode.add(captiveNode: captive3)
        self.metaGraph.add(node: railNode)
    }
    
    func update(dt: Double) {
        self.metaGraph.update()
        self.constructionGraph.update(dt: dt)
    }
}
