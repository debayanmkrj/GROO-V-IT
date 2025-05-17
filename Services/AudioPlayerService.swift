//
//  AudioPlayerService.swift
//  GrooveMusic
//
//  Created by Student on 3/19/25.
//

import Foundation
import AVFoundation
import Combine

class AudioPlayerService: ObservableObject {
    @Published var isPlaying: Bool = false
    @Published var currentTrack: Track?
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var progress: Double = 0
    @Published var volume: Float = 1.0
    var onTrackChanged: ((Track) -> Void)?
    
    // Audio player
    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?
    
    init() {
        
        setupAudioSession()
    }
    
    // Setup audio session for proper playback
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default)
            try audioSession.setActive(true)
            print("Audio session setup successful")
        } catch {
            print("Audio session setup failed: \(error.localizedDescription)")
        }
    }
    
    // Timer for updating UI
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let player = self.audioPlayer else { return }
            self.currentTime = player.currentTime
            self.duration = player.duration
            self.progress = player.currentTime / player.duration
        }
    }
    
    func setVolume(_ volume: Float) {
        self.volume = max(0, min(1, volume))
        audioPlayer?.volume = self.volume
    }
    // Play a track
    func play(_ track: Track) {
        
        if currentTrack?.id == track.id {
            resume()
            return
        }
        
        stopAndReset()
        
        // Set up new track
        currentTrack = track
        
        onTrackChanged?(track)
        
        guard let url = track.audioURL else {
            print("Could not find audio file for \(track.title)")
            print("Attempting to find file: \(track.filename)")
            
            Bundle.main.paths(forResourcesOfType: "mp3", inDirectory: nil).forEach {
                print("Available MP3: \($0)")
            }
            return
        }
        
        print("Playing track from URL: \(url.path)")
        print("File exists: \(FileManager.default.fileExists(atPath: url.path))")
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            
            // Set volume to current volume setting
            audioPlayer?.volume = volume
            
            try AVAudioSession.sharedInstance().setActive(true)
            
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            isPlaying = true
            startTimer()
            
            objectWillChange.send()
            
            print("Audio player started successfully")
        } catch {
            print("Error playing track: \(error.localizedDescription)")
        }
    }
    
    // Pause playback
    func pause() {
        audioPlayer?.pause()
        isPlaying = false
    }
    
    // Resume playback
    func resume() {
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to activate audio session: \(error)")
        }
        
        audioPlayer?.play()
        isPlaying = true
    }
    
    // Toggle play/pause
    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            resume()
        }
    }
    
    // Seek to a specific position
    func seek(to time: TimeInterval) {
        audioPlayer?.currentTime = time
        currentTime = time
    }
    
    // Seek to a percentage of the track
    func seekToPercent(_ percent: Double) {
        guard let player = audioPlayer else { return }
        let targetTime = player.duration * max(0, min(1, percent))
        seek(to: targetTime)
    }
    
    // Skip to next or previous track
    func skipToNextOrPrevious(tracks: [Track], forward: Bool) {
        guard let currentTrack = currentTrack,
              let currentIndex = tracks.firstIndex(where: { $0.id == currentTrack.id }) else {
            return
        }
        
        let newIndex = forward ?
        (currentIndex + 1) % tracks.count :
        (currentIndex - 1 + tracks.count) % tracks.count
        
        play(tracks[newIndex])
    }
    
    // Cleanup
    func stopAndReset() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        currentTime = 0
        timer?.invalidate()
    }
    
    deinit {
        timer?.invalidate()
        
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("Failed to deactivate audio session: \(error)")
        }
    }
}
