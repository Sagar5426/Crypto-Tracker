//
//  LocalFileManager.swift
//  CrytoTracker
//
//  Created by Sagar Jangra on 22/09/2025.
//

import SwiftUI


class LocalFileManager {
    // singleton
    static let instance = LocalFileManager()
    
    private init() {}
    
    func saveImage(image: UIImage, imageName: String, folderName: String) {
        
        // create folder
        createFolderIfNeeded(folderName: folderName)
        
        // get path for image
        guard let data = image.pngData(),
              let url = getUrlForImage(imageName: imageName, folderName: folderName)
        else { return }
        
        // save image to path
        do {
            try data.write(to: url)
        } catch let error {
            print("Error saving image. ImageName: \(imageName) \(error)")
        }
    }
    
    func getImage(imageName: String, folderName: String) -> UIImage? {
        guard let url = getUrlForImage(imageName: imageName, folderName: folderName),
              FileManager.default.fileExists(atPath: url.path)
        else { return nil }
        
        return UIImage(contentsOfFile: url.path)
    }
    
    private func createFolderIfNeeded(folderName: String) {
        guard let url = getUrlForFolder(folderName: folderName) else { return }
        
        if !FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
            } catch let error {
                print("Error creating directory. FolderName: \(folderName). \(error)")
            }
        }
    }
    
    
    private func getUrlForFolder(folderName: String) -> URL? {
        //using .cachesDirectory bcz if it get full and start unloading images we have functionality to download them again
        guard let folderURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else { return nil }
        
        return folderURL.appendingPathComponent(folderName)
    }
    
    private func getUrlForImage(imageName: String, folderName: String) -> URL? {
        guard let url = getUrlForFolder(folderName: folderName) else { return nil }
        
        
        return url.appendingPathComponent(imageName + ".png")
    }
}
