//
//  AudioPlayerService.swift
//  GrooveMusic
//
//  Created by Student on 3/19/25.
//

import Foundation
import Combine
import SwiftUI

class MusicDataStore: ObservableObject, @unchecked Sendable {
    // Published properties for SwiftUI updates
    @Published var allTracks: [Track] = []
    @Published var favoriteTracks: [Track] = []
    @Published var allModels: [Model3D] = []
    @Published var currentModel: Model3D?
    @Published var isLoading: Bool = false
    @Published var error: String? = nil
    @Published var recentlyPlayedTracks: [Track] = []
    private let maxRecentTracks = 5
    
    private let audioAnalysisService = AudioAnalysisService()
    let audioPlayerService = AudioPlayerService()
    
    private let favoritesKey = "com.groovemusic.favorites"
    
    init() {
        
        allTracks = Track.samples
        
        allModels = Model3D.samples
        currentModel = allModels.first
        
        loadFromPlist()
        
        audioPlayerService.onTrackChanged = { [weak self] track in
            self?.updateRecentlyPlayed(track)
        }
        
        Task {
            await analyzeAllTracks()
        }
    }
    
    
    func toggleFavorite(_ track: Track) {
        if let index = allTracks.firstIndex(where: { $0.id == track.id }) {
            // Create new track instance with toggled favorite
            let updatedTrack = allTracks[index].withUpdatedFavorite(!allTracks[index].isFavorite)
            allTracks[index] = updatedTrack
            
            // If this is the current playing track, update it too
            if let currentTrack = audioPlayerService.currentTrack,
               currentTrack.id == track.id {
                audioPlayerService.currentTrack = updatedTrack
            }
            
            // Update favorites list
            updateFavoriteTracks()
            
            // Save to plist
            saveToPlist()
        }
    }
    
    func updateFavoriteTracks() {
        favoriteTracks = allTracks.filter { $0.isFavorite }
    }
    
    // Save favorites to UserDefaults
    private func saveFavorites() {
        let favoriteIds = allTracks.filter { $0.isFavorite }.map { $0.id.uuidString }
        UserDefaults.standard.set(favoriteIds, forKey: favoritesKey)
    }
    
    private func loadFavorites() {
        guard let favoriteIds = UserDefaults.standard.stringArray(forKey: favoritesKey) else {
            updateFavoriteTracks()
            return
        }
        
        let favoriteUUIDs = favoriteIds.compactMap { UUID(uuidString: $0) }
        
        for (index, track) in allTracks.enumerated() {
            if favoriteUUIDs.contains(track.id) {
                allTracks[index].isFavorite = true
            }
        }
        
        updateFavoriteTracks()
    }
    
    func updateRecentlyPlayed(_ track: Track) {
        // Remove the track if it's already in the list
        recentlyPlayedTracks.removeAll { $0.id == track.id }
        
        // Add the track to the beginning of the list
        recentlyPlayedTracks.insert(track, at: 0)
        
        if recentlyPlayedTracks.count > maxRecentTracks {
            recentlyPlayedTracks = Array(recentlyPlayedTracks.prefix(maxRecentTracks))
        }
    }
    
    // Analyze all tracks in the background
    func analyzeAllTracks() async {
        
        await MainActor.run {
            isLoading = true
            error = nil
        }
        
        for track in allTracks {
            do {
                _ = try await audioAnalysisService.analyzeAndSaveTrack(track)
            } catch {
                await MainActor.run {
                    self.error = "Failed to analyze \(track.title): \(error.localizedDescription)"
                }
            }
        }
        
        await MainActor.run {
            isLoading = false
        }
    }
    
    // Get analysis for a specific time in a track
    func getAnalysisFor(track: Track, at time: TimeInterval) -> [String: Double]? {
        do {
            guard let analysisData = try audioAnalysisService.loadAnalysis(for: track) else {
                return nil
            }
            
            if let closestPoint = analysisData.min(by: { abs($0.timestamp - time) < abs($1.timestamp - time) }) {
                return closestPoint.getAnimationTriggers(at: time)
            }
            
            return nil
        } catch {
            self.error = "Failed to load analysis: \(error.localizedDescription)"
            return nil
        }
    }
    private func saveToPlist() {
        do {
            let documentsDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let url = documentsDirectoryURL.appendingPathComponent("FavoriteTracks").appendingPathExtension("plist")
            let encoder = PropertyListEncoder()
            
            let favoriteTitles = allTracks.filter { $0.isFavorite }.map { $0.title }
            
            let data = try encoder.encode(favoriteTitles)
            try data.write(to: url)
            print("Successfully saved favorites to plist: \(favoriteTitles)")
        } catch {
            print("Error saving favorites: \(error.localizedDescription)")
        }
    }
    
    // Load data from plist file
    private func loadFromPlist() {
        let documentsDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let url = documentsDirectoryURL.appendingPathComponent("FavoriteTracks").appendingPathExtension("plist")
        
        print("Attempting to load favorites from: \(url.path)")
        
        if FileManager.default.fileExists(atPath: url.path) {
            do {
                let data = try Data(contentsOf: url)
                let decoder = PropertyListDecoder()
                let favoriteTitles = try decoder.decode([String].self, from: data)
                
                print("Loading favorites from plist by title: \(favoriteTitles)")
                
                // Reset all favorites first
                for (index, _) in allTracks.enumerated() {
                    allTracks[index].isFavorite = false
                }
                
                // Mark tracks as favorites by matching titles
                var foundFavorites = 0
                for title in favoriteTitles {
                    if let index = allTracks.firstIndex(where: { $0.title == title }) {
                        print("Setting track as favorite: \(allTracks[index].title)")
                        allTracks[index].isFavorite = true
                        foundFavorites += 1
                    } else {
                        print("Warning: Favorite track with title '\(title)' not found in current tracks")
                    }
                }
                
                updateFavoriteTracks()
                print("Successfully loaded \(favoriteTracks.count) favorites")
                for track in favoriteTracks {
                    print("Favorite track: \(track.title)")
                }
            } catch {
                print("Error loading favorites from plist: \(error.localizedDescription)")
            }
        } else {
            print("No favorites plist found at path: \(url.path)")
        }
    }
}

