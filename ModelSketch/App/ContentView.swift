//
//  ContentView.swift
//  ModelSketch
//
//  Created by Ben Oztalay on 4/10/23.
//

import SwiftUI

struct ContentView: View {
    
    enum Screen: String, CaseIterable {
        case sketch = "Sketch"
        case gestures = "Gestures"
    }
    
    @State private var selection: Screen? = .sketch
    @State private var columnVisibility = NavigationSplitViewVisibility.detailOnly
    @State private var drawingMode: SketchView.DrawingMode = .construction
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            List(Screen.allCases, id: \.self, selection: $selection) { screen in
                NavigationLink(screen.rawValue, value: screen)
            }
            .listStyle(.sidebar)
            .navigationTitle("Model Sketch")
        } detail: {
            switch self.selection {
                case .sketch:
                    ZStack {
                        RepresentedSketchView(drawingMode: $drawingMode).ignoresSafeArea().navigationTitle("")
                        HStack {
                            Spacer()
                            VStack {
                                Spacer()
                                Picker("Drawing Mode", selection: $drawingMode) {
                                    ForEach(SketchView.DrawingMode.allCases) { drawingMode in
                                        Text(drawingMode.friendlyName)
                                    }
                                }.pickerStyle(.menu)
                            }
                        }
                    }
                case .gestures:
                    GestureTrainerView().navigationTitle("Gesture Trainer")
                case .none:
                    Text("No Selection")
            }
        }.onChange(of: selection) { _ in
            columnVisibility = .detailOnly
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
