# Offline Cinema

Native macOS video library app. Beautiful. Minimal. Native. Inspired by Apple Books.

## Tech Stack

- **Language**: Swift 5.9
- **UI Framework**: SwiftUI
- **Platform**: macOS 14.0+ (Sonoma)
- **Build**: Swift Package Manager + Xcode project
- **Video**: AVPlayer, AVKit

## Build Commands

```bash
# Quick build and run
./build-app.sh

# Clean rebuild
swift package clean && rm -rf .build OfflineCinema.app && ./build-app.sh

# Build with Xcode
open OfflineCinema.xcodeproj
```

## Project Structure

```
OfflineCinema/
├── OfflineCinemaApp.swift      # App entry, window config, traffic lights
├── Models/
│   ├── Video.swift             # Video model with bookmark handling
│   ├── Collection.swift        # User collections
│   └── WatchProgress.swift     # Playback progress tracking
├── Services/
│   ├── VideoLibrary.swift      # Central state manager
│   ├── PersistenceService.swift # JSON save/load
│   └── ThumbnailGenerator.swift # Video metadata extraction
├── Views/
│   ├── ContentView.swift       # Main layout with floating sidebar
│   ├── SidebarView.swift       # Navigation sidebar
│   ├── VideoGridView.swift     # Video thumbnail grid
│   ├── VideoPlayerView.swift   # Full-featured player
│   ├── LibraryDetailView.swift # Grid + empty state + drop zone
│   ├── AppKitSplitHost.swift   # AppKit split view wrapper
│   └── Components/             # Reusable UI components
└── Assets.xcassets/            # App icons and colors
```

## Design Principles

1. **Native First** — Use system APIs, materials, and behaviors
2. **Liquid Glass Aesthetic** — Translucent materials that sample desktop wallpaper
3. **Minimalism with Purpose** — Show only what's necessary
4. **Seamless Integration** — Drag-and-drop, Finder integration, keyboard shortcuts
5. **Performance** — Smooth video playback, hardware acceleration

## Key Patterns

### Window Configuration
```swift
window.titlebarAppearsTransparent = true
window.titleVisibility = .hidden
window.styleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
window.isMovableByWindowBackground = true
```

### Security-Scoped Bookmarks
Videos stored as security-scoped bookmarks for persistent access:
```swift
url.bookmarkData(options: .withSecurityScope, ...)
```

### AVPlayer Optimizations
```swift
playerItem.preferredForwardBufferDuration = 5.0
player.automaticallyWaitsToMinimizeStalling = false
player.preventsDisplaySleepDuringVideoPlayback = true
```

## Keyboard Shortcuts

| Key | Action |
|-----|--------|
| `Space` | Play / Pause |
| `←` | Skip back 10s |
| `→` | Skip forward 30s |
| `↑` / `↓` | Volume |
| `F` | Fullscreen |
| `Esc` | Exit player |
| `⌘O` | Import video |
| `⌘⌥S` | Toggle sidebar |

## Data Storage

Library data stored in: `~/Library/Application Support/OfflineCinema/`

Videos are not copied – only references (bookmarks) are stored.

## Supported Formats

MP4, MOV, MKV, AVI, M4V, WebM, WMV, FLV, 3GP, OGV

## Conventions

- Use SF Symbols for icons (16pt)
- Typography: 13pt for lists, 32pt bold serif for page titles
- Corner radius: 12pt for panels
- Sidebar width: 220pt
- Always capture objects weakly in notification observers
- Use `Task.sleep` instead of `Timer.scheduledTimer` in SwiftUI views
- Prefer hardware acceleration for video playback
