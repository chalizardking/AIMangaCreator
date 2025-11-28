import Foundation
import AppKit

class CacheManager {
    static let shared = CacheManager()
    
    private let fileManager = FileManager.default
    private lazy var cacheDirectory: URL = {
        let caches = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        let mangaCache = caches.appendingPathComponent("AIMangaCreator")
        try? fileManager.createDirectory(at: mangaCache, withIntermediateDirectories: true)
        return mangaCache
    }()
    
    /// 1GB cache limit
    private let diskSizeLimit: Int = 1_000_000_000
    private var memoryCache = NSCache<NSString, NSImage>()
    
    func setImage(_ image: NSImage, forKey key: String) {
        memoryCache.setObject(image, forKey: key as NSString)
        
        if let tiff = image.tiffRepresentation,
           let bitmap = NSBitmapImageRep(data: tiff),
           let pngData = bitmap.representation(using: .png, properties: [:]) {
            let fileURL = cacheDirectory.appendingPathComponent("\(key).png")
            try? pngData.write(to: fileURL)
            trimCacheIfNeeded()
        }
    }
    
    func image(forKey key: String) -> NSImage? {
        if let cached = memoryCache.object(forKey: key as NSString) {
            return cached
        }
        
        let fileURL = cacheDirectory.appendingPathComponent("\(key).png")
        if let imageData = try? Data(contentsOf: fileURL),
           let image = NSImage(data: imageData) {
            memoryCache.setObject(image, forKey: key as NSString)
            return image
        }
        
        return nil
    }
    
    private func trimCacheIfNeeded() {
        let attrs = try? fileManager.attributesOfFileSystem(forPath: cacheDirectory.path)
        let availableSpace = (attrs?[.systemFreeSize] as? NSNumber)?.int64Value ?? 0
        
        /// Less than 100MB free
        if availableSpace < 100_000_000 {
            clearCache()
        }
    }
    
    func clearCache() {
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        memoryCache.removeAllObjects()
    }
}
