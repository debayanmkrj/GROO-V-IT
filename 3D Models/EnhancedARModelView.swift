//
//  EnhancedARModelView.swift
//  GrooveMusic
//
//  Created by Student on 4/9/25.
//
import SwiftUI
import RealityKit
import ARKit
import Combine

struct EnhancedARModelView: View {
    let track: Track
    @EnvironmentObject var dataStore: MusicDataStore
    @Environment(\.dismiss) private var dismiss
    @State private var modelScale: Float = 0.25
    @State private var audioAnalysis: [String: Double] = [:]
    @State private var modelsPlaced: Bool = false
    @Binding var currentModelName: String
    @State private var currentProgress: Double = 0
    @State private var progressTimer: Timer? = nil
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // AR View
            EnhancedARViewContainer(
                track: track,
                dataStore: dataStore,
                modelScale: $modelScale,
                audioAnalysis: audioAnalysis,
                modelsPlaced: $modelsPlaced,
                currentModelName: $currentModelName
            )
            .edgesIgnoringSafeArea(.all)
            
            // Overlay controls
            VStack {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title3)
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Text(modelsPlaced ? "Dancer placed" : "Tap to place dancer")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(10)
                    
                    Spacer()
                }
                .padding()
                
                Spacer()
                
                // Model size slider
                HStack {
                    Image(systemName: "person.fill")
                        .foregroundColor(.white)
                    
                    Slider(value: $modelScale, in: 0.03...0.5)
                        .accentColor(.accent)
                    
                    Image(systemName: "person.fill.viewfinder")
                        .foregroundColor(.white)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.6))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.bottom, 10)
                
                // Bottom playback controls
                EnhancedARPlaybackControlsView(track: track)
                    .environmentObject(dataStore)
                    .padding(.bottom, 30)
            }
        }
        .onAppear {
            // Timer to update audio analysis
            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                if let analysis = dataStore.getAnalysisFor(track: track, at: dataStore.audioPlayerService.currentTime) {
                    audioAnalysis = analysis
                }
            }
        }
    }
}

// Enhanced AR View Container
struct EnhancedARViewContainer: UIViewRepresentable {
    let track: Track
    let dataStore: MusicDataStore
    @Binding var modelScale: Float
    var audioAnalysis: [String: Double]
    @Binding var modelsPlaced: Bool
    @Binding var currentModelName: String
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        // Configure AR session for horizontal plane detection
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        
        // Reduce memory usage
        config.frameSemantics = []
        if let frameRate = ARWorldTrackingConfiguration.supportedVideoFormats.first {
            config.videoFormat = frameRate
        }
        
        // Start session
        arView.session.run(config)
        setupLighting(for: arView)
        // Overlay to help users find surfaces
        let coachingOverlay = ARCoachingOverlayView()
        coachingOverlay.session = arView.session
        coachingOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        coachingOverlay.goal = .horizontalPlane
        arView.addSubview(coachingOverlay)
        
        // Set up tap gesture for placing model
        let tapGesture = UITapGestureRecognizer(target: context.coordinator,
                                                action: #selector(Coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tapGesture)
        
        // Set the coordinator's arView
        context.coordinator.arView = arView
        context.coordinator.setup()
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        // Update dancer with audio analysis
        if modelsPlaced {
            context.coordinator.updateWithAudio(audioAnalysis)
        }
        
        // Update model scale when changed
        context.coordinator.updateModelScale(modelScale)
    }
    
