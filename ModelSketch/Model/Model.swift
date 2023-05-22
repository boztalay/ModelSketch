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
        self.constructionGraph.add(spring: DistanceSpring(nodeA: nodeB, nodeB: nodeC, distance: nodeB.cgPoint.distance(to: nodeC.cgPoint)))
        
        let nodeD = self.constructionGraph.createNode(at: CGPoint(x: 600.0, y: 300.0))
        let nodeE = self.constructionGraph.createNode(at: CGPoint(x: 550.0, y: 400.0))
        let nodeF = self.constructionGraph.createNode(at: CGPoint(x: 650.0, y: 400.0))
        self.constructionGraph.connect(nodeA: nodeD, nodeB: nodeE)
        self.constructionGraph.connect(nodeA: nodeE, nodeB: nodeF)
        self.constructionGraph.connect(nodeA: nodeF, nodeB: nodeD)
        self.constructionGraph.add(spring: DistanceSpring(nodeA: nodeD, nodeB: nodeE, distance: nodeD.cgPoint.distance(to: nodeE.cgPoint)))
        self.constructionGraph.add(spring: DistanceSpring(nodeA: nodeE, nodeB: nodeF, distance: nodeE.cgPoint.distance(to: nodeF.cgPoint)))
        self.constructionGraph.add(spring: DistanceSpring(nodeA: nodeF, nodeB: nodeD, distance: nodeF.cgPoint.distance(to: nodeD.cgPoint)))

        self.update()
    }
    
    func update() {
        self.metaGraph.update()
    }
}
