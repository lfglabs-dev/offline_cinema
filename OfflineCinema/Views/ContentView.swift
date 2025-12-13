//
//  ContentView.swift
//  OfflineCinema
//
//  Main content view with Books-inspired glass UI layout
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject var library: VideoLibrary
    @State private var showFilePicker = false
    @State private var dragOver = false
    @State private var searchText = ""
    
    var body: some View {
        ZStack {
            // Solid dark background like Books app
            Color(nsColor: NSColor.windowBackgroundColor)
                .ignoresSafeArea(.all)
            
            // Main layout
            if library.isPlaying, let video = library.selectedVideo {
                // Full-screen video player
                VideoPlayerView(video: video)
                    .transition(.opacity)
            } else {
                // Library view
                mainLibraryLayout
                    .transition(.opacity)
            }
        }
        .frame(minWidth: 900, minHeight: 600)
        .animation(.easeInOut(duration: 0.25), value: library.isPlaying)
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: supportedVideoTypes,
            allowsMultipleSelection: true
        ) { result in
            if case .success(let urls) = result {
                Task {
                    for url in urls {
                        await library.importVideo(from: url)
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .importVideo)) { _ in
            showFilePicker = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .openVideoFile)) { notification in
            if let url = notification.object as? URL {
                Task {
                    await library.importVideo(from: url)
                    // Auto-play the imported video
                    if let video = library.videos.first(where: { $0.resolvedURL == url }) {
                        library.playVideo(video)
                    }
                }
            }
        }
    }
    
    // MARK: - Main Library Layout
    
    private var mainLibraryLayout: some View {
        HStack(spacing: 0) {
            // Sidebar like Books app - solid background, no floating
            SidebarView()
                .frame(width: 240)
                .background(Color(nsColor: NSColor.controlBackgroundColor).opacity(0.5))
            
            // Subtle separator
            Rectangle()
                .fill(Color.primary.opacity(0.1))
                .frame(width: 1)
            
            // Main content area
            mainContentArea
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    // MARK: - Main Content Area
    
    private var mainContentArea: some View {
        ZStack {
            // Video grid or drop zone
            if library.videos.isEmpty {
                dropZone
            } else {
                VideoGridView(videos: library.filteredVideos)
            }
            
            // Drag overlay
            if dragOver {
                dragOverlay
            }
        }
        .onDrop(of: [.fileURL], isTargeted: $dragOver) { providers in
            handleDrop(providers: providers)
        }
    }
    
    // MARK: - Drop Zone
    
    private var dropZone: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Title header like Books app
            HStack(alignment: .center) {
                Text(library.currentFilterTitle)
                    .font(.system(size: 32, weight: .bold, design: .serif))
                
                Spacer()
                
                // Three-dot menu
                Menu {
                    Button {
                        showFilePicker = true
                    } label: {
                        Label("Import Videos...", systemImage: "plus")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 18))
                        .foregroundColor(.secondary)
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .frame(width: 28, height: 28)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 20)
            
            // Drop zone content
            VStack(spacing: 28) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color(hex: "DC2626").opacity(0.1))
                        .frame(width: 88, height: 88)
                    
                    Circle()
                        .strokeBorder(Color(hex: "DC2626").opacity(0.2), lineWidth: 1)
                        .frame(width: 88, height: 88)
                    
                    Image(systemName: dragOver ? "arrow.down" : "play.rectangle.on.rectangle.fill")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(Color(hex: "DC2626"))
                        .scaleEffect(dragOver ? 1.1 : 1.0)
                }
                .animation(.spring(response: 0.3), value: dragOver)
                
                VStack(spacing: 8) {
                    Text("Drop videos to add to your library")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text("MP4, MOV, MKV, AVI, and more")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                
                Button {
                    showFilePicker = true
                } label: {
                    Text("Choose Files")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background {
                            Capsule().fill(Color(hex: "DC2626"))
                        }
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: 380)
            .padding(48)
            .background {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.primary.opacity(dragOver ? 0.04 : 0.02))
                    .overlay {
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(
                                dragOver ? Color(hex: "DC2626").opacity(0.5) : .primary.opacity(0.08),
                                style: StrokeStyle(lineWidth: dragOver ? 2 : 1, dash: dragOver ? [] : [8, 6])
                            )
                    }
            }
            .scaleEffect(dragOver ? 1.01 : 1.0)
            .animation(.spring(response: 0.3), value: dragOver)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    // MARK: - Drag Overlay
    
    private var dragOverlay: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "DC2626").opacity(0.1))
            
            VStack(spacing: 12) {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundColor(Color(hex: "DC2626"))
                
                Text("Drop to add to library")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: "DC2626"))
            }
        }
        .transition(.opacity)
    }
    
    // MARK: - Helpers
    
    private var supportedVideoTypes: [UTType] {
        [.movie, .mpeg4Movie, .quickTimeMovie, .avi, .mpeg]
    }
    
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        var handled = false
        
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier("public.file-url") {
                provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, _ in
                    guard let data = item as? Data,
                          let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
                    
                    // Check if it's a video file
                    let videoExtensions = ["mp4", "mov", "mkv", "avi", "m4v", "wmv", "webm", "flv", "3gp", "ogv"]
                    let ext = url.pathExtension.lowercased()
                    
                    if videoExtensions.contains(ext) {
                        Task { @MainActor in
                            await library.importVideo(from: url)
                        }
                    }
                }
                handled = true
            }
        }
        
        return handled
    }
}

// MARK: - Visual Effect Background

struct VisualEffectBackground: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .sidebar
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.blendingMode = .behindWindow
        view.state = .active
        view.material = material
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}

#Preview {
    ContentView()
        .environmentObject(VideoLibrary())
        .frame(width: 1100, height: 750)
}

