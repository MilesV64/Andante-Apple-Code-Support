//
//  IntentHandler.swift
//  WidgetProfileIntent
//
//  Created by Miles Vinson on 9/25/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import Intents

class IntentHandler: INExtension, ChooseProfileIntentHandling {
    
    func provideProfileOptionsCollection(for intent: ChooseProfileIntent, with completion: @escaping (INObjectCollection<WidgetProfile>?, Error?) -> Void) {
        
        let contents = WidgetFileManager.getContents()
        
        let profiles: [WidgetProfile] = contents.map { content in
            let widgetProfile = WidgetProfile(
                identifier: content.profileID,
                display: content.profileName)
            widgetProfile.name = content.profileName
            return widgetProfile
        }
        
        let collection = INObjectCollection(items: profiles)
        completion(collection, nil)
        
    }
    
    
    override func handler(for intent: INIntent) -> Any {
        // This is the default implementation.  If you want different objects to handle different intents,
        // you can override this and return the handler you want for that particular intent.
        
        return self
    }
    
}
