//
//  ContentView.swift
//  3DViewer
//
//  Created by Erick Nungaray on 02/04/24.
import SwiftUI
import SceneKit
import ARKit

struct STLView: UIViewRepresentable {
    var scene: SCNScene?
    var color: UIColor?
    var isARActive: Bool
    
    func makeUIView(context: Context) -> ARSCNView {
        let arView = ARSCNView(frame: .zero)
        let configuration = ARWorldTrackingConfiguration()
        arView.session.run(configuration)
        
        arView.autoenablesDefaultLighting = true
        arView.allowsCameraControl = true
        
        if let safeScene = scene {
            arView.scene = safeScene
        }
        
        arView.backgroundColor = isARActive ? .clear : .white
        
        // Add pinch gesture recognizer
        let pinchGesture = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePinch(_:)))
        arView.addGestureRecognizer(pinchGesture)
        
        return arView
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {
        if let safeScene = scene {
            uiView.scene = safeScene
        }
        uiView.backgroundColor = isARActive ? .clear : .white
    }
    
    private func applyColor(to scene: SCNScene) {
        let colorMaterial = SCNMaterial()
        colorMaterial.diffuse.contents = color
        scene.rootNode.enumerateChildNodes { (node, _) in
            node.geometry?.materials.forEach { material in
                material.diffuse.contents = colorMaterial.diffuse.contents
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var stlView: STLView
        
        init(_ view: STLView) {
            self.stlView = view
        }
        
        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            guard let view = gesture.view as? SCNView else { return }
            let location = gesture.location(in: view)
            let hitResults = view.hitTest(location, options: nil)
            if let hitResult = hitResults.first {
                let node = hitResult.node
                let scale = Float(gesture.scale)
                node.scale = SCNVector3(x: node.scale.x * scale, y: node.scale.y * scale, z: node.scale.z * scale)
                gesture.scale = 1.0  // Reset scale factor to normalize incremental scaling
            }
        }
    }
}

struct ContentView: View {
    @State private var selectedFileIndex: Int = 0
    @State private var scene: SCNScene?
    @State private var showShareSheet: Bool = false
    @State private var selectedColor: Color = .white
    @State private var isARViewActive: Bool = false

    let stlFiles = ["JacksonV2.stl", "MarioSTL.stl", "CopaPiston.stl", "Megaman.stl", "_thomas2.stl", "_guy2.stl", "squirtle.stl", "rocky.stl", "kaws.stl"]

    var body: some View {
        VStack {
            controlBar
            STLView(scene: scene, color: UIColor(selectedColor), isARActive: isARViewActive)
                .edgesIgnoringSafeArea(.all)
        }
    }
    
    var controlBar: some View {
        VStack {
            HStack {
                Button(action: showPreviousModel) {
                    Image(systemName: "arrow.left").padding().background(Color.gray.opacity(0.2)).clipShape(Circle())
                }
                Spacer()
                Picker("Select Model", selection: $selectedFileIndex) {
                    ForEach(stlFiles.indices, id: \.self) { index in
                        Text(stlFiles[index]).tag(index)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding()
                .onChange(of: selectedFileIndex) { newIndex in
                    loadScene(for: newIndex)
                }
                Spacer()
                Button(action: showNextModel) {
                    Image(systemName: "arrow.right").padding().background(Color.gray.opacity(0.2)).clipShape(Circle())
                }
            }
            .padding()

            HStack {
                Button(action: {
                    isARViewActive.toggle()
                }) {
                    Image(systemName: isARViewActive ? "camera.fill" : "camera")
                        .padding()
                        .background(Color.blue.opacity(0.5))
                        .clipShape(Circle())
                }

                Button(action: {
                    showShareSheet = true
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .padding()
                        .background(Color.green.opacity(0.2))
                        .clipShape(Circle())
                        .foregroundColor(.green)
                }
                .sheet(isPresented: $showShareSheet) {
                    ShareSheet(activityItems: [getFileURL()])
                }
                
                ColorPicker("", selection: $selectedColor)
                    .padding()
                    .labelsHidden() // Hide any labels associated with the ColorPicker
            }
        }
    }
    
    private func loadScene(for index: Int) {
        let fileName = stlFiles[index]
        scene = SCNScene(named: fileName)
    }
    
    private func showPreviousModel() {
        selectedFileIndex = selectedFileIndex > 0 ? selectedFileIndex - 1 : stlFiles.count - 1
        loadScene(for: selectedFileIndex)
    }
    
    private func showNextModel() {
        selectedFileIndex = selectedFileIndex < stlFiles.count - 1 ? selectedFileIndex + 1 : 0
        loadScene(for: selectedFileIndex)
    }
    
    private func getFileURL() -> URL {
        guard let fileURL = Bundle.main.url(forResource: stlFiles[selectedFileIndex], withExtension: nil) else {
            fatalError("File not found: \(stlFiles[selectedFileIndex])")
        }
        return fileURL
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [URL]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
