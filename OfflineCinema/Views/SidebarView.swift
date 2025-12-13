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
    @State private var selectedTopDestination: TopDestination? = nil
    
    private let contentInsetX: CGFloat = 12
    private let rowHPadding: CGFloat = 12
    private let rowVPadding: CGFloat = 6
    private let titlebarSpacerHeight: CGFloat = 52
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Titlebar space (traffic lights). Panel sits under the titlebar, so controls feel “inside”.
            Spacer().frame(height: titlebarSpacerHeight)
            
            // Top destinations (Books-style)
            topDestinations
            
            // Library section
            librarySection
            
            // Collections section
            collectionsSection
            
            Spacer()
            
            // User profile footer like Books
            userProfileFooter
        }
        .padding(.top, 6)
    }
    
    // MARK: - App Header
    
    private var appHeader: some View {
        EmptyView()
            .frame(height: 0)
    }
    
    // MARK: - Library Section
    
    private var librarySection: some View {
        VStack(alignment: .leading, spacing: 1) {
            SidebarSectionHeader(title: "Library")
            
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
        .padding(.horizontal, contentInsetX)
    }
    
    // MARK: - Collections Section
    
    private var collectionsSection: some View {
        VStack(alignment: .leading, spacing: 1) {
            HStack {
                SidebarSectionHeader(title: "My Collections")
                Spacer()
            }
            .padding(.top, 8)
            
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
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .frame(width: 20)
                    
                    Text("New Collection")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, contentInsetX)
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
    
    // MARK: - User Profile Footer (like Books)
    
    private var userProfileFooter: some View {
        HStack(spacing: 10) {
            // User avatar
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "7C3AED"), Color(hex: "6366F1")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 28, height: 28)
                .overlay {
                    Text("T")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                }
            
            VStack(alignment: .leading, spacing: 1) {
                Text("Thomas")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary)
                
                Text("Marchand")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 14)
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

// MARK: - Top Destinations (Books-style, simplified)

private enum TopDestination: String, CaseIterable, Identifiable {
    case search = "Search"
    case home = "Home"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .search: return "magnifyingglass"
        case .home: return "house"
        }
    }
}

private struct TopDestinationRow: View {
    let destination: TopDestination
    let isSelected: Bool
    let action: () -> Void
    @State private var hovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: destination.icon)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.primary.opacity(0.85))
                    .frame(width: 22)
                
                Text(destination.rawValue)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary.opacity(0.9))
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(isSelected ? .white.opacity(0.10) : (hovered ? .white.opacity(0.05) : .clear))
            }
        }
        .buttonStyle(.plain)
        .onHover { hovered = $0 }
    }
}

private extension SidebarView {
    var topDestinations: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(TopDestination.allCases) { dest in
                TopDestinationRow(destination: dest, isSelected: selectedTopDestination == dest) {
                    selectedTopDestination = dest
                    library.selectedSidebar = .library(.all)
                }
            }
        }
        .padding(.horizontal, contentInsetX)
        .padding(.bottom, 8)
    }
}

// MARK: - Sidebar Section Header

struct SidebarSectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(.secondary)
            .textCase(.uppercase)
            .tracking(0.3)
            .padding(.horizontal, 10)
            .padding(.top, 10)
            .padding(.bottom, 4)
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
            HStack(spacing: 8) {
                Image(systemName: filter.iconOutlined)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .frame(width: 20)
                
                Text(filter.rawValue)
                    .font(.system(size: 13))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(isSelected ? .white.opacity(0.10) : (isHovered ? .white.opacity(0.05) : .clear))
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
            HStack(spacing: 8) {
                Image(systemName: collection.icon)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .frame(width: 20)
                
                Text(collection.name)
                    .font(.system(size: 13))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(isSelected ? .white.opacity(0.10) : (isHovered ? .white.opacity(0.05) : .clear))
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

