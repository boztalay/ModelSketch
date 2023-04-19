//
//  GesturesView.swift
//  ModelSketch
//
//  Created by Ben Oztalay on 4/18/23.
//

import SwiftUI

enum TrainableGesture: String, CaseIterable, Identifiable {
    var id: Self { self }
    
    case create
    case delete1
    case delete2
    
    var friendlyName: String {
        switch self {
            case .create:
                return "Create 'O'"
            case .delete1:
                return "Delete 'X' 1"
            case .delete2:
                return "Delete 'X' 2"
        }
    }
}

struct LabeledImage {
    let image: UIImage
    let label: TrainableGesture
    let date: Date
    
    init(image: UIImage, label: TrainableGesture) {
        self.image = image
        self.label = label
        self.date = Date()
    }
}

struct GesturesView: View {
    
    @State private var selectedGesture = TrainableGesture.create
    @State private var strokeImage = UIImage(systemName: "pencil.line")!
    @State private var images = [LabeledImage]()
    
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
                    ForEach(TrainableGesture.allCases) { gesture in
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
    
    func strokeCompletion(_ image: UIImage) {
        strokeImage = image
        self.images.append(LabeledImage(image: image, label: self.selectedGesture))
    }
    
    func saveImages() {
        for image in self.images {
            let data = image.image.pngData()!
            let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let directoryUrl = documentsUrl.appending(component: "labeled_gestures").appending(component: image.label.rawValue)
            try! FileManager.default.createDirectory(at: directoryUrl, withIntermediateDirectories: true)
            let fileUrl = directoryUrl.appending(path: UUID().uuidString).appendingPathExtension("png")
            try! data.write(to: fileUrl)
        }
        
        self.images = []
    }
}

struct GesturesView_Previews: PreviewProvider {
    static var previews: some View {
        GesturesView()
    }
}
