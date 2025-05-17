//
//  AudioAnalysis.swift
//  GrooveMusic
//
//  Created by Student on 3/19/25.
//

import Foundation

struct AudioAnalysis: Codable {
    let trackId: UUID
    let timestamp: Double
    let frequencyBands: [FrequencyBand]
    let beats: [Beat]
    let loudness: Double
    let tempo: Double
    let sectionChanges: [SectionChange]
    
    // metadata to help with 3D animations
    let energyLevel: Double
    let rhythmicComplexity: Double
    let tonal: Bool
    
    // frequency band analysis for animation triggers
    struct FrequencyBand: Codable {
        let band: String
        let energy: Double
        let peakFrequency: Double
    }
    
    // Beat detection for animations
    struct Beat: Codable {
        let timestamp: Double
        let confidence: Double
        let strength: Double
    }
    
    // Section changes for major animation transitions
    struct SectionChange: Codable {
        let timestamp: Double
        let type: String
        let intensity: Double
    }
    
    // Helper method to identify animation triggers
    func getAnimationTriggers(at currentTime: Double, window: Double = 0.1) -> [String: Double] {
        var triggers: [String: Double] = [:]
        
        // Check if  at a beat
        if let nearestBeat = beats.first(where: { abs($0.timestamp - currentTime) < window }) {
            triggers["beat"] = nearestBeat.strength
        }
        
        // Check if at a section change
        if let sectionChange = sectionChanges.first(where: { abs($0.timestamp - currentTime) < window }) {
            triggers["sectionChange"] = sectionChange.intensity
            triggers["sectionType"] = Double(sectionChange.type.hashValue) // Just a way to encode the section type
        }
        
        // Add frequency data for current time
        triggers["bass"] = frequencyBands.first(where: { $0.band == "bass" })?.energy ?? 0
        triggers["midrange"] = frequencyBands.first(where: { $0.band == "midrange" })?.energy ?? 0
        triggers["treble"] = frequencyBands.first(where: { $0.band == "treble" })?.energy ?? 0
        
        return triggers
    }
}

