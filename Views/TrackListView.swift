//
//  TrackListView.swift
//  GrooveMusic
//
//  Created by Student on 3/19/25.
//

import SwiftUI

struct TrackListView: View {
    let tracks: [Track]
    let onTrackTap: (Track) -> Void
    
    @EnvironmentObject private var dataStore: MusicDataStore
    
    var body: some View {
        if tracks.isEmpty {
            // Empty state
            VStack(spacing: 20) {
                Image(systemName: "music.note.list")
                    .font(.system(size: 60))
                    .foregroundColor(.accent)
                
                Text("No Tracks Found")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                
                Text("Try a different search or add some music")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.textSecondary)
                    .padding(.horizontal, 40)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.background)
        } else {
            
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(tracks) { track in
                        TrackRowView(track: track)
                            .environmentObject(dataStore)
                            .onTapGesture {
                                onTrackTap(track)
                            }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 100)
            }
        }
    }
}

struct TrackListView_Previews: PreviewProvider {
    static var previews: some View {
        let store = MusicDataStore()
        
        return TrackListView(
            tracks: Track.samples,
            onTrackTap: { _ in }
        )
        .environmentObject(store)
        .preferredColorScheme(.dark)
    }
}
