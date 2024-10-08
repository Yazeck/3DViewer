//
//  DocumentPicker.swift
//  3DViewer
//
//  Created by AdminMac on 25/09/24.
//

import SwiftUI
import UniformTypeIdentifiers

struct DocumentPicker: UIViewControllerRepresentable {
    @Binding var stlFiles: [URL]

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType(filenameExtension: "stl")!], asCopy: true)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self, saveFileToDocumentsDirectory)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var parent: DocumentPicker
        var saveFile: (String, Data) -> URL?

        init(_ parent: DocumentPicker, _ saveFile: @escaping (String, Data) -> URL?) {
            self.parent = parent
            self.saveFile = saveFile
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            
            // Guarda el archivo seleccionado en el Document Directory
            if let savedURL = saveFile(url.lastPathComponent, try! Data(contentsOf: url)) {
                parent.stlFiles.append(savedURL)
            }
        }
    }

    // Función para guardar el archivo en el Document Directory
    func saveFileToDocumentsDirectory(fileName: String, fileData: Data) -> URL? {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        let fileURL = documentsDirectory?.appendingPathComponent(fileName)
        
        do {
            try fileData.write(to: fileURL!)
            return fileURL
        } catch {
            print("Error guardando el archivo: \(error)")
            return nil
        }
    }
}
    // Función para guardar el archivo en el directorio de documentos
    func saveFileToDocumentsDirectory(fileName: String, fileData: Data) -> URL? {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        let fileURL = documentsDirectory?.appendingPathComponent(fileName)
        
        do {
            try fileData.write(to: fileURL!)
            return fileURL
        } catch {
            print("Error guardando el archivo: \(error)")
            return nil
        }
    }

