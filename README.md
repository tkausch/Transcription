# Transcribe

A native macOS and iOS audio transcription app powered by OpenAI's Whisper models, running entirely on-device for maximum privacy and performance.

## Features

### Core Functionality
- **On-Device Transcription**: Transcribe audio files locally using WhisperKit, no internet required after model download
- **Multiple Whisper Models**: Choose from various Whisper models optimized for different use cases:
  - Base models (~145 MB) - Fast and efficient
  - Small models (~500 MB) - Balanced performance
  - Medium models (~1.5 GB) - High accuracy
  - Large models (~3 GB) - Maximum accuracy
  - English-optimized variants for faster, more accurate English-only transcription
- **AI-Powered Summaries**: Generate concise summaries of transcriptions using Apple's FoundationModels framework
- **Multi-Language Support**: Automatic language detection and transcription in multiple languages
- **Audio Playback**: Built-in audio player with synchronized transcription viewing

### User Experience
- **Dark Mode**: Optional force dark mode setting
- **Localization**: Full localization support for English, German, French, Spanish, Danish, Norwegian, Swedish, and Icelandic
- **Progress Tracking**: Real-time progress indicators for downloads and transcriptions
- **Onboarding**: Guided setup for first-time users
- **iOS Shortcuts Integration**: Transcribe audio files via Siri Shortcuts and the Shortcuts app

### Platform-Specific Features

#### macOS
- macOS Services integration: Right-click audio files in Finder and select "Transcribe Audio"
- Native document-based workflow
- Grouped form styling

#### iOS
- App Intents support for Shortcuts integration
- Download confirmation alerts with data size information
- Optimized for iPhone and iPad

## System Requirements

- **macOS**: macOS 14.0 or later
- **iOS**: iOS 17.0 or later
- **Storage**: 150 MB - 3 GB depending on selected model
- **RAM**: Recommended 8 GB or more for optimal performance with larger models

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/tkausch/Transcription.git
   cd Transcribe
   ```

2. Open the project in Xcode:
   ```bash
   open Transcribe.xcodeproj
   ```

3. Build and run the project in Xcode

## Getting Started

### First Launch
1. Launch the app and complete the onboarding process
2. Navigate to Settings
3. Select your preferred Whisper model (Base model recommended for first-time users)
4. Download the model (keep the app in the foreground during download)

### Transcribing Audio
1. Import an audio file (supported formats: MP3, M4A, WAV, MP4)
2. The transcription will begin automatically if a model is downloaded
3. View real-time progress as the transcription processes
4. Once complete, read the full transcription and optionally generate an AI summary

### Using Shortcuts (iOS)
1. Open the Shortcuts app
2. Create a new shortcut
3. Add the "Transcribe Audio" action
4. Configure the audio file input
5. Run the shortcut to transcribe audio anywhere in iOS

## Architecture

### Core Services
- **TranscriptionService**: Manages WhisperKit pipeline and handles audio transcription
- **SummarizationService**: Generates summaries using Apple's FoundationModels
- **AudioFileStore**: Manages audio file storage and cleanup
- **TranscriptionRepository**: Handles persistence via SwiftData
- **AppSettings**: Manages user preferences and model configuration

### View Architecture
Built with SwiftUI and following MVVM pattern:
- **TranscriptionListView**: Main list of all transcriptions
- **TranscriptionDetailView**: Detailed view with audio player and transcription text
- **SettingsView**: Model selection and app configuration
- **OnboardingView**: First-time user experience

### Data Persistence
- SwiftData for transcription metadata and text storage
- Local file system for audio files (managed by AudioFileStore)
- UserDefaults for app settings via AppSettings

## Privacy

Transcribe is designed with privacy as a top priority:
- All transcription happens on-device
- No data is sent to external servers (except model downloads)
- Audio files are stored locally in the app's container
- No telemetry or analytics collected

## Technical Details

### Dependencies
- **WhisperKit**: Apple's optimized implementation of OpenAI's Whisper for on-device transcription
- **FoundationModels**: Apple's framework for on-device AI/ML capabilities (summarization)
- **AVFoundation**: Audio playback and processing
- **SwiftData**: Modern data persistence
- **SwiftUI**: Native UI framework

### Performance Optimizations
- Async/await throughout for responsive UI
- Background model loading on app launch
- Detached tasks for heavy computation
- Progress callbacks for long-running operations
- Intelligent audio duration-based progress tracking

## Development

### Project Structure
```
Transcribe/
├── Service/           # Core business logic and services
├── Views/             # SwiftUI views and view models
├── Model/             # Data models
└── Transcribe/        # App configuration and assets
```

### Building
- Requires Xcode 15.0 or later
- Swift 5.9+
- Targets macOS 14.0+ and iOS 17.0+

## License

Copyright © 2026 Thomas Kausch. All Rights Reserved.

## Acknowledgments

- OpenAI for the Whisper model
- Apple for WhisperKit and FoundationModels frameworks