    private func setupLighting(for arView: ARView) {
        // anchor for our lights
        let lightAnchor = AnchorEntity()
        arView.scene.addAnchor(lightAnchor)
        
        //  environment lighting
        arView.environment.lighting.intensityExponent = 1.0
        //Point light
        let pointLight = Entity()
        var lightComponent = PointLightComponent()
        lightComponent.intensity = 1000
        lightComponent.color = .white
        pointLight.components.set(lightComponent)
        pointLight.position = [0, 1, 0]
        lightAnchor.addChild(pointLight)
        
        // Directional light entity
        let directionalLight = Entity()
        var dirLightComponent = DirectionalLightComponent()
        dirLightComponent.intensity = 1500
        dirLightComponent.color = .white
        directionalLight.components.set(dirLightComponent)
        directionalLight.position = [1, 2, 1]
        directionalLight.look(at: [0, 0, 0], from: directionalLight.position, relativeTo: nil)
        lightAnchor.addChild(directionalLight)
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    
    class Coordinator: NSObject {
        var parent: EnhancedARViewContainer // Fixed: EnhancedARViewContainer instead of EnhancedARModelView
        var arView: ARView?
        var anchorEntity: AnchorEntity?
        var dancerEntity: ModelEntity?
        var hasBeenPlaced: Bool = false
        var currentScale: Float = 0.02
        var isLoading: Bool = false
        var currentModelName: String?
        private var lastModelChangeTime: TimeInterval = 0
        private let minChangeInterval: TimeInterval = 3.0
        private var intensityBuffer: [Double] = []
        private let bufferSize = 10
        private var currentSection: String = "verse"
        
        // Cancellable set for async loading
        private var cancellables = Set<AnyCancellable>()
        
        init(_ parent: EnhancedARViewContainer) {
            self.parent = parent
            self.currentScale = parent.modelScale * 0.05
            self.currentModelName = "Female_HH_7" // Default model
            
        }
        
        // Debug helper to check available models
        private func checkAvailableModels() {
            let allModels = Bundle.main.paths(forResourcesOfType: "usdz", inDirectory: nil)
            print("==== AR VIEW - AVAILABLE MODELS ====")
            allModels.forEach {
                print("Model: \(URL(fileURLWithPath: $0).lastPathComponent)")
            }
            
            // Check specifically for Biker models
            let bikerModels = allModels.filter {
                URL(fileURLWithPath: $0).lastPathComponent.lowercased().contains("biker")
            }
            
            if bikerModels.isEmpty {
                print("WARNING: No Biker models found in bundle for AR View!")
            } else {
                print("Found Biker models for AR: \(bikerModels.map { URL(fileURLWithPath: $0).lastPathComponent })")
            }
        }
        
        // Update dancer with audio analysis
        func updateWithAudio(_ audioAnalysis: [String: Double]) {
            // Check after minimum interval has passed
            let currentTime = Date().timeIntervalSince1970
            if (currentTime - lastModelChangeTime) < minChangeInterval {
                return
            }
            
            // Add to intensity buffer
            let bass = audioAnalysis["bass"] ?? 0.0
            let beat = audioAnalysis["beat"] ?? 0.0
            intensityBuffer.append((bass * 0.7) + (beat * 0.3))
            if intensityBuffer.count > bufferSize {
                intensityBuffer.removeFirst()
            }
            
            // Change model with sufficient samples
            if intensityBuffer.count >= 5 {
                let avgIntensity = intensityBuffer.reduce(0, +) / Double(intensityBuffer.count)
                let genre = parent.track.genre
                
                // Use centralized model selection
                let newModelName = Model3D.getModelNameBasedOnBeat(
                    ["bass": avgIntensity,
                     "beat": avgIntensity,
                     "sectionType": audioAnalysis["sectionType"] ?? 0.0],
                    genre: genre
                )
                
                // Change if model name changed
                if newModelName != currentModelName {
                    currentModelName = newModelName
                    parent.currentModelName = newModelName
                    lastModelChangeTime = currentTime
                    intensityBuffer.removeAll()
                    
                    if let position = anchorEntity?.position {
                        loadModelWithFade(at: position, modelName: newModelName)
                    }
                }
            }
        }
        
        func updateModelScale(_ scale: Float) {
            // Small scale factor for proper AR sizing
            self.currentScale = scale * 0.05
            
            // Update dancer scale if it exists
            if let dancerEntity = dancerEntity {
                dancerEntity.scale = [currentScale, currentScale, currentScale]
            }
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let arView = arView else { return }
            
            let tapLocation = gesture.location(in: arView)
            let results = arView.raycast(from: tapLocation,
                                         allowing: .estimatedPlane,
                                         alignment: .horizontal)
            
            if let firstResult = results.first {
                // Get hit position
                let worldPosition = firstResult.worldTransform.columns.3
                let position = SIMD3<Float>(
                    worldPosition.x,
                    worldPosition.y + 0.001, // Slightly above surface
                    worldPosition.z
                )
                
                // Place or move model
                if !hasBeenPlaced {
                    placeDancerModel(at: position)
                    parent.modelsPlaced = true
                    hasBeenPlaced = true
                } else {
                    // Move existing model
                    moveModel(to: position)
                }
            }
        }
        
        func placeDancerModel(at position: SIMD3<Float>) {
            let anchor = AnchorEntity(world: position)
            arView?.scene.addAnchor(anchor)
            anchorEntity = anchor
            
            isLoading = true
            
            // Get the current track genre
            let genre = parent.track.genre
            
            //Default model name based on genre
            let modelName = genre.lowercased() == "pop" ? "Biker_Swing_Dancing" : "Female_HH_7"
            currentModelName = modelName
            
            loadModel(at: position, modelName: modelName)
        }
        
        func loadModel(at position: SIMD3<Float>, modelName: String? = nil) {
            
            let modelToLoad = modelName ?? currentModelName ?? "Female_HH_7"
            
            // Get URL for the model
            guard let modelURL = Model3D.urlForModelName(modelToLoad) else {
                print("AR View - Could not find model: \(modelToLoad)")
                isLoading = false
                return
            }
            
            print("AR View - Loading model: \(modelToLoad) from URL: \(modelURL.lastPathComponent)")
            
            // Cancel any previous loading operations
            cancellables.removeAll()
            
            // Use the new async/await pattern with Task
            Task {
                do {
                    
                    let entity = try await ModelEntity(contentsOf: modelURL)
                    await MainActor.run {
                        guard anchorEntity != nil else {
                            isLoading = false
                            return
                        }
                        
                        // Configure the loaded entity
                        configureLoadedEntity(entity, at: position, modelName: modelToLoad)
                    }
                } catch {
                    print("AR View - Error loading model: \(error)")
                    
                }
            }
        }
        
        private func configureLoadedEntity(_ entity: ModelEntity, at position: SIMD3<Float>, modelName: String) {
            guard let anchor = anchorEntity else {
                isLoading = false
                return
            }
            
            // Remove existing models
            anchor.children.forEach { $0.removeFromParent() }
            
            // Configure entity
            entity.scale = [currentScale, currentScale, currentScale]
            dancerEntity = entity
            
            // Model orient toward camera
            if let arView = arView {
                let cameraPosition = arView.cameraTransform.translation
                
                let modelToCameraDirection = normalize(SIMD3<Float>(
                    cameraPosition.x - position.x,
                    0,
                    cameraPosition.z - position.z
                ))
                
                // Calculate the angle
                _ = atan2(modelToCameraDirection.x, modelToCameraDirection.z)
                
                // Create quaternion with rotation around y-axis
                entity.orientation = simd_quatf(angle: Float.pi, axis: [0, 1, 0])
                
                // Apply additional 180-degree rotation to face directly toward the camera
                let rotationTransform = Transform(pitch: 0, yaw: Float.pi, roll: 0)
                entity.transform.rotation = simd_mul(entity.transform.rotation, rotationTransform.rotation)
            }
            
            // Add to scene and play animations
            anchor.addChild(entity)
            
            if let animController = entity.availableAnimations.first {
                entity.playAnimation(animController.repeat())
            }
            
            isLoading = false
        }
        
        func moveModel(to position: SIMD3<Float>) {
            guard let arView = arView, let dancerEntity = dancerEntity else { return }
            
            // Remove existing anchor
            if let oldAnchor = anchorEntity {
                oldAnchor.removeFromParent()
            }
            
            // Create new anchor at the position
            let anchor = AnchorEntity(world: position)
            arView.scene.addAnchor(anchor)
            
            let cameraPosition = arView.cameraTransform.translation
            let direction = normalize(SIMD3<Float>(
                cameraPosition.x - position.x,
                0, // Keep level on y-axis
                cameraPosition.z - position.z
            ))
            
            _ = atan2(direction.x, direction.z) + Float.pi
            dancerEntity.orientation = simd_quatf(angle: Float.pi, axis: [0, 1, 0])
            
            // Move to new anchor
            anchor.addChild(dancerEntity)
            anchorEntity = anchor
        }
        
        
        func loadModelWithFade(at position: SIMD3<Float>, modelName: String? = nil) {
            let modelToLoad = modelName ?? currentModelName ?? "Female_HH_7"
            
            print("AR View - Loading model: \(modelToLoad)")
            
            // Get URL for the model with fallback handling
            guard let modelURL = Model3D.urlForModelName(modelToLoad) else {
                print("AR View - Could not find model: \(modelToLoad)")
                isLoading = false
                return
            }
            
            print("AR View - Found model URL: \(modelURL.lastPathComponent)")
            
            // Save reference to current entity
            let oldEntity = dancerEntity
            
            // Load the new model
            isLoading = true
            
            Task {
                do {
                    let entity = try await ModelEntity(contentsOf: modelURL)
                    
                    // Run UI updates on the main thread
                    await MainActor.run {
                        guard anchorEntity != nil else {
                            isLoading = false
                            return
                        }
                        
                        print("AR View - Received loaded model entity")
                        
                        // Configure the entity - this adds it to the anchor
                        configureLoadedEntity(entity, at: position, modelName: modelToLoad)
                        
                        // Remove old entity
                        oldEntity?.removeFromParent()
                    }
                } catch {
                    await MainActor.run {
                        print("AR View - Error loading model: \(error)")
                        isLoading = false
                    }
                }
            }
        }
        
        func setup() {
            // Check available models after a delay for transition
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.checkAvailableModels()
            }
        }
    }
}

