<p align="center">
  <img src="branding/logo_preview.png" alt="Offline Cinema" width="200">
</p>

<h1 align="center">Offline Cinema</h1>

<p align="center">
  <strong>Open source</strong> macOS video library viewer. Beautiful. Minimal. Native.
</p>

<p align="center">
  <a href="#building">Build it yourself</a> · <a href="#features">Features</a>
</p>

---

## What is this?

Offline Cinema is a native macOS application for managing and watching your downloaded movies and videos. Inspired by Apple Books, it provides a beautiful, minimal interface that feels right at home on macOS.

This project is **fully open source**. You can clone it, build it, modify it, and use it however you like.

- **Drag and drop** videos to build your library
- **Track progress** with automatic resume
- **Organize** with custom collections
- **Full playback** with keyboard controls, subtitles, and PiP

## Features

### Library Management
| Feature | Description |
|---------|-------------|
| **Smart Filters** | All, Watching, Finished – automatically organized |
| **Collections** | Create custom collections with icons and colors |
| **Progress Tracking** | Automatically saves your position and watch state |
| **Search** | Quick search across your entire library |

### Video Playback
| Feature | Description |
|---------|-------------|
| **Full Controls** | Play, pause, seek, skip forward/back |
| **Speed Control** | 0.5× to 2× playback speed |
| **Subtitles** | Select embedded subtitle tracks |
| **Audio Tracks** | Switch between audio tracks |
| **Picture-in-Picture** | Watch in a floating window |
| **Keyboard Shortcuts** | Space, arrows, F for fullscreen |

### Design
| Feature | Description |
|---------|-------------|
| **Glass UI** | Native macOS vibrancy and translucency |
| **Dark Mode** | Designed for dark mode first |
| **Tahoe Style** | Follows macOS Tahoe design language |
| **Minimal** | No clutter, just your videos |

## Supported Formats

| Video Formats |
|---------------|
| MP4, MOV, MKV, AVI, M4V, WebM, WMV, FLV, 3GP, OGV |

## Requirements

- macOS 14.0 (Sonoma) or later

## Building

### Quick Build

```bash
./build-app.sh
```

This will:
1. Build the app in release mode
2. Create the `OfflineCinema.app` bundle
3. Launch the app automatically

### Clean Rebuild

If you need to rebuild from scratch:

```bash
swift package clean
rm -rf .build OfflineCinema.app
./build-app.sh
```

Or as a one-liner:

```bash
swift package clean && rm -rf .build OfflineCinema.app && ./build-app.sh
```

### Development Build

For faster iteration during development:

```bash
swift build
swift run
```

## Running the App

### After Building

The build script automatically launches the app. To run it manually:

```bash
open OfflineCinema.app
```

### From Finder

Navigate to the project directory and double-click `OfflineCinema.app`.

### Move to Applications (Optional)

To install permanently:

```bash
cp -r OfflineCinema.app /Applications/
```

Then launch from Spotlight or the Applications folder.

## Keyboard Shortcuts

| Key | Action |
|-----|--------|
| `Space` | Play / Pause |
| `←` | Skip back 10 seconds |
| `→` | Skip forward 30 seconds |
| `⌘←` | Skip back 60 seconds |
| `⌘→` | Skip forward 60 seconds |
| `↑` | Volume up |
| `↓` | Volume down |
| `F` | Toggle fullscreen |
| `Esc` | Exit player |
| `⌘O` | Import video |

## Project Structure

```
offline_cinema/
├── OfflineCinema/
│   ├── Models/           # Video, Collection, WatchProgress
│   ├── Services/         # VideoLibrary, Persistence, Thumbnails
│   ├── Views/            # SwiftUI views
│   │   ├── ContentView.swift
│   │   ├── SidebarView.swift
│   │   ├── VideoGridView.swift
│   │   └── VideoPlayerView.swift
│   └── Assets.xcassets/  # App icons and colors
├── build-app.sh          # Build script
└── Package.swift         # Swift Package Manager config
```

## Data Storage

Your library data is stored in:
```
~/Library/Application Support/OfflineCinema/
├── library.json      # Video metadata and progress
└── collections.json  # Custom collections
```

Videos are not copied – only references (bookmarks) are stored.

## License

MIT License. See LICENSE for details.

