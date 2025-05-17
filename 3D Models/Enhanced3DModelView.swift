//
//  Enhanced3DModelView.swift
//  GrooveMusic
//
//  Created by Student on 4/9/25.
//
import SwiftUI
import SceneKit

struct Enhanced3DModelView: UIViewRepresentable {
    let modelName: String
    var audioAnalysis: [String: Double]
    @EnvironmentObject var dataStore: MusicDataStore
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> SCNView {
        let sceneView = SCNView(frame: .zero)
        sceneView.backgroundColor = .clear
        sceneView.autoenablesDefaultLighting = true
        sceneView.allowsCameraControl = false
        
        // Set up scene
        let scene = SCNScene()
        sceneView.scene = scene
        
        //  camera
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(0, 0.5, 4)
        scene.rootNode.addChildNode(cameraNode)
        
        //  lighting
        setupLighting(in: scene)
        
        // Initial model load
        let initialModelName = self.modelName
        _ = loadModel(sceneView: sceneView, modelName: initialModelName)
        context.coordinator.currentModelName = initialModelName
        context.coordinator.sceneView = sceneView
        
        return sceneView
    }
    
    //  updateUIView to include isPlaying state
    func updateUIView(_ uiView: SCNView, context: Context) {
        // Update model based on audio analysis with playing state
        var updatedAnalysis = audioAnalysis
        updatedAnalysis["isPlaying"] = dataStore.audioPlayerService.isPlaying ? 1.0 : 0.0
        context.coordinator.updateWithAudio(updatedAnalysis)
    }
    
    private func setupLighting(in scene: SCNScene) {
        // Ambient light
        let ambientLight = SCNLight()
        ambientLight.type = .ambient
        ambientLight.intensity = 1000
        let ambientLightNode = SCNNode()
        ambientLightNode.light = ambientLight
        scene.rootNode.addChildNode(ambientLightNode)
        
        // Directional light
        let directions = [
            SCNVector3(1, 2, 1),
            SCNVector3(-1, 2, -1),
            SCNVector3(0, 3, 0)
        ]
        
        for direction in directions {
            let directionalLight = SCNLight()
            directionalLight.type = .directional
            directionalLight.intensity = 1500
            
            let directionalLightNode = SCNNode()
            directionalLightNode.light = directionalLight
            directionalLightNode.position = direction
            directionalLightNode.eulerAngles = SCNVector3(-Float.pi/4, Float.pi/4, 0)
            scene.rootNode.addChildNode(directionalLightNode)
        }
    }
    
    private func loadModel(sceneView: SCNView, modelName: String) -> SCNNode? {
        print("3D View - Loading model: \(modelName)")
        
        // Clear existing nodes
        sceneView.scene?.rootNode.childNodes.forEach {
            if $0.camera == nil {  // Don't remove camera
                $0.removeFromParentNode()
            }
        }
        
        // URL for the model
        guard let url = Model3D.urlForModelName(modelName) else {
            print("Could not find URL for model: \(modelName)")
            return nil
        }
        
        print("Loading model from URL: \(url.lastPathComponent)")
        
        do {
            let scene = try SCNScene(url: url, options: [
                SCNSceneSource.LoadingOption.animationImportPolicy: SCNSceneSource.AnimationImportPolicy.playRepeatedly,
                SCNSceneSource.LoadingOption.createNormalsIfAbsent: true,
                SCNSceneSource.LoadingOption.checkConsistency: true,
                SCNSceneSource.LoadingOption.flattenScene: true,
                SCNSceneSource.LoadingOption.convertToYUp: true
            ])
            
            // Root node
            var rootNode: SCNNode?
            
            // Root node with children
            if let firstNode = scene.rootNode.childNodes.first {
                rootNode = firstNode
                print("Found first node for model: \(modelName)")
            }
            
            // no node found
            if rootNode == nil {
                print("No root node found for model: \(modelName)")
                return nil
            }
            
            // Configure node with scale
            rootNode?.scale = SCNVector3(0.015, 0.015, 0.015)
            rootNode?.position = SCNVector3(0, -1.2, 0)
            
            // Add to scene
            sceneView.scene?.rootNode.addChildNode(rootNode!)
            
            return rootNode
            
        } catch {
            print("Error loading model: \(modelName), error: \(error.localizedDescription)")
            return nil
        }
    }
    
    
    class Coordinator: NSObject {
        var parent: Enhanced3DModelView
        var sceneView: SCNView?
        var modelNode: SCNNode?
        var currentModelName: String?
        var animationPlaying: Bool = true
        private var lastModelChangeTime: TimeInterval = 0
        private let minChangeInterval: TimeInterval = 5.0 // 5 seconds for less frequent changes
        private var intensityBuffer: [Double] = []
        private let bufferSize = 15 // Increased buffer size for smoother transitions
        private var currentSection: String = "normal"
        
