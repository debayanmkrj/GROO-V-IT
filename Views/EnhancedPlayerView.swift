//
//  EnhancedPlayerView.swift
//  GrooveMusic
//
//  Created by Student on 3/19/25.
//
import SwiftUI

struct EnhancedPlayerView: View {
    @State var track: Track
    @EnvironmentObject private var dataStore: MusicDataStore
    @Environment(\.dismiss) private var dismiss
    @State private var sourceTabIndex: Int = 0
    
    @State private var isVisualizerActive = true
    @State private var volume: Double = 0.8
    @State private var isScrubbing = false
    @State private var scrubPosition: Double = 0
    @State private var showARView = false
    @State private var selectedModel = Model3D.samples.first!
    @State private var showModelPicker = false
    @State private var audioAnalysis: [String: Double] = [:]
    @State private var currentModelInfo: String = "Waiting for analysis..."
    @State public var currentModelName: String = "Female_HH_7"
    @State private var isFavorite: Bool = false
    @State private var isPlaying: Bool = false
    
    @State private var analysisTimer: Timer? = nil
    
    private var playerService: AudioPlayerService {
        dataStore.audioPlayerService
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.background, Color(hex: "080808")]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                
                ZStack(alignment: .topTrailing) {
                    // 3D model view
                    ZStack {
                        // Album artwork as background
                        track.artwork
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 300, height: 300)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .blur(radius: 3)
                            .opacity(0.6)
                        
                        // 3D model dancer
                        Enhanced3DModelView(
                            modelName: currentModelName,
                            audioAnalysis: audioAnalysis
                        )
                        .frame(width: 300, height: 300)
                    }
                    .frame(width: 300, height: 300)
                    .background(Color.cardBackground)
                    .cornerRadius(20)
                    .shadow(color: .black.opacity(0.4), radius: 10)
                }
                .frame(width: 300, height: 300)
                .padding(.top, 20)
                
                // Track info
                VStack(spacing: 8) {
                    Text(track.title)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text(track.artist)
                        .font(.title3)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                
                // Buttons row
                HStack(spacing: 20) {
                    // Favorite button
                    Button {
                        
                        dataStore.toggleFavorite(track)
                        
                        isFavorite.toggle()
                    } label: {
                        HStack {
                            Image(systemName: isFavorite ? "heart.fill" : "heart")
                        }
                        .foregroundColor(isFavorite ? .accent : .white)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color.cardBackground.opacity(0.5))
                        .cornerRadius(20)
                    }
                    
                    // AR mode button
                    Button {
                        showARView = true
                    } label: {
                        HStack {
                            Image(systemName: "arkit")
                            Text("AR Mode")
                        }
                        .foregroundColor(.white)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color.cardBackground.opacity(0.5))
                        .cornerRadius(20)
                    }
                }
                
                // Progress bar
                VStack(spacing: 8) {
                    // Time labels
                    HStack {
                        Text(formatTime(isScrubbing ? scrubPosition * track.duration : playerService.currentTime))
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        Text(formatTime(track.duration))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    // Slider
                    Slider(
                        value: isScrubbing ? $scrubPosition : Binding(
                            get: { playerService.progress },
                            set: { playerService.seekToPercent($0) }
                        ),
                        in: 0...1,
                        onEditingChanged: { editing in
                            isScrubbing = editing
                            if !editing {
                                playerService.seekToPercent(scrubPosition)
                            }
                        }
                    )
                    .tint(.accent)
                    
                    .onChange(of: playerService.progress) { _, newValue in
                        if !isScrubbing {
                            scrubPosition = newValue
                        }
                    }
                }
                .padding(.horizontal)
                
                // Playback controls
                HStack(spacing: 40) {
                    // Previous button
                    Button {
                        playerService.skipToNextOrPrevious(tracks: dataStore.allTracks, forward: false)
                    } label: {
                        Image(systemName: "backward.fill")
                            .font(.title)
                            .foregroundColor(.white)
                    }
                    
                    // Play/Pause button
                    Button {
                        playerService.togglePlayPause()
                        isPlaying.toggle()
                    } label: {
                        Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 65))
                            .foregroundColor(.accent)
                    }
                    
                    // Next button
                    Button {
                        playerService.skipToNextOrPrevious(tracks: dataStore.allTracks, forward: true)
                    } label: {
                        Image(systemName: "forward.fill")
                            .font(.title)
                            .foregroundColor(.white)
                    }
                }
                .padding(.vertical, 10)
                
                // Volume slider
                HStack(spacing: 15) {
                    Image(systemName: "speaker.fill")
                        .foregroundColor(.gray)
                    
                    Slider(value: $volume, in: 0...1)
                        .tint(.accent)
                        .onChange(of: volume) { oldValue, newValue in
                            playerService.setVolume(Float(newValue))
                        }
                    
                    Image(systemName: "speaker.wave.3.fill")
                        .foregroundColor(.gray)
                }
                .padding(.horizontal)
                
                Spacer(minLength: 20)
            }
            .padding(.top, 40)
            .padding(.horizontal)
        }
        .overlay(alignment: .topTrailing) {
            // Dismiss button
            Button {
                print("Dismissing player, returning to tab: \(sourceTabIndex)")
                dismiss()
                navigateToTab(index: sourceTabIndex)
            } label: {
                Image(systemName: "chevron.down")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.8))
                    .padding()
            }
        }
        .onAppear {
            // Store the current tab index when the view appears
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootViewController = window.rootViewController,
               let tabBarController = rootViewController.children.first as? UITabBarController {
                tabBarController.selectedIndex = 0
                print("EnhancedPlayerView detected source tab: \(sourceTabIndex)")
            }
            
            // Initialize state from current track
            setupAnalysisTimer()
            volume = Double(playerService.volume)
            
            if let currentTrack = dataStore.audioPlayerService.currentTrack {
                track = currentTrack
            }
            
            isFavorite = track.isFavorite
            isPlaying = playerService.isPlaying
        }
        .onDisappear {
            analysisTimer?.invalidate()
        }
        
        .onChange(of: dataStore.audioPlayerService.currentTrack) { _, newTrack in
            if let newTrack = newTrack {
                track = newTrack
                
                isFavorite = newTrack.isFavorite
            }
        }
        
        .onChange(of: dataStore.favoriteTracks) { _, _ in
            // Find the current track in allTracks and update the local isFavorite state
            if let updatedTrack = dataStore.allTracks.first(where: { $0.id == track.id }) {
                isFavorite = updatedTrack.isFavorite
            }
        }
        
        .fullScreenCover(isPresented: $showARView) {
            EnhancedARModelView(track: track, currentModelName: $currentModelName)
                .environmentObject(dataStore)
        }
    }
    
    
    // Setup timer to update audio analysis
    private func setupAnalysisTimer() {
        analysisTimer?.invalidate()
        
        analysisTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { _ in
            if self.playerService.isPlaying {
                if let analysis = self.dataStore.getAnalysisFor(
                    track: self.track,
                    at: self.playerService.currentTime
                ) {
                    
                    let newModelName = Model3D.getModelNameBasedOnBeat(analysis, genre: self.track.genre)
                    
                    if newModelName != self.currentModelName {
                        self.currentModelName = newModelName
                    }
                    
                    self.audioAnalysis = analysis
                } else {
                    
                    audioAnalysis = [
                        "bass": Double.random(in: 0.3...0.7),
                        "midrange": Double.random(in: 0.3...0.7),
                        "treble": Double.random(in: 0.3...0.7),
                        "beat": Double.random(in: 0...1) > 0.8 ? Double.random(in: 0.5...0.9) : 0.1
                    ]
                }
            }
        }
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
    private func navigateToTab(index: Int) {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController,
           let tabBarController = rootViewController.children.first as? UITabBarController {
            tabBarController.selectedIndex = index
        }
    }
}

extension EnhancedPlayerView {
    static func createEnhancedPlayer(for track: Track) -> some View {
        EnhancedPlayerView(track: track)
    }
}
