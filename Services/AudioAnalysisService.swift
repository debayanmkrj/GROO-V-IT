//
//  AudioAnalysisService.swift
//  GrooveMusic
//
//  Created by Student on 3/19/25.
//

import Foundation
import AVFoundation
import Accelerate

class AudioAnalysisService {
    private let fileManager = FileManager.default
    private let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    
    // analysis for a track and save to file
    func analyzeAndSaveTrack(_ track: Track) async throws -> URL {
        guard let audioURL = track.audioURL else {
            throw NSError(domain: "GrooveMusicApp", code: 1, userInfo: [NSLocalizedDescriptionKey: "Audio file not found"])
        }
        
        //  analysis file URL
        let analysisURL = documentsDirectory.appendingPathComponent(track.analysisFilename)
        
        // Check if analysis already exists
        if fileManager.fileExists(atPath: analysisURL.path) {
            return analysisURL
        }
        
        // Perform audio analysis
        let analysis = try await performAudioAnalysis(for: audioURL, trackId: track.id)
        
        // Convert to JSON data
        let encoder = JSONEncoder()
        let data = try encoder.encode(analysis)
        
        // Save to file
        try data.write(to: analysisURL)
        
        return analysisURL
    }
    
    private func performAudioAnalysis(for url: URL, trackId: UUID) async throws -> [AudioAnalysis] {
        let audioFile = try AVAudioFile(forReading: url)
        let format = audioFile.processingFormat
        let sampleRate = format.sampleRate
        
        // Calculate buffer size and prepare analysis settings
        let frameCount = UInt32(audioFile.length)
        let analysisIntervalSeconds = 0.1
        let framesPerInterval = UInt32(sampleRate * analysisIntervalSeconds)
        let intervalCount = Int(ceil(Double(frameCount) / Double(framesPerInterval)))
        
        var analysisResults = [AudioAnalysis]()
        
        // Create a buffer for reading audio
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: framesPerInterval)!
        
        // Sectuin detection
        var bassHistory: [Double] = []
        var beatHistory: [Double] = []
        var energyHistory: [Double] = []
        let historyWindowSize = 20
        
        var currentSection = "intro"
        _ = ["intro", "verse", "chorus", "bridge", "outro"]
        var sectionStartTime = 0.0
        let minSectionDuration = 10.0 // Minimum section duration in seconds
        
        var songProgressPercent = 0.0
        
        // Read and analyze file in chunks
        for i in 0..<intervalCount {
            
            audioFile.framePosition = AVAudioFramePosition(i) * AVAudioFramePosition(framesPerInterval)
            
            do {
                try audioFile.read(into: buffer)
            } catch {
                break
            }
            
            if buffer.frameLength == 0 {
                continue
            }
            
            let timestamp = Double(i) * analysisIntervalSeconds
            
            // Update song progress
            songProgressPercent = Double(i) / Double(intervalCount)
            
            // Extract audio features
            let loudness = calculateLoudness(buffer)
            let frequencyBands = analyzeFrequencyBands(buffer, sampleRate: sampleRate)
            let tempo = estimateTempo(buffer, sampleRate: sampleRate)
            
            // Get bass and beat values
            let bassValue = frequencyBands.first(where: { $0.band == "bass" })?.energy ?? 0.0
            let beatValue = Double.random(in: 0.4...0.9) * loudness // Simulated beat detection
            let energyValue = calculateEnergy(buffer)
            
            // Add current values to history buffer
            bassHistory.append(bassValue)
            beatHistory.append(beatValue)
            energyHistory.append(energyValue)
            
            // Keep history at specified size
            if bassHistory.count > historyWindowSize {
                bassHistory.removeFirst()
                beatHistory.removeFirst()
                energyHistory.removeFirst()
            }
            
            var sectionChanges = [AudioAnalysis.SectionChange]()
            let timeSinceLastSectionChange = timestamp - sectionStartTime
            
            if timeSinceLastSectionChange >= minSectionDuration && bassHistory.count >= historyWindowSize / 2 {
                
                let avgBass = bassHistory.reduce(0, +) / Double(bassHistory.count)
                let avgBeat = beatHistory.reduce(0, +) / Double(beatHistory.count)
                let avgEnergy = energyHistory.reduce(0, +) / Double(energyHistory.count)
                
                let bassDelta = abs(bassValue - avgBass)
                let beatDelta = abs(beatValue - avgBeat)
                let energyDelta = abs(energyValue - avgEnergy)
                
                let thresholdForChange = 0.25
                
                let significantChange = (bassDelta > thresholdForChange ||
                                         beatDelta > thresholdForChange ||
                                         energyDelta > thresholdForChange)
                
                var nextSection = currentSection
                
                // Force section change based on song structure
                if songProgressPercent < 0.1 {
                    // First 10% of the song
                    nextSection = "intro"
                } else if songProgressPercent > 0.9 {
                    // Last 10% of the song
                    nextSection = "outro"
                } else if significantChange {
                    // Middle of song - choose based on audio characteristics
                    if bassValue > 0.7 && beatValue > 0.6 && energyValue > 0.7 {
                        nextSection = "chorus"
                    } else if bassValue > 0.5 && beatValue > 0.5 {
                        nextSection = "verse"
                    } else if bassValue > 0.6 && beatValue < 0.4 {
                        nextSection = "bridge"
                    } else if bassValue < 0.4 && beatValue < 0.4 {
                        nextSection = "verse" // Quieter verse
                    }
                }
                
                
                if nextSection != currentSection {
                    currentSection = nextSection
                    sectionStartTime = timestamp
                    
                    sectionChanges.append(AudioAnalysis.SectionChange(
                        timestamp: timestamp,
                        type: currentSection,
                        intensity: max(bassValue, beatValue)
                    ))
                    
                    // Clear history buffers for next section
                    bassHistory.removeAll()
                    beatHistory.removeAll()
                    energyHistory.removeAll()
                }
            }
            
            // Generate beats
            var beats = [AudioAnalysis.Beat]()
            if beatValue > 0.5 || i % 5 == 0 {
                beats.append(AudioAnalysis.Beat(
                    timestamp: timestamp,
                    confidence: Double.random(in: 0.7...1.0),
                    strength: beatValue
                ))
            }
            
            // Create analysis object
            let analysis = AudioAnalysis(
                trackId: trackId,
                timestamp: timestamp,
                frequencyBands: frequencyBands,
                beats: beats,
                loudness: loudness,
                tempo: tempo,
                sectionChanges: sectionChanges,
                energyLevel: energyValue,
                rhythmicComplexity: Double.random(in: 0.2...0.9),
                tonal: i % 2 == 0
            )
            
            analysisResults.append(analysis)
        }
        
