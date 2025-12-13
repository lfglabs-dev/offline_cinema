//
//  SidebarView.swift
//  OfflineCinema
//
//  Books-inspired sidebar with library filters and collections
//

import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var library: VideoLibrary
    @State private var isCreatingCollection = false
    @State private var newCollectionName = ""
    @State private var editingCollection: VideoCollection?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top spacing for title bar area
            Spacer()
                .frame(height: 52)
            
            // Library section
            librarySection
            
            // Collections section
            collectionsSection
            
            Spacer()
            
            // Stats footer
            statsFooter
        }
    }
    
    // MARK: - App Header
    
    private var appHeader: some View {
        EmptyView()
            .frame(height: 0)
    }
    
    // MARK: - Library Section
    
    private var librarySection: some View {
        VStack(alignment: .leading, spacing: 4) {
            SidebarSectionHeader(title: "LIBRARY")
            
            ForEach(LibraryFilter.allCases) { filter in
                SidebarFilterButton(
                    filter: filter,
                    count: countForFilter(filter),
                    isSelected: isFilterSelected(filter)
                ) {
                    withAnimation(.spring(response: 0.25)) {
                        library.selectedSidebar = .library(filter)
                    }
                }
            }
        }
        .padding(.horizontal, 12)
    }
    
    // MARK: - Collections Section
    
    private var collectionsSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                SidebarSectionHeader(title: "MY COLLECTIONS")
                Spacer()
            }
            .padding(.top, 20)
            
            ForEach(library.collections) { collection in
                SidebarCollectionButton(
                    collection: collection,
                    isSelected: isCollectionSelected(collection)
                ) {
                    withAnimation(.spring(response: 0.25)) {
                        library.selectedSidebar = .collection(collection.id)
                    }
                }
                .contextMenu {
                    Button("Rename...") {
                        editingCollection = collection
                    }
                    Divider()
                    Button("Delete", role: .destructive) {
                        Task { await library.deleteCollection(collection) }
                    }
                }
            }
            
            // New collection button
            Button {
                isCreatingCollection = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 20)
                    
                    Text("New Collection")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .sheet(isPresented: $isCreatingCollection) {
            NewCollectionSheet(isPresented: $isCreatingCollection)
        }
        .sheet(item: $editingCollection) { collection in
            RenameCollectionSheet(collection: collection, isPresented: Binding(
                get: { editingCollection != nil },
                set: { if !$0 { editingCollection = nil } }
            ))
        }
    }
    
    // MARK: - Stats Footer
    
    private var statsFooter: some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider().padding(.horizontal, 4)
            
            let stats = library.libraryStats
            
            HStack(spacing: 8) {
                Image(systemName: "film.stack.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 1) {
                    Text("\(stats.total) videos")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.primary.opacity(0.8))
                    
                    Text("\(stats.watching) watching • \(stats.finished) finished")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
    
    // MARK: - Helpers
    
    private func countForFilter(_ filter: LibraryFilter) -> Int {
        switch filter {
        case .all: return library.videos.count
        case .watching: return library.videos.filter { $0.watchState == .watching }.count
        case .finished: return library.videos.filter { $0.watchState == .finished }.count
        }
    }
    
    private func isFilterSelected(_ filter: LibraryFilter) -> Bool {
        if case .library(let selected) = library.selectedSidebar {
            return selected == filter
        }
        return false
    }
    
    private func isCollectionSelected(_ collection: VideoCollection) -> Bool {
        if case .collection(let id) = library.selectedSidebar {
            return id == collection.id
        }
        return false
    }
}

// MARK: - Sidebar Section Header

struct SidebarSectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(.secondary)
            .tracking(0.5)
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
    }
}

// MARK: - Sidebar Filter Button

struct SidebarFilterButton: View {
    let filter: LibraryFilter
    let count: Int
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: filter.icon)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isSelected ? Color(hex: "DC2626") : .secondary)
                    .frame(width: 20)
                
                Text(filter.rawValue)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .primary : .secondary)
                
                Spacer()
                
                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background {
                            Capsule().fill(.primary.opacity(0.06))
                        }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color(hex: "DC2626").opacity(0.12) : (isHovered ? .primary.opacity(0.05) : .clear))
            }
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Sidebar Collection Button

struct SidebarCollectionButton: View {
    let collection: VideoCollection
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: collection.icon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isSelected ? collection.accentColor : .secondary)
                    .frame(width: 20)
                
                Text(collection.name)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .primary : .secondary)
                    .lineLimit(1)
                
                Spacer()
                
                if collection.videoCount > 0 {
                    Text("\(collection.videoCount)")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background {
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? collection.accentColor.opacity(0.12) : (isHovered ? .primary.opacity(0.05) : .clear))
            }
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

// MARK: - New Collection Sheet

struct NewCollectionSheet: View {
    @EnvironmentObject var library: VideoLibrary
    @Binding var isPresented: Bool
    @State private var name = ""
    @State private var selectedIcon = "folder.fill"
    @State private var selectedColor = "6366F1"
    
    var body: some View {
        VStack(spacing: 20) {
            Text("New Collection")
                .font(.system(size: 16, weight: .semibold))
            
            TextField("Collection name", text: $name)
                .textFieldStyle(.roundedBorder)
                .frame(width: 250)
            
            // Icon picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Icon")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                
                HStack(spacing: 8) {
                    ForEach(CollectionIcon.allCases) { icon in
                        Button {
                            selectedIcon = icon.rawValue
                        } label: {
                            Image(systemName: icon.rawValue)
                                .font(.system(size: 14))
                                .foregroundColor(selectedIcon == icon.rawValue ? .white : .secondary)
                                .frame(width: 28, height: 28)
                                .background {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(selectedIcon == icon.rawValue ? Color(hex: selectedColor) : .primary.opacity(0.06))
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            // Color picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Color")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                
                HStack(spacing: 8) {
                    ForEach(CollectionColor.allCases) { color in
                        Button {
                            selectedColor = color.rawValue
                        } label: {
                            Circle()
                                .fill(color.color)
                                .frame(width: 24, height: 24)
                                .overlay {
                                    if selectedColor == color.rawValue {
                                        Circle()
                                            .strokeBorder(.white, lineWidth: 2)
                                    }
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            HStack(spacing: 12) {
                Button("Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.escape)
                
                Button("Create") {
                    Task {
                        await library.createCollection(
                            name: name.isEmpty ? "New Collection" : name,
                            icon: selectedIcon,
                            color: selectedColor
                        )
                        isPresented = false
                    }
                }
                .keyboardShortcut(.return)
                .buttonStyle(.borderedProminent)
                .tint(Color(hex: selectedColor))
            }
        }
        .padding(24)
        .frame(width: 320)
    }
}

// MARK: - Rename Collection Sheet

struct RenameCollectionSheet: View {
    @EnvironmentObject var library: VideoLibrary
    let collection: VideoCollection
    @Binding var isPresented: Bool
    @State private var name: String = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Rename Collection")
                .font(.system(size: 16, weight: .semibold))
            
            TextField("Collection name", text: $name)
                .textFieldStyle(.roundedBorder)
                .frame(width: 250)
            
            HStack(spacing: 12) {
                Button("Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.escape)
                
                Button("Save") {
                    Task {
                        await library.renameCollection(collection, to: name)
                        isPresented = false
                    }
                }
                .keyboardShortcut(.return)
                .buttonStyle(.borderedProminent)
                .disabled(name.isEmpty)
            }
        }
        .padding(24)
        .frame(width: 320)
        .onAppear {
            name = collection.name
        }
    }
}

