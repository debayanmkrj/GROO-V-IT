//
//  GrooveMusicApp.swift
//  GrooveMusic
//
//  Created by Student on 3/19/25.
//

import SwiftUI

@main
struct GrooveMusicApp: App {
    
    @StateObject private var dataStore = MusicDataStore()
    @State private var selectedTab = 0
    
    var body: some Scene {
        WindowGroup {
            ZStack(alignment: .bottom) {
                TabView(selection: $selectedTab) {
                    HomeView()
                        .environmentObject(dataStore)
                        .tabItem {
                            Label("Home", systemImage: "house.fill")
                        }
                        .tag(0)
                    
                    FavoritesView()
                        .environmentObject(dataStore)
                        .tabItem {
                            Label("Favorites", systemImage: "heart.fill")
                        }
                        .tag(1)
                }
                .accentColor(.pink)
                
                // Mini player overlay
                if dataStore.audioPlayerService.currentTrack != nil {
                    MiniPlayerView()
                        .environmentObject(dataStore)
                        .transition(.move(edge: .bottom))
                        .zIndex(1)
                }
            }
            .onChange(of: dataStore.audioPlayerService.currentTrack) { _, _ in
                print("Track changed, updating view")
            }
            .preferredColorScheme(.dark) // Dark mode for music app aesthetic
        }
    }
}

