//
//  HomeView.swift
//  GrooveMusic
//
//  Created by Student on 3/19/25.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var dataStore: MusicDataStore
    @State private var searchText = ""
    @State private var showPlayerSheet = false
    @State private var showDebugView = false
    
    private var filteredTracks: [Track] {
        if searchText.isEmpty {
            return dataStore.allTracks
        } else {
            return dataStore.allTracks.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.artist.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private var recents: [Track] {
        return dataStore.recentlyPlayedTracks.isEmpty ?
        Array(dataStore.allTracks.prefix(3)) :
        dataStore.recentlyPlayedTracks
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerView
                    
                    // Recently Played Section
                    sectionHeader(title: "Recently Played")
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(recents) { track in
                                RecentTrackView(track: track)
                                    .onTapGesture {
                                        dataStore.audioPlayerService.play(track)
                                        showPlayerSheet = true
                                    }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    if dataStore.audioPlayerService.currentTrack != nil {
                        Button {
                            // Navigate to favorites tab
                            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                               let window = windowScene.windows.first,
                               let rootViewController = window.rootViewController,
                               let tabBarController = rootViewController.children.first as? UITabBarController {
                                tabBarController.selectedIndex = 1  // Index 1 is the Favorites tab
                            }
                        } label: {
                            HStack {
                                Image(systemName: "heart.fill")
                                Text("Go to Favorites")
                            }
                            .foregroundColor(.white)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(Color.accent)
                            .cornerRadius(16)
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                        
                    }
                    
                    sectionHeader(title: "Your Library")
                    
                    TrackListView(
                        tracks: filteredTracks,
                        onTrackTap: { track in
                            dataStore.audioPlayerService.play(track)
                            showPlayerSheet = true
                        }
                    )
                    .environmentObject(dataStore)
                }
                .padding(.bottom, 100) // Space for mini player
            }
            .background(Color.background.ignoresSafeArea())
            .navigationTitle("GROO-V-IT")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search music")
            
            .sheet(isPresented: $showPlayerSheet) {
                if let currentTrack = dataStore.audioPlayerService.currentTrack {
                    EnhancedPlayerView(track: currentTrack)
                        .environmentObject(dataStore)
                }
            }
        }
    }
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Welcome to")
                .font(.title3)
                .fontWeight(.medium)
                .foregroundColor(.textSecondary)
            
            Text("GROO-V-IT")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.accent, .secondaryAccent],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    // Section header
    private func sectionHeader(title: String) -> some View {
        Text(title)
            .font(.title2)
            .fontWeight(.bold)
            .foregroundColor(.textPrimary)
            .padding(.horizontal)
            .padding(.top, 10)
    }
}

// Recent track view
struct RecentTrackView: View {
    let track: Track
    
    var body: some View {
        VStack(alignment: .leading) {
            track.artwork
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 160, height: 160)
                .cornerRadius(12)
                .shadow(radius: 4)
            
            Text(track.title)
                .font(.headline)
                .foregroundColor(.textPrimary)
                .lineLimit(1)
            
            Text(track.artist)
                .font(.subheadline)
                .foregroundColor(.textSecondary)
                .lineLimit(1)
        }
        .frame(width: 160)
    }
}

// Row view for track list
struct TrackRowView: View {
    let track: Track
    @EnvironmentObject private var dataStore: MusicDataStore
    
    var body: some View {
        HStack(spacing: 12) {
            track.artwork
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 50, height: 50)
                .cornerRadius(6)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(track.title)
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                    .lineLimit(1)
                
                Text(track.artist)
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
                    .lineLimit(1)
            }
            
            Spacer(minLength: 2)
        }
    }
}

// Preview provider
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(MusicDataStore())
            .preferredColorScheme(.dark)
    }
}
