//
//  GesturesView.swift
//  ModelSketch
//
//  Created by Ben Oztalay on 4/18/23.
//

import SwiftUI

struct GesturesView: View {
    
    enum TrainableGesture: String, CaseIterable, Identifiable {
        case create = "Create 'O'"
        case delete1 = "Delete 'X' 1"
        case delete2 = "Delete 'X' 2"
        var id: Self { self }
    }
    
    @State private var selectedGesture = TrainableGesture.create
    
    var body: some View {
        HStack {
            RepresentedPencilStrokeView()
            Form {
                Picker("Gesture to Train", selection: $selectedGesture) {
                    ForEach(TrainableGesture.allCases) { gesture in
                        Text(gesture.rawValue)
                    }
                }.pickerStyle(.menu)
                HStack {
                    Spacer()
                    Button(action: saveImages) {
                        Text("Save Images")
                    }
                    Spacer()
                }
            }.frame(width: 350.0)
        }
    }
    
    func saveImages() {
        
    }
}

struct GesturesView_Previews: PreviewProvider {
    static var previews: some View {
        GesturesView()
    }
}
