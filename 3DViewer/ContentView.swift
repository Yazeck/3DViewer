// Created by Erick Nungaray on 02/04/24
import SwiftUI
import SceneKit
import UniformTypeIdentifiers

struct STLView: UIViewRepresentable {
    var scene: SCNScene?
    var modelColor: UIColor?
    
    func makeUIView(context: Context) -> SCNView {
        let sceneView = SCNView(frame: .zero)
        sceneView.autoenablesDefaultLighting = true
        sceneView.allowsCameraControl = true  // Habilita el control de cámara por gestos
        
        if let safeScene = scene {
            sceneView.scene = safeScene
            adjustModelScale(sceneView: sceneView, scaleFactor: 1.5)  // Aplicar el factor de escala
            applyModelColor(scene: safeScene, color: modelColor)  // Aplicar color al modelo
        }
        
        sceneView.backgroundColor = .white
        return sceneView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {
        if let safeScene = scene {
            uiView.scene = safeScene
            adjustModelScale(sceneView: uiView, scaleFactor: 1.0)  // Aplicar el factor de escala
            applyModelColor(scene: safeScene, color: modelColor)  // Aplicar color al modelo
        }
        uiView.backgroundColor = .white
    }
    
    // Ajustar la escala del modelo
    private func adjustModelScale(sceneView: SCNView, scaleFactor: Float) {
        let rootNode = sceneView.scene?.rootNode  // No necesita ser opcional
        rootNode?.scale = SCNVector3(scaleFactor, scaleFactor, scaleFactor)
    }
    
    // Aplicar color al modelo
    private func applyModelColor(scene: SCNScene, color: UIColor?) {
        let rootNode = scene.rootNode  // No es necesario hacer un guard let, directamente asignamos
        rootNode.enumerateChildNodes { (node, _) in
            node.geometry?.firstMaterial?.diffuse.contents = color  // Cambiar el color del modelo
        }
    }
}

struct ContentView: View {
    @State private var selectedFileIndex: Int = 0
    @State private var scene: SCNScene?
    @State private var selectedColor: Color = .white  // Este es el color del modelo
    @State private var stlFiles: [URL] = []
    @State private var showingDocumentPicker = false
    @State private var isLoading: Bool = false  // Indica si se está cargando un modelo

    var body: some View {
        VStack {
            controlBar
            STLView(scene: scene, modelColor: UIColor(selectedColor))
                .edgesIgnoringSafeArea(.all)
            if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(2)  // Cambiar el tamaño del indicador de carga
                        }
        }
        .onAppear(perform: loadFilesFromDirectory)  // Cargar archivos al iniciar la app
        .sheet(isPresented: $showingDocumentPicker) {
            DocumentPicker(stlFiles: $stlFiles)
        }
    }

    var controlBar: some View {
        VStack {
            HStack {
                Button(action: showPreviousModel) {
                    Image(systemName: "arrow.left")
                        .padding()
                        .background(buttonColor)
                        .clipShape(Circle())
                }
                Spacer()
                Menu {
                    Picker(selection: $selectedFileIndex, label: EmptyView()) {
                        ForEach(stlFiles.indices, id: \.self) { index in
                            Text(stlFiles[index].lastPathComponent).tag(index)
                        }
                    }
                } label: {
                    Text("Select Model")  // Siempre muestra "Select Model" cuando está cerrado
                        .padding()
                        .background(buttonColor)
                        .clipShape(Capsule())
                }
                .pickerStyle(MenuPickerStyle())
                //.padding()
                .onChange(of: selectedFileIndex) { newIndex in
                    loadScene(for: newIndex)
                }
                Spacer()
                Button(action: showNextModel) {
                    Image(systemName: "arrow.right")
                        .padding()
                        .background(buttonColor)
                        .clipShape(Circle())
                }
            }
            .padding()

            HStack {
                ColorPicker("", selection: $selectedColor)
                    .padding()
                    .labelsHidden()
                    .onChange(of: selectedColor) { _ in
                        if let currentScene = scene {
                            scene = currentScene  // Forzar actualización de la escena para cambiar color
                        }
                    }

                Button(action: {
                    showingDocumentPicker = true
                }) {
                    Image(systemName: "folder")
                        .padding()
                        .background(buttonColor)
                        .clipShape(Circle())
                }

                if !stlFiles.isEmpty {
                    Button(action: {
                        if let firstFile = stlFiles.first {
                            shareFile(fileURL: firstFile)
                        }
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .padding()
                            .background(buttonColor)
                            .clipShape(Circle())
                    }
                }
            }
        }
    }

      
    @State private var buttonColor: Color = .black

    private func loadScene(for index: Int) {
        guard index >= 0 && index < stlFiles.count else {
            print("Invalid index: \(index)")
            return
        }

        isLoading = true  // Mostrar el indicador de carga
        
        let fileURL = stlFiles[index]
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let loadedScene = try SCNScene(url: fileURL, options: nil)
                DispatchQueue.main.async {
                    self.scene = loadedScene
                    self.isLoading = false  // Ocultar el indicador de carga
                }
            } catch {
                print("Failed to load scene: \(error)")
                DispatchQueue.main.async {
                    self.isLoading = false  // Asegurarse de que desaparezca el indicador si hay error
                }
            }
        }
    }

    private func showPreviousModel() {
        guard !stlFiles.isEmpty else { return }
        selectedFileIndex = selectedFileIndex > 0 ? selectedFileIndex - 1 : stlFiles.count - 1
        loadScene(for: selectedFileIndex)
    }

    private func showNextModel() {
        guard !stlFiles.isEmpty else { return }
        selectedFileIndex = selectedFileIndex < stlFiles.count - 1 ? selectedFileIndex + 1 : 0
        loadScene(for: selectedFileIndex)
    }

    private func shareFile(fileURL: URL) {
        let activityViewController = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
        if let topController = UIApplication.shared.windows.first?.rootViewController {
            topController.present(activityViewController, animated: true, completion: nil)
        }
    }

    private func loadFilesFromDirectory() {
        // Obtener la ruta del directorio de documentos
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first

        do {
            if let documentsDirectory = documentsDirectory {
                let urls = try fileManager.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil)
                
                // Filtrar archivos STL
                let stlURLs = urls.filter { $0.pathExtension.lowercased() == "stl" }
                stlFiles = stlURLs
                
                // Cargar el primer modelo por defecto
                if !stlFiles.isEmpty {
                    loadScene(for: 0)
                }
            }
        } catch {
            print("Error al cargar archivos desde el directorio: \(error)")
        }
    }
}
