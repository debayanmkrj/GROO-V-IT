//
//  FavoritesView.swift
//  GrooveMusic
//
//  Created by Student on 3/19/25.
//

import SwiftUI

import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject private var dataStore: MusicDataStore
    @State private var showPlayerSheet = false
    @State private var isEditing = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.background.ignoresSafeArea()
                
                if dataStore.favoriteTracks.isEmpty {
                    // Empty state
                    VStack(spacing: 20) {
                        Image(systemName: "heart.slash")
                            .font(.system(size: 70))
                            .foregroundColor(.accent)
                        
                        Text("No Favorites Yet")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.textPrimary)
                        
                        Text("Add songs to your favorites by tapping the heart icon")
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.textSecondary)
                            .padding(.horizontal, 40)
                        
                        Button {
                            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                               let window = windowScene.windows.first,
                               let rootViewController = window.rootViewController,
                               let tabBarController = rootViewController.children.first as? UITabBarController {
                                tabBarController.selectedIndex = 0
                            }
                        } label: {
                            Text("Browse All Tracks")
                                .font(.headline)
                                .foregroundColor(.black)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color.accent)
                                .cornerRadius(20)
                        }
                        .padding(.top, 10)
                    }
                } else {
                    
                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach(dataStore.favoriteTracks) { track in
                                HStack(spacing: 12) {
                                    track.artwork
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 60, height: 60)
                                        .cornerRadius(8)
                                    
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
                                    
                                    Spacer()
                                    
                                    if isEditing {
                                        Button {
                                            dataStore.toggleFavorite(track)
                                        } label: {
                                            Image(systemName: "minus.circle.fill")
                                                .foregroundColor(.red)
                                                .font(.title2)
                                                .padding(8)
                                        }
                                        .buttonStyle(BorderlessButtonStyle())
                                    } else {
                                        Button {
                                            dataStore.audioPlayerService.play(track)
                                            showPlayerSheet = true
                                        } label: {
                                            Image(systemName: "play.fill")
                                                .foregroundColor(.accent)
                                                .padding(8)
                                        }
                                        .buttonStyle(BorderlessButtonStyle())
                                    }
                                }
                                .padding()
                                .background(Color.cardBackground.opacity(0.3))
                                .cornerRadius(10)
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("Favorites")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           let window = windowScene.windows.first,
                           let rootViewController = window.rootViewController,
                           let tabBarController = rootViewController.children.first as? UITabBarController {
                            tabBarController.selectedIndex = 0
                        }
                    } label: {
                        Image(systemName: "house.fill")
                            .foregroundColor(.white)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !dataStore.favoriteTracks.isEmpty {
                        Button {
                            withAnimation {
                                isEditing.toggle()
                            }
                        } label: {
                            Text(isEditing ? "Done" : "Edit")
                                .foregroundColor(.accent)
                        }
                    }
                }
            }
            .sheet(isPresented: $showPlayerSheet) {
                if let currentTrack = dataStore.audioPlayerService.currentTrack {
                    EnhancedPlayerView(track: currentTrack)
                        .environmentObject(dataStore)
                }
            }
        }
    }
}


// Preview provider
struct FavoritesView_Previews: PreviewProvider {
    static var previews: some View {
        let store = MusicDataStore()
        store.allTracks[0].isFavorite = true
        store.allTracks[2].isFavorite = true
        
        return FavoritesView()
            .environmentObject(store)
            .preferredColorScheme(.dark)
    }
}
