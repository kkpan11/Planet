//
//  AppContentItemView.swift
//  PlanetLite
//

import SwiftUI
import ImageIO


struct AppContentItemView: View {
    @EnvironmentObject private var planetStore: PlanetStore
    
    var article: MyArticleModel
    var width: CGFloat
    
    @State private var isShowingDeleteConfirmation = false
    @State private var thumbnail: NSImage?

    var body: some View {
        itemPreviewImageView(forArticle: self.article)
            .onTapGesture {
                Task { @MainActor in
                    AppContentDetailsWindowManager.shared.activateWindowController(forArticle: self.article)
                }
            }
            .contextMenu {
                Button {
                    isShowingDeleteConfirmation = true
                } label: {
                    Text("Delete Article")
                }
            }
            .confirmationDialog(
                Text("Are you sure you want to delete this article?"),
                isPresented: $isShowingDeleteConfirmation
            ) {
                Button(role: .destructive) {
                    do {
                        if let planet = article.planet {
                            article.delete()
                            planet.updated = Date()
                            try planet.save()
                            try planet.savePublic()
                            Task { @MainActor in
                                AppContentDetailsWindowManager.shared.deactivateWindowController(forArticle: article)
                                planetStore.selectedView = .myPlanet(planet)
                            }
                        }
                    } catch {
                        PlanetStore.shared.alert(title: "Failed to delete article: \(error)")
                    }
                } label: {
                    Text("Delete")
                }
            }
    }
    
    @ViewBuilder
    private func itemPreviewImageView(forArticle article: MyArticleModel) -> some View {
        VStack {
            if let thumbnail = thumbnail {
                Image(nsImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                if let heroImageName = article.getHeroImage() {
                    let cachedPath = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(heroImageName)!
                    if let cachedHeroImage = NSImage(contentsOf: cachedPath) {
                        Image(nsImage: cachedHeroImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .frame(width: 16, height: 16, alignment: .center)
                            .task(id: article.id, priority: .background) {
                                let heroImagePath = article.publicBasePath.appendingPathComponent(heroImageName)
                                guard let heroImage = NSImage(contentsOf: heroImagePath) else {
                                    await MainActor.run {
                                        self.thumbnail = nil
                                    }
                                    return
                                }
                                Task.detached(priority: .utility) {
                                    let image = await self.generateThumbnail(forImage: heroImage, imageName: heroImageName, imagePath: heroImagePath)
                                    await MainActor.run {
                                        self.thumbnail = image == nil ? nil : image!
                                    }
                                }
                            }
                    }
                } else {
                    if let summary = article.summary, summary != "" {
                        Text(article.summary!)
                    } else {
                        Text(article.title)
                    }
                }
            }
        }
        .contentShape(Rectangle())
        .frame(width: width, height: width)
        .background(Color.secondary.opacity(0.15))
        .cornerRadius(4)
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }
    
    private func generateThumbnail(forImage image: NSImage, imageName: String, imagePath: URL) async -> NSImage? {
        let ratio: CGFloat = image.size.width / image.size.height
        let targetSize = NSSize(width: width * 2, height: width * 2 / ratio)
        let sourceOptions: [CFString: Any] = [
            kCGImageSourceShouldCache: false
        ]
        let imageOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageIfAbsent: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: width * 2
        ]
        guard let imageSource = CGImageSourceCreateWithURL(imagePath as NSURL, sourceOptions as CFDictionary), let targetCGImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, imageOptions as CFDictionary) else {
            return nil
        }
        let targetImage = NSImage(cgImage: targetCGImage, size: targetSize)
        let cachedPath = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(imageName)!
        Task (priority: .background) {
            do {
                try targetImage.PNGData?.write(to: cachedPath)
            } catch {
                debugPrint("failed to save cached thumbnail for article: \(error)")
            }
        }
        return targetImage
    }
}