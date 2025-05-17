![Groove_Music_logo](https://github.com/user-attachments/assets/aff8d171-b84a-4e05-b4fa-56bd2b35015e)

# GROO-V-IT
GROO-V-IT is an immersive music player app that combines audio playback with real-time 3D visual experiences. The app features a unique interactive component where 3D character models animated as dancers react to the music's beat, bass, and other audio characteristics.

GrooveMusic (GROO-V-IT)
An immersive music player app that creates dynamic 3D visualizations and AR experiences based on music analysis. Elevate your listening experience with real-time responsive 3D dancers that move to the beat!
🎵 Features
Core Music Features

Music library with streaming playback
Favorites management
Recently played tracks
Full playback controls (play/pause, previous/next, seek, volume)
Mini-player overlay for navigation while listening

Advanced Visualization

Dynamic 3D Model Visualization: 3D dancers that react to the music's beat, bass, and section changes
Augmented Reality Mode: Place dancers in your real environment through AR
Real-time Audio Analysis: Automated detection of beats, sections (intro, verse, chorus, bridge, outro), and frequency bands

Technical Highlights

Reactive UI with SwiftUI
3D rendering with SceneKit
AR experience with RealityKit and ARKit
Real-time audio analysis and visualization
Smooth animations and transitions

📱 Screenshots

![image](https://github.com/user-attachments/assets/445c761f-41ac-4d66-b27b-481f7510c772)
![image](https://github.com/user-attachments/assets/450fe8b7-934b-4ab1-b020-4e7136815d50)
![image](https://github.com/user-attachments/assets/96b6bb21-e63a-4ea0-ac75-1d94f5839388)
![image](https://github.com/user-attachments/assets/18bf43c7-c272-4802-b507-ba1af395bd2b)
![image](https://github.com/user-attachments/assets/73cf964b-dbd5-47e1-a096-63bd24a50b01)


🏗 Architecture
Core Components:

MusicDataStore: Central data store for track management and state
AudioPlayerService: Handles music playback and control
AudioAnalysisService: Analyzes audio to extract beats, frequency data, and section changes
Model3D: Manages 3D models selection and rendering based on audio data

Key Views:

HomeView: Main interface with recently played and library
EnhancedPlayerView: Full-screen player with 3D visualization
EnhancedARModelView: Augmented reality experience with music-reactive dancers
FavoritesView: User's favorite tracks with management
MiniPlayerView: Persistent mini player for navigation while listening

🎨 3D Visualization System
GrooveMusic features an innovative visualization system that dynamically selects and animates 3D models based on:

Genre Detection: Different model types for various genres 

Hip-Hop dancers for rap/hip-hop tracks
Swing/house dancers for pop tracks


Beat Intensity Adaptation: Models change based on intensity levels

Low intensity: Subtle movements (Female_HH_0 to Female_HH_3)
Medium intensity: Moderate movements (Female_HH_4 to Female_HH_10)
High intensity: Energetic movements (Female_HH_11 to Female_HH_13)


Section Recognition: Transition between models based on song structure

Detects intro, verse, chorus, bridge, and outro
Changes visualization style to match the current section


Real-time Animation: Models respond to:

Bass intensity
Beat detection
Frequency distribution
Overall energy



🌟 Augmented Reality Experience
The AR mode allows users to:

Place dancers in their physical environment
Scale models to the desired size
Experience music with spatial context
Watch as dancers react to the music in real time
Interact with full playback controls while in AR mode

🎧 Audio Analysis
The app performs sophisticated analysis on audio files:

Beat detection for rhythm synchronization
Bass/midrange/treble separation for targeted animations
Section detection for structural awareness
Energy level calculation for intensity mapping

🔧 Technical Requirements

iOS 15.0+
Swift 5.0+
Xcode 14.0+
Devices with ARKit support (for AR features)

🚀 Getting Started

Clone the repository
Open GrooveMusic.xcodeproj in Xcode
Add MP3 files to the project to test with your own music
Build and run on a compatible iOS device


📝 License
This project is licensed under the MIT License - see the LICENSE file for details.
👥 Credits

USDZ 3D models for visualization
Sample tracks for demonstration
Design inspiration from modern music applications


Made with ❤️ using SwiftUI, RealityKit and SceneKit
