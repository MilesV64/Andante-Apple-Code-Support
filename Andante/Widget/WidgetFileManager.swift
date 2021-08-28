//
//  WidgetFileManager.swift
//  Andante
//
//  Created by Miles Vinson on 9/25/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import Foundation

struct WidgetFileManager {
    
    private static var sharedContainerURL: URL {
        return FileManager.default.containerURL(
          forSecurityApplicationGroupIdentifier: "group.milesvinson.Andante"
        )!.appendingPathComponent("contents.json")
    }
    
    public static func writeContents(_ contents: [WidgetContent]) {
        let archiveURL = WidgetFileManager.sharedContainerURL
        
        let encoder = JSONEncoder()
        if let dataToSave = try? encoder.encode(contents) {
            do {
                try dataToSave.write(to: archiveURL)
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    public static func getContents() -> [WidgetContent] {
        var contents: [WidgetContent] = []
        let archiveURL = WidgetFileManager.sharedContainerURL

        let decoder = JSONDecoder()
        if let codeData = try? Data(contentsOf: archiveURL) {
            do {
                contents = try decoder.decode([WidgetContent].self, from: codeData)
            } catch {
                print(error.localizedDescription)
            }
        }
        
        return contents
    }
    
    
    
}
