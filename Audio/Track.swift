//
//  Track.swift
//  GrooveMusic
//
//  Created by Student on 3/19/25.
//

import Foundation
import SwiftUI

struct Track: Identifiable, Equatable, Codable {
    let id: UUID
    let title: String
    let artist: String
    let duration: TimeInterval
    let filename: String
    let artworkFilename: String
    var isFavorite: Bool
    var genre: String
    
    // Computed property to get the artwork image
    var artwork: Image {
        Image(artworkFilename.replacingOccurrences(of: ".jpg", with: ""))
    }
    
    // URL for the audio file
    var audioURL: URL? {
        // Remove file extension if present
        let filenameWithoutExtension = filename.replacingOccurrences(of: ".mp3", with: "")
        
        // resource with exact name match
        if let url = Bundle.main.url(forResource: filenameWithoutExtension, withExtension: "mp3") {
            return url
        }
        
        // try with lowercase filename
        let lowercaseName = filenameWithoutExtension.lowercased()
        if let url = Bundle.main.url(forResource: lowercaseName, withExtension: "mp3") {
            return url
        }
        
        let allMP3s = Bundle.main.paths(forResourcesOfType: "mp3", inDirectory: nil)
        for path in allMP3s {
            let filename = URL(fileURLWithPath: path).lastPathComponent
            if filename.lowercased().contains(filenameWithoutExtension.lowercased()) {
                return URL(fileURLWithPath: path)
            }
        }
        
        return nil
    }
    
    // For analysis file
    var analysisFilename: String {
        filename.replacingOccurrences(of: ".mp3", with: "_analysis.json")
    }
    
    // Equality check
    static func == (lhs: Track, rhs: Track) -> Bool {
        lhs.id == rhs.id
    }
    
    // Create a copy with updated favorite status
    func withUpdatedFavorite(_ isFavorite: Bool) -> Track {
        var copy = self
        copy.isFavorite = isFavorite
        return copy
    }
    
    //Data load
    static let samples: [Track] = [
        Track(id: UUID(), title: "Take On Me", artist: "A-ha", duration: 244,
              filename: "ahaTakeOnMe.mp3", artworkFilename: "ahaTakeOnMe.jpg", isFavorite: false, genre: "Pop"),
        
        Track(id: UUID(), title: "Billie Jean", artist: "Michael Jackson", duration: 296,
              filename: "BillieJean.mp3", artworkFilename: "BillieJean.jpg", isFavorite: false, genre: "Pop"),
        
        Track(id: UUID(), title: "Blinding Lights", artist: "The Weeknd", duration: 263,
              filename: "BlindingLights.mp3", artworkFilename: "BlindingLights.jpg", isFavorite: false, genre: "Pop"),
        
        Track(id: UUID(), title: "Fein", artist: "Travis Scott", duration: 194,
              filename: "Fein.mp3", artworkFilename: "fein.jpg", isFavorite: false, genre: "Hip-Hop"),
        
        Track(id: UUID(), title: "Not Like Us", artist: "Kendrick Lamar", duration: 255,
              filename: "Notlikeus.mp3", artworkFilename: "Notlikeus.jpg", isFavorite: false, genre: "Hip-Hop")
    ]
    
}



