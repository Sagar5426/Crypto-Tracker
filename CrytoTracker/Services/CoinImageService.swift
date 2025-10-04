//
//  CoinImageService.swift
//  CrytoTracker
//
//  Created by Sagar Jangra on 22/09/2025.
//

import SwiftUI
import Combine

class CoinImageService {
    @Published var image : UIImage? = nil
    private var imageSubsciption: AnyCancellable?
    private let coin: CoinModel
    private let fileManager = LocalFileManager.instance
    private let folderName = "coin_images"
    private let imageName: String
    
    init(coin: CoinModel) {
        self.coin = coin
        self.imageName = coin.id
        getCoinImage()
    }
    
    // Retreive image from file manager if downloaded before
    private func getCoinImage() {
        if let savedImage  = fileManager.getImage(imageName: imageName, folderName: folderName) {
            image = savedImage
            print("Retrieved image from file manager!")
        } else {
            downloadCoinImage()
            print("Downloading image now")
        }
    }
    
    
    // download from internet only if we dont get them in fileManager
    private func downloadCoinImage() {
        guard let url = URL(string: coin.image) else { return }
        
        imageSubsciption = NetworkingManager.download(url: url)
            .tryMap({ (data) -> UIImage? in
                return UIImage(data: data)
            })
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: NetworkingManager.handleCompletion, receiveValue: { [weak self] (returnedImage) in
                guard let self = self, let downloadedImage = returnedImage else { return }
                self.image = downloadedImage
                self.imageSubsciption?.cancel()
                self.fileManager.saveImage(image: downloadedImage, imageName: self.imageName, folderName: self.folderName)
            })
    }
    
    
}
