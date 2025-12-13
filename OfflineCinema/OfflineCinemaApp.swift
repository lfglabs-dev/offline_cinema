//
//  OfflineCinemaApp.swift
//  OfflineCinema
//
//  A beautiful native macOS video library viewer
//

import SwiftUI
import AppKit

@main
struct OfflineCinemaApp: App {
    @StateObject private var videoLibrary = VideoLibrary()
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(videoLibrary)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1100, height: 750)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Import Video...") {
                    NotificationCenter.default.post(name: .importVideo, object: nil)
                }
                .keyboardShortcut("o", modifiers: .command)
            }
            
            CommandMenu("View") {
                Button("Toggle Sidebar") {
                    NotificationCenter.default.post(name: .toggleSidebar, object: nil)
                }
                .keyboardShortcut("s", modifiers: [.command, .option])
            }
        }
    }
}

// MARK: - App Delegate

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private let trafficLights = TrafficLightsPositioner(offsetX: 14, offsetY: -10)
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.activate(ignoringOtherApps: true)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            for window in NSApplication.shared.windows {
                self.configureWindow(window)
                window.makeKeyAndOrderFront(nil)
            }
        }
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            for window in sender.windows {
                window.makeKeyAndOrderFront(nil)
            }
        }
        return true
    }
    
    func applicationDidBecomeActive(_ notification: Notification) {
        for window in NSApplication.shared.windows {
            window.makeKeyAndOrderFront(nil)
        }
    }
    
    func application(_ application: NSApplication, open urls: [URL]) {
        // Handle files opened via "Open With" or drag to dock icon
        for url in urls {
            NotificationCenter.default.post(name: .openVideoFile, object: url)
        }
    }
    
    func configureWindow(_ window: NSWindow) {
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        
        // Remove any toolbar to eliminate the glass titlebar effect
        window.toolbar = nil
        
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
        window.level = .normal
        window.collectionBehavior = [.managed, .fullScreenPrimary]
        window.isReleasedWhenClosed = false
        window.acceptsMouseMovedEvents = true
        window.ignoresMouseEvents = false
        window.isMovableByWindowBackground = true
        
        // Move traffic lights slightly down to match Books spacing (without changing sidebar inset).
        trafficLights.attach(to: window)
    }
}

// MARK: - Traffic lights positioning

/// Offsets the traffic lights from their system default positions (e.g., to match Books).
/// Uses an associated baseline so offsets do not accumulate across relayouts.
@MainActor
final class TrafficLightsPositioner {
    private let offsetX: CGFloat
    private let offsetY: CGFloat
    private var observers: [ObjectIdentifier: [NSObjectProtocol]] = [:]
    
    init(offsetX: CGFloat, offsetY: CGFloat) {
        self.offsetX = offsetX
        self.offsetY = offsetY
    }
    
    func attach(to window: NSWindow) {
        let id = ObjectIdentifier(window)
        if observers[id] != nil { return } // already attached
        
        // Apply after initial layout, then keep it consistent on resize/move.
        DispatchQueue.main.async { [weak self, weak window] in
            guard let self, let window else { return }
            self.apply(to: window)
        }
        
        let center = NotificationCenter.default
        let tokens: [NSObjectProtocol] = [
            center.addObserver(forName: NSWindow.didResizeNotification, object: window, queue: .main) { [weak self] _ in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    self.apply(to: window)
                }
            },
            center.addObserver(forName: NSWindow.didMoveNotification, object: window, queue: .main) { [weak self] _ in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    self.apply(to: window)
                }
            },
            center.addObserver(forName: NSWindow.didEndLiveResizeNotification, object: window, queue: .main) { [weak self] _ in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    self.apply(to: window)
                }
            }
        ]
        
        observers[id] = tokens
    }
    
    private func apply(to window: NSWindow) {
        guard let close = window.standardWindowButton(.closeButton),
              let mini = window.standardWindowButton(.miniaturizeButton),
              let zoom = window.standardWindowButton(.zoomButton) else { return }
        
        // Baseline positions (captured once, after the system has laid out the titlebar).
        let baseline = Baseline.ensure(on: window, close: close.frame.origin, mini: mini.frame.origin, zoom: zoom.frame.origin)
        
        close.setFrameOrigin(NSPoint(x: baseline.close.x + offsetX, y: baseline.close.y + offsetY))
        mini.setFrameOrigin(NSPoint(x: baseline.mini.x + offsetX, y: baseline.mini.y + offsetY))
        zoom.setFrameOrigin(NSPoint(x: baseline.zoom.x + offsetX, y: baseline.zoom.y + offsetY))
    }
    
    // MARK: Baseline storage
    
    private final class Baseline: NSObject {
        let close: NSPoint
        let mini: NSPoint
        let zoom: NSPoint
        
        init(close: NSPoint, mini: NSPoint, zoom: NSPoint) {
            self.close = close
            self.mini = mini
            self.zoom = zoom
        }
        
        static func ensure(on window: NSWindow, close: NSPoint, mini: NSPoint, zoom: NSPoint) -> Baseline {
            if let existing = objc_getAssociatedObject(window, &baselineKey) as? Baseline {
                return existing
            }
            let created = Baseline(close: close, mini: mini, zoom: zoom)
            objc_setAssociatedObject(window, &baselineKey, created, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return created
        }
    }
}

private var baselineKey: UInt8 = 0

// MARK: - Notification Names

extension Notification.Name {
    static let importVideo = Notification.Name("importVideo")
    static let openVideoFile = Notification.Name("openVideoFile")
    static let toggleSidebar = Notification.Name("toggleSidebar")
}

