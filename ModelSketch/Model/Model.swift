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
        
        let angleNodeA = self.constructionGraph.createNode(at: CGPoint(x: 371.0, y: 229.0))
        let angleNodeB = self.constructionGraph.createNode(at: CGPoint(x: 400.0, y: 300.0))
        let angleNodePivot = self.constructionGraph.createNode(at: CGPoint(x: 300.0, y: 300.0))
        self.constructionGraph.add(spring: AffixSpring(node: angleNodePivot, to: angleNodePivot.cgPoint))
        
        let anglePivotBDistanceNode = MetaDistanceNode(nodeA: angleNodePivot, nodeB: angleNodeB)
        anglePivotBDistanceNode.setMin(to: 50.0)
        anglePivotBDistanceNode.setMax(to: 150.0)
        self.metaGraph.add(node: anglePivotBDistanceNode)
        
        let anglePivotADistanceNode = MetaDistanceNode(nodeA: angleNodePivot, nodeB: angleNodeA)
        anglePivotADistanceNode.setMin(to: anglePivotBDistanceNode)
        anglePivotADistanceNode.setMax(to: anglePivotBDistanceNode)
        self.metaGraph.add(node: anglePivotADistanceNode)
        
        let distanceNodeA = self.constructionGraph.createNode(at: CGPoint(x: 300.0, y: 350.0))
        let distanceNodeB = self.constructionGraph.createNode(at: CGPoint(x: 345.0, y: 350.0))
        let distanceABNode = MetaDistanceNode(nodeA: distanceNodeA, nodeB: distanceNodeB)
        self.metaGraph.add(node: distanceABNode)
        
        let angleNode = MetaAngleNode(nodeA: angleNodeA, nodeB: angleNodeB, pivot: angleNodePivot)
        angleNode.setMin(to: distanceABNode)
        angleNode.setMax(to: distanceABNode)
        self.metaGraph.add(node: angleNode)
        
        let railNodeA = self.constructionGraph.createNode(at: CGPoint(x: 250.0, y: 450.0))
        let railNodeB = self.constructionGraph.createNode(at: CGPoint(x: 450.0, y: 450.0))
        let railNodeCaptive = self.constructionGraph.createNode(at: CGPoint(x: 350.0, y: 450.0))
        
        let railNode = MetaRailNode(nodeA: railNodeA, nodeB: railNodeB)
        railNode.add(captiveNode: railNodeCaptive)
        self.metaGraph.add(node: railNode)

        let railABDistanceNode = MetaDistanceNode(nodeA: railNodeA, nodeB: railNodeB)
        railABDistanceNode.setMin(to: 200.0)
        railABDistanceNode.setMax(to: 200.0)
        self.metaGraph.add(node: railABDistanceNode)
    }
    
    func update(dt: Double) {
        self.metaGraph.update()
        self.constructionGraph.update(dt: dt)
    }
}
