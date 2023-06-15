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
        
        let nodeA = self.constructionGraph.createNode(at: CGPoint(x: 300.0, y: 400.0))
        let nodeB = self.constructionGraph.createNode(at: CGPoint(x: 600.0, y: 400.0))
        let captive = self.constructionGraph.createNode(at: CGPoint(x: 450.0, y: 400.0))
        
        let railNode = MetaRailNode(nodeA: nodeA, nodeB: nodeB)
        railNode.add(captiveNode: captive)
        self.metaGraph.add(node: railNode)
        
        let distanceABNode = MetaDistanceNode(nodeA: nodeA, nodeB: nodeB)
        distanceABNode.setMin(to: 300.0)
        distanceABNode.setMax(to: 300.0)
        self.metaGraph.add(node: distanceABNode)
        
        let distanceToANode = MetaDistanceNode(nodeA: nodeA, nodeB: captive)
        distanceToANode.setMax(to: 300.0)
        self.metaGraph.add(node: distanceToANode)
        
        let distanceToBNode = MetaDistanceNode(nodeA: nodeB, nodeB: captive)
        distanceToBNode.setMax(to: 300.0)
        self.metaGraph.add(node: distanceToBNode)
    }
    
    func update(dt: Double) {
        self.metaGraph.update()
        self.constructionGraph.update(dt: dt)
    }
}
