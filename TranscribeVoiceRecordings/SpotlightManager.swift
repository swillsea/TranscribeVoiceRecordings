//
//  SpotlightManager.swift
//  TranscribeVoiceRecordings
//
//  Created by Sam Willsea on 1/2/17.
//  Copyright © 2017 Sam Willsea. All rights reserved.
//

import Foundation
import CoreSpotlight
import MobileCoreServices

class SpotlightManager {

    class func indexForSearch(memory: URL, text: String) {
        
        let attributeSet = CSSearchableItemAttributeSet(itemContentType: kUTTypeText as String)
        attributeSet.title = "_ App Memory"
        attributeSet.contentDescription = text
        attributeSet.thumbnailURL = thumbnailURL(for: memory)
        
        let searchableItem = CSSearchableItem(uniqueIdentifier: memory.path, domainIdentifier: "com.ThisApp", attributeSet: attributeSet)
        
        searchableItem.expirationDate = Date.distantFuture
        
        CSSearchableIndex.default().indexSearchableItems([searchableItem]) { error in
            if let error = error {
                print("Indexing error: \(error.localizedDescription)")
            } else {
                print("Indexing succeeded")
            }
        }
        
    }
    
}
