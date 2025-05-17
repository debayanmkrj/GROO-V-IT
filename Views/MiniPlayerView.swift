//
//  MiniPlayerView.swift
//  GrooveMusic
//
//  Created by Student on 3/19/25.
//
import SwiftUI

struct MiniPlayerView: View {
    @EnvironmentObject private var dataStore: MusicDataStore
    @State private var showPlayerSheet = false
    @State private var currentTrackId: UUID? = nil
    @State private var isPlaying: Bool = false
    @State private var currentProgress: Double = 0
    @State private var progressTimer: Timer? = nil
    
    private var playerService: AudioPlayerService {
        dataStore.audioPlayerService
    }
    
    var body: some View {
        if let currentTrack = playerService.currentTrack {
            VStack(spacing: 0) {
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 2)
                        
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [.accent, .secondaryAccent],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * CGFloat(currentProgress), height: 2)
                    }
                }
                .frame(height: 2)
                
                // Mini player content
                HStack(spacing: 12) {
                    // Album artwork
                    currentTrack.artwork
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 40, height: 40)
                        .cornerRadius(6)
                    
                    // Track info
                    VStack(alignment: .leading, spacing: 2) {
                        Text(currentTrack.title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.textPrimary)
                        
                        Text(currentTrack.artist)
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 20) {
                        Button {
                            playerService.togglePlayPause()
                            
                            isPlaying.toggle()
                        } label: {
                            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                .font(.title3)
                                .foregroundColor(.textPrimary)
                        }
                        
                        Button {
                            dataStore.toggleFavorite(currentTrack)
                        } label: {
                            Image(systemName: currentTrack.isFavorite ? "heart.fill" : "heart")
                                .font(.title3)
                                .foregroundColor(currentTrack.isFavorite ? .accent : .textPrimary)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(
                    Color.cardBackground
                        .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: -2)
                )
                .onTapGesture {
                    showPlayerSheet = true
                }
            }
            .sheet(isPresented: $showPlayerSheet) {
                if let currentTrack = playerService.currentTrack {
                    EnhancedPlayerView(track: currentTrack)
                        .environmentObject(dataStore)
                }
            }
            .onChange(of: playerService.currentTrack?.id) { oldValue, newValue in
                if oldValue != newValue {
                    currentTrackId = newValue
                    
                    currentProgress = 0
                }
            }
            .onChange(of: playerService.isPlaying) { oldValue, newValue in
                
                isPlaying = newValue
                
                if newValue {
                    startProgressTimer()
                } else {
                    progressTimer?.invalidate()
                }
            }
            .onAppear {
                currentTrackId = currentTrack.id
                isPlaying = playerService.isPlaying
                currentProgress = playerService.progress
                
                if isPlaying {
                    startProgressTimer()
                }
                
                print("MiniPlayer appeared, isPlaying: \(isPlaying), progress: \(currentProgress)")
            }
            .onDisappear {
                
                progressTimer?.invalidate()
            }
        }
    }
    
    private func startProgressTimer() {
        
        progressTimer?.invalidate()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if playerService.isPlaying {
                currentProgress = playerService.progress
            }
        }
    }
}

// Preview
struct MiniPlayerView_Previews: PreviewProvider {
    static var previews: some View {
        let store = MusicDataStore()
        store.audioPlayerService.play(Track.samples[0])
        
        return MiniPlayerView()
            .environmentObject(store)
            .preferredColorScheme(.dark)
            .background(Color.background)
    }
}