        return analysisResults
    }
    
    // Calculate loudness from audio buffer
    private func calculateLoudness(_ buffer: AVAudioPCMBuffer) -> Double {
        guard let channelData = buffer.floatChannelData else { return 0 }
        
        let channelCount = Int(buffer.format.channelCount)
        let frameLength = Int(buffer.frameLength)
        var sumOfSquares: Float = 0.0
        
        // Calculate RMS (Root Mean Square) value
        for channel in 0..<channelCount {
            let data = channelData[channel]
            for frame in 0..<frameLength {
                let sample = data[frame]
                sumOfSquares += sample * sample
            }
        }
        
        let rms = sqrt(sumOfSquares / Float(frameLength * channelCount))
        
        // Convert to dB and normalize to 0-1 range
        let dbValue = 20 * log10(rms)
        let normalizedDb = (dbValue + 50) / 50 // Assuming -50dB is silence, 0dB is maximum
        
        return Double(max(0, min(1, normalizedDb)))
    }
    
    // Analyze frequency bands
    private func analyzeFrequencyBands(_ buffer: AVAudioPCMBuffer, sampleRate: Double) -> [AudioAnalysis.FrequencyBand] {
        // Define frequency bands
        let bands = [
            "bass": (20.0, 250.0),
            "midrange": (250.0, 4000.0),
            "treble": (4000.0, 20000.0)
        ]
        
        var results = [AudioAnalysis.FrequencyBand]()
        
        for (name, range) in bands {
            let energy = Double.random(in: 0.2...0.9)
            let peakFrequency = Double.random(in: range.0...range.1)
            
            results.append(AudioAnalysis.FrequencyBand(
                band: name,
                energy: energy,
                peakFrequency: peakFrequency
            ))
        }
        
        return results
    }
    
    // Estimate tempo (BPM)
    private func estimateTempo(_ buffer: AVAudioPCMBuffer, sampleRate: Double) -> Double {
        return Double.random(in: 80...160)
    }
    
    // Calculate energy (overall intensity)
    private func calculateEnergy(_ buffer: AVAudioPCMBuffer) -> Double {
        return calculateLoudness(buffer) * Double.random(in: 0.8...1.2)
    }
    
    // Load analysis for a track
    func loadAnalysis(for track: Track) throws -> [AudioAnalysis]? {
        let analysisURL = documentsDirectory.appendingPathComponent(track.analysisFilename)
        
        if !fileManager.fileExists(atPath: analysisURL.path) {
            return nil
        }
        
        let data = try Data(contentsOf: analysisURL)
        
        let decoder = JSONDecoder()
        let analysis = try decoder.decode([AudioAnalysis].self, from: data)
        
        return analysis
    }
}
