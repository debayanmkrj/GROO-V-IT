//
//  Model3D.swift
//  GrooveMusic
//
//  Created by Student on 3/19/25.
//
import Foundation
import SceneKit
import RealityKit

class Model3D: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String
    let filename: String
    let thumbnailName: String
    var isFavorite: Bool
    static let primaryModel = "Female_HH_7"
    
    // Additional attributes for animation
    let animationPoints: [String: [String]]
    let style: String
    
    // Modified model selection based on beat intensity
    static func getModelNameBasedOnBeat(_ audioAnalysis: [String: Double], genre: String = "Hip-Hop") -> String {
        let beat = audioAnalysis["beat"] ?? 0.0
        let bass = audioAnalysis["bass"] ?? 0.0
        
        // Combined intensity (weighted more toward bass)
        let intensity = (bass * 0.7) + (beat * 0.3)
        
        // Check the section type if available
        let sectionType = audioAnalysis["sectionType"]
        let sectionName = sectionType != nil ? getSectionNameFromHash(sectionType!) : "verse"
        
        // Select model based on genre
        if genre.lowercased() == "pop" {
            // For Pop genre, choose between Biker_House_Dancing or Biker_Swing_Dancing
            if sectionName == "chorus" || intensity > 0.6 {
                return "Biker_House_Dancing"
            } else {
                return "Biker_Swing_Dancing"
            }
        } else {
            // For Hip-Hop genre (default behavior)
            if intensity <= 0.3 {
                // Low intensity: Female_HH_0 to Female_HH_3
                let modelNumber = min(3, Int(intensity * 10))
                return "Female_HH_\(modelNumber)"
            } else if intensity <= 0.6 {
                // Medium intensity: Female_HH_4 to Female_HH_10
                let modelNumber = 4 + Int((intensity - 0.3) * 20)
                return "Female_HH_\(min(10, modelNumber))"
            } else {
                // High intensity: Female_HH_11 to Female_HH_13
                let modelNumber = 11 + Int((intensity - 0.6) * 7.5)
                return "Female_HH_\(min(13, modelNumber))"
            }
        }
    }
    
    private static func getSectionNameFromHash(_ hashValue: Double) -> String {
        let sections = ["intro", "verse", "chorus", "bridge", "outro"]
        let hash = Int(hashValue)
        
        for section in sections {
            if section.hashValue == hash {
                return section
            }
        }
        return "verse" // Default
    }
    
    // Get URL for a specific model by name
    static func urlForModelName(_ modelName: String) -> URL? {
        
        if let url = Bundle.main.url(forResource: modelName, withExtension: "usdz") {
            return url
        }
        
        
        let allModels = Bundle.main.paths(forResourcesOfType: "usdz", inDirectory: nil)
        
        
        for path in allModels {
            let filename = URL(fileURLWithPath: path).lastPathComponent.lowercased()
            if filename.contains(modelName.lowercased()) {
                return URL(fileURLWithPath: path)
            }
        }
        
        // Genre-specific handling
        if modelName.contains("Biker") {
            
            for path in allModels {
                if URL(fileURLWithPath: path).lastPathComponent.lowercased().contains("biker") {
                    return URL(fileURLWithPath: path)
                }
            }
        }
        
        
        return Bundle.main.url(forResource: primaryModel, withExtension: "usdz")
    }
    
    // Get all available USDZ models in the bundle (for debugging)
    static func getAllAvailableModels() -> [String] {
        return Bundle.main.paths(forResourcesOfType: "usdz", inDirectory: nil).map {
            URL(fileURLWithPath: $0).lastPathComponent
        }
    }
    
    // Computed property for SceneKit URL
    var modelURL: URL? {
        
        if let url = Bundle.main.url(forResource: filename.replacingOccurrences(of: ".usdz", with: ""),
                                     withExtension: "usdz") {
            return url
        }
        
        let lowercaseName = filename.replacingOccurrences(of: ".usdz", with: "").lowercased()
        if let url = Bundle.main.url(forResource: lowercaseName, withExtension: "usdz") {
            return url
        }
        
        let allModels = Bundle.main.paths(forResourcesOfType: "usdz", inDirectory: nil)
        for path in allModels {
            let filename = URL(fileURLWithPath: path).lastPathComponent.lowercased()
            if filename.contains(lowercaseName) {
                return URL(fileURLWithPath: path)
            }
        }
        
        if let firstModel = Bundle.main.paths(forResourcesOfType: "usdz", inDirectory: nil).first {
            return URL(fileURLWithPath: firstModel)
        }
        
        return nil
    }
    
    // Computed property for thumbnail image
    var thumbnail: UIImage {
        if let image = UIImage(named: thumbnailName) {
            return image
        }
        //fallback
        return UIImage(systemName: "person.fill") ?? UIImage()
    }
    
    // Initializer
    init(id: UUID = UUID(), name: String, filename: String, thumbnailName: String, isFavorite: Bool = false,
         animationPoints: [String: [String]] = [:], style: String = "general") {
        self.id = id
        self.name = name
        self.filename = filename
        self.thumbnailName = thumbnailName
        self.isFavorite = isFavorite
        self.animationPoints = animationPoints
        self.style = style
    }
    
    // Create a copy with updated favorite status
    func withUpdatedFavorite(_ isFavorite: Bool) -> Model3D {
        let copy = self
        copy.isFavorite = isFavorite
        return copy
    }
    static func getAudioIntensity(audioAnalysis: [String: Double]) -> Double {
        //  overall intensity from bass, midrange, and beat
        let bass = audioAnalysis["bass"] ?? 0.0
        let mid = audioAnalysis["midrange"] ?? 0.0
        let beat = audioAnalysis["beat"] ?? 0.0
        
        // Weight the components
        return (bass * 0.6) + (mid * 0.3) + (beat * 0.1)
    }
    
    // Equality check
    static func == (lhs: Model3D, rhs: Model3D) -> Bool {
        lhs.id == rhs.id
    }
    
    
    static let samples: [Model3D] = [
        Model3D(
            name: "Hip-Hop Dancer",
            filename: "Female_HH_7.usdz", // Default medium intensity
            thumbnailName: "dancer1_thumb",
            animationPoints: [
                "full_body": ["bass", "beat", "midrange"]
            ],
            style: "hiphop"
        ),
        
        Model3D(
            name: "Pop Dancer",
            filename: "Biker_Swing_Dancing.usdz",
            thumbnailName: "dancer2_thumb",
            animationPoints: [
                "full_body": ["bass", "midrange", "treble"]
            ],
            style: "pop"
        ),
        
        Model3D(
            name: "EDM Dancer",
            filename: "Female_HH_10.usdz",
            thumbnailName: "robot_thumb",
            animationPoints: [
                "full_body": ["bass", "beat", "midrange", "treble"]
            ],
            style: "edm"
        ),
        
        Model3D(
            name: "Intense Dancer",
            filename: "Female_HH_13.usdz",
            thumbnailName: "alien_thumb",
            animationPoints: [
                "full_body": ["bass", "beat", "midrange", "treble"]
            ],
            style: "experimental"
        ),
        
        Model3D(
            name: "Chill Dancer",
            filename: "Female_HH_2.usdz",
            thumbnailName: "character_thumb",
            animationPoints: [
                "full_body": ["midrange", "treble"]
            ],
            style: "general"
        )
    ]
}
