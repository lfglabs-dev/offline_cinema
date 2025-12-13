//
//  ThumbnailGenerator.swift
//  OfflineCinema
//
//  Generate video thumbnails using AVFoundation
//

import Foundation
import AVFoundation
import AppKit

actor ThumbnailGenerator {
    
    struct VideoMetadata {
        let duration: TimeInterval
        let resolution: VideoResolution?
        let fileSize: Int64
        let thumbnailData: Data?
    }
    
    func generateMetadata(for url: URL) async -> VideoMetadata {
        let asset = AVAsset(url: url)
        
        // Get duration
        let duration: TimeInterval
        do {
            let cmDuration = try await asset.load(.duration)
            duration = CMTimeGetSeconds(cmDuration)
        } catch {
            duration = 0
        }
        
        // Get resolution from video track
        let resolution: VideoResolution?
        do {
            let tracks = try await asset.loadTracks(withMediaType: .video)
            if let videoTrack = tracks.first {
                let size = try await videoTrack.load(.naturalSize)
                let transform = try await videoTrack.load(.preferredTransform)
                
                // Apply transform to get correct dimensions (handles rotation)
                let transformedSize = size.applying(transform)
                let width = abs(Int(transformedSize.width))
                let height = abs(Int(transformedSize.height))
                
                resolution = VideoResolution(width: width, height: height)
            } else {
                resolution = nil
            }
        } catch {
            resolution = nil
        }
        
        // Get file size
        let fileSize: Int64
        do {
            let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey])
            fileSize = Int64(resourceValues.fileSize ?? 0)
        } catch {
            fileSize = 0
        }
        
        // Generate thumbnail
        let thumbnailData = await generateThumbnail(for: url, at: duration * 0.1)
        
        return VideoMetadata(
            duration: duration,
            resolution: resolution,
            fileSize: fileSize,
            thumbnailData: thumbnailData
        )
    }
    
    func generateThumbnail(for url: URL, at time: TimeInterval = 0) async -> Data? {
        let asset = AVAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.maximumSize = CGSize(width: 400, height: 400) // Reasonable thumbnail size
        imageGenerator.requestedTimeToleranceAfter = .zero
        imageGenerator.requestedTimeToleranceBefore = .zero
        
        let cmTime = CMTime(seconds: max(0, time), preferredTimescale: 600)
        
        do {
            let (cgImage, _) = try await imageGenerator.image(at: cmTime)
            let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
            
            // Convert to JPEG data
            guard let tiffData = nsImage.tiffRepresentation,
                  let bitmapRep = NSBitmapImageRep(data: tiffData) else {
                return nil
            }
            
            return bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: 0.8])
        } catch {
            // Try at the beginning if specified time fails
            if time > 0 {
                return await generateThumbnail(for: url, at: 0)
            }
            return nil
        }
    }
}

