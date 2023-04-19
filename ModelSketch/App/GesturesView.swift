//
//  GesturesView.swift
//  ModelSketch
//
//  Created by Ben Oztalay on 4/18/23.
//

import SwiftUI

struct LabeledStroke {
    let stroke: PencilStroke
    let label: PencilGesture
}

struct GesturesView: View {
    
    @State private var selectedGesture = PencilGesture.create
    @State private var strokeImage = UIImage(systemName: "pencil.line")!
    @State private var labeledStrokes = [LabeledStroke]()
    
    var body: some View {
        HStack {
            RepresentedGestureTrainerView(strokeCompletion: strokeCompletion)
            Form {
                HStack{
                    Spacer()
                    Image(uiImage: strokeImage).frame(width: 100.0, height: 100.0).aspectRatio(contentMode: .fit)
                    Spacer()
                }
                Picker("Gesture to Train", selection: $selectedGesture) {
                    ForEach(PencilGesture.allCases) { gesture in
                        Text(gesture.friendlyName)
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
    
    func strokeCompletion(_ stroke: PencilStroke) {
        guard let image = stroke.renderImage() else {
            return
        }

        self.strokeImage = image
        self.labeledStrokes.append(LabeledStroke(stroke: stroke, label: self.selectedGesture))
    }
    
    func saveImages() {
        for labeledStroke in self.labeledStrokes {
            guard let image = labeledStroke.stroke.renderImage() else {
                continue
            }
            
            let data = image.pngData()!
            let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let directoryUrl = documentsUrl.appending(component: "labeled_gestures").appending(component: labeledStroke.label.rawValue)
            try! FileManager.default.createDirectory(at: directoryUrl, withIntermediateDirectories: true)
            let fileUrl = directoryUrl.appending(path: UUID().uuidString).appendingPathExtension("png")
            try! data.write(to: fileUrl)
        }
        
        self.labeledStrokes = []
    }
}

struct GesturesView_Previews: PreviewProvider {
    static var previews: some View {
        GesturesView()
    }
}
