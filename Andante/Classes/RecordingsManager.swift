//
//  RecordingsManager.swift
//  Andante
//
//  Created by Miles Vinson on 7/29/19.
//  Copyright © 2019 Miles Vinson. All rights reserved.
//

import Foundation

class RecordingsManager {
    
    class func getRecordingsDirectory() -> URL {
        let directory = RecordingsManager.getDocumentsDirectory().appendingPathComponent("Recordings", isDirectory: true)
        
        //If the directory doesn't already exist, create it before returning the URL
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: false, attributes: nil)
        } catch {
            //directory already exists
        }
        
        return directory
    }
    
    class func getRecordings() -> [URL] {
        
        do {
            let urls = try FileManager.default.contentsOfDirectory(at: getRecordingsDirectory(), includingPropertiesForKeys: nil, options: [])
            return urls
        } catch {
            print(error.localizedDescription)
        }
        
        return []
    }
    
    /**
     Returns the URL of the recording with the given file name
     - Parameter fileName: The file name of the recording, without any extensions
     - Returns: The URL of the recording, regardless of if it is valid or not. The result should be error handled
     */
    class func getRecordingURL(_ fileName: String) -> URL {
        return getRecordingsDirectory().appendingPathComponent(fileName).appendingPathExtension("m4a")
    }
    
    class func createFileName(title: String = "Recording", from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
        return "Recording \(formatter.string(from: date))"
    }
    
    static func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }

    class func filename(from url: URL) -> String {
        return String(url.lastPathComponent.split(separator: ".").first!)
    }
}

extension URL {
    /**
     Renames the file at the url to the new given name
     
     - Parameter newName: The new name for the file. Should not include the extension.
     */
    func rename(_ newName: String) {
        let fileExtension = self.pathExtension
        let basePath = self.deletingLastPathComponent()
        let newPath = basePath.appendingPathComponent(newName).appendingPathExtension(fileExtension)
        do {
            try FileManager.default.moveItem(at: self, to: newPath)
        } catch {
            print(error)
        }
    }
}
