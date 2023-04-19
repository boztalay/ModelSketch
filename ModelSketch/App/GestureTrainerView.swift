//
//  GestureTrainerView.swift
//  ModelSketch
//
//  Created by Ben Oztalay on 4/18/23.
//

import SwiftUI

struct LabeledStroke {
    let stroke: PencilStroke
    let label: PencilGesture
}

struct GestureTrainerView: View {
    
    @State private var selectedGesture = PencilGesture.create
    @State private var labeledStrokes = [LabeledStroke]()
    
    var body: some View {
        GeometryReader { metrics in
            HStack {
                RepresentedGestureView(strokeCompletion: strokeCompletion)
                Form {
                    ZStack {
                        HStack{
                            Spacer()
                            let image = self.labeledStrokes.last?.stroke.image ?? UIImage(systemName: "pencil.line")!
                            Image(uiImage: image).frame(maxWidth: 100.0, maxHeight: 100.0).aspectRatio(contentMode: .fit).clipped()
                            Spacer()
                        }
                        HStack {
                            Spacer()
                            if self.labeledStrokes.count > 0 {
                                VStack {
                                    Button(action: discardImage) {
                                        Image(systemName: "trash")
                                    }.padding(.top, 10.0)
                                    Spacer()
                                }
                            }
                        }
                    }
                    Picker("Gesture to Train", selection: $selectedGesture) {
                        ForEach(PencilGesture.allCases) { gesture in
                            Text(gesture.friendlyName)
                        }
                    }.pickerStyle(.menu)
                    HStack {
                        Spacer()
                        Button(action: saveImages) {
                            if self.labeledStrokes.count == 0 {
                                Text("Draw a Gesture!")
                            } else if self.labeledStrokes.count == 1 {
                                Text("Save Image")
                            } else {
                                Text("Save \(self.labeledStrokes.count) Images")
                            }
                        }.disabled(self.labeledStrokes.count == 0)
                        Spacer()
                    }
                }
                .frame(width: metrics.size.width * 0.30)
            }
        }
    }
    
    func strokeCompletion(_ stroke: PencilStroke) {
        guard stroke.image != nil else {
            return
        }
        
        self.labeledStrokes.append(LabeledStroke(stroke: stroke, label: self.selectedGesture))
    }
    
    func discardImage() {
        guard self.labeledStrokes.count > 0 else {
            return
        }
        
        self.labeledStrokes.removeLast()
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
        GestureTrainerView()
    }
}