// AR Playback controls
struct EnhancedARPlaybackControlsView: View {
    let track: Track
    @EnvironmentObject var dataStore: MusicDataStore
    @State private var isPlaying: Bool = false
    @State private var currentProgress: Double = 0
    @State private var progressTimer: Timer? = nil
    
    var body: some View {
        VStack(spacing: 10) {
            // Track info
            HStack {
                track.artwork
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 50, height: 50)
                    .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(track.title)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(track.artist)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Audio visualization indicator
                HStack(spacing: 2) {
                    ForEach(0..<5) { i in
                        Rectangle()
                            .fill(Color.accent)
                            .frame(width: 3, height: CGFloat(10 + Int.random(in: 5...30)))
                            .cornerRadius(1.5)
                            .opacity(dataStore.audioPlayerService.isPlaying ? 1.0 : 0.5)
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: dataStore.audioPlayerService.isPlaying)
                .padding(.trailing, 8)
            }
            .padding(.horizontal)
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 4)
                    
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.accent, .secondaryAccent],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * CGFloat(currentProgress), height: 4)
                }
            }
            .frame(height: 4)
            .padding(.horizontal)
            
            // Playback controls
            HStack(spacing: 40) {
                Button {
                    dataStore.audioPlayerService.skipToNextOrPrevious(tracks: dataStore.allTracks, forward: false)
                } label: {
                    Image(systemName: "backward.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                }
                
                Button {
                    dataStore.audioPlayerService.togglePlayPause()
                    isPlaying.toggle()
                } label: {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.accent)
                }
                
                Button {
                    dataStore.audioPlayerService.skipToNextOrPrevious(tracks: dataStore.allTracks, forward: true)
                } label: {
                    Image(systemName: "forward.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                }
            }
            .padding(.vertical, 5)
        }
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.7))
        .cornerRadius(15)
        .padding(.horizontal)
        .onAppear {
            // Initialize with current playback state
            isPlaying = dataStore.audioPlayerService.isPlaying
            currentProgress = dataStore.audioPlayerService.progress
            startProgressTimer()
        }
        .onDisappear {
            progressTimer?.invalidate()
        }
        .onChange(of: dataStore.audioPlayerService.isPlaying) { oldValue, newValue in
            // Update when the actual playback state changes
            isPlaying = newValue
        }
    }
    
    // Add this method to keep progress updated in real-time
    private func startProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            currentProgress = dataStore.audioPlayerService.progress
        }
    }
}