        init(_ parent: Enhanced3DModelView) {
            self.parent = parent
            self.currentModelName = parent.modelName
        }
        
        
        func updateWithAudio(_ audioAnalysis: [String: Double]) {
            
            //changing model after minimum interval
            let currentTime = Date().timeIntervalSince1970
            if (currentTime - lastModelChangeTime) < minChangeInterval {
                return
            }
            
            // intensity for smoother transitions
            let bass = audioAnalysis["bass"] ?? 0.0
            let beat = audioAnalysis["beat"] ?? 0.0
            intensityBuffer.append((bass * 0.7) + (beat * 0.3))
            if intensityBuffer.count > bufferSize {
                intensityBuffer.removeFirst()
            }
            
            // change model with sufficient samples
            if intensityBuffer.count >= bufferSize / 2 {
                let avgIntensity = intensityBuffer.reduce(0, +) / Double(intensityBuffer.count)
                let genre = parent.dataStore.audioPlayerService.currentTrack?.genre ?? "Hip-Hop"
                
                let newModelName = Model3D.getModelNameBasedOnBeat(
                    ["bass": avgIntensity,
                     "beat": avgIntensity,
                     "sectionType": audioAnalysis["sectionType"] ?? 0.0],
                    genre: genre
                )
                
                // Only change if model is different
                if newModelName != currentModelName {
                    currentModelName = newModelName
                    lastModelChangeTime = currentTime
                    intensityBuffer.removeAll()
                    
                    guard let sceneView = sceneView else { return }
                    performModelChangeWithFade(to: newModelName, in: sceneView)
                }
            }
        }
        
        
        private func getSectionNameFromHash(_ hashValue: Double?) -> String {
            guard let hashValue = hashValue else { return "verse" }
            
            let sections = ["intro", "verse", "chorus", "bridge", "outro"]
            let hash = Int(hashValue)
            
            for section in sections {
                if section.hashValue == hash {
                    return section
                }
            }
            return "verse" // Default
        }
        
        
        
        private func performModelChangeWithFade(to newModelName: String, in sceneView: SCNView) {
            print("Starting fade transition to model: \(newModelName)")
            
            // If no current model, load directly
            if modelNode == nil {
                modelNode = parent.loadModel(sceneView: sceneView, modelName: newModelName)
                return
            }
            
            guard let oldNode = modelNode else { return }
            
            // Create fade sequence
            let fadeOut = SCNAction.fadeOut(duration: 0.2)
            let remove = SCNAction.removeFromParentNode()
            let sequence = SCNAction.sequence([fadeOut, remove])
            
            // Run on old node
            oldNode.runAction(sequence)
            
            // Load new model
            DispatchQueue.main.asyncAfter(deadline: .now()) { [weak self] in
                guard let self = self else { return }
                
                let newNode = parent.loadModel(sceneView: sceneView, modelName: newModelName)
                newNode?.opacity = 0
                self.modelNode = newNode
                let fadeIn = SCNAction.fadeIn(duration: 0.2)
                newNode?.runAction(fadeIn)
            }
        }
    }
}

extension SCNNode {
    func getPresentationCopy() -> CAAnimation? {
        
        let animation = CABasicAnimation(keyPath: "transform")
        animation.fromValue = NSValue(scnMatrix4: SCNMatrix4Identity)
        animation.toValue = NSValue(scnMatrix4: self.transform)
        animation.duration = 0.5
        return animation
        
    }
}
