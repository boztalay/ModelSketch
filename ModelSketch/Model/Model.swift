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

        var nodes = [ConstructionNode]()
        for i in 0 ..< 10 {
            let node = self.constructionGraph.createNode()
            if i == 0 {
                self.constructionGraph.add(inputRelationship: AffixRelationship(node: node, cgPoint: CGPoint(x: 200.0 + (CGFloat(i) * 50.0), y: 300.0)))
            } else {
                self.constructionGraph.add(inputRelationship: FollowPencilRelationship(node: node, cgPoint: CGPoint(x: 200.0 + (CGFloat(i) * 50.0), y: 300.0)))
            }
            nodes.append(node)
        }
        
        self.constructionGraph.update()
        
        for i in 0 ..< (nodes.count - 1) {
            self.constructionGraph.connect(nodeA: nodes[i], nodeB: nodes[i + 1])
            self.constructionGraph.add(nodeToNodeRelationship: DistanceRelationship(nodeA: nodes[i], nodeB: nodes[i + 1], min: 50.0, max: 50.0))
        }

        self.update()
    }
    
    func update() {
        self.metaGraph.update()
        self.constructionGraph.update()
    }
}
