//
//  TempHelpers.swift
//  TranscribeVoiceRecordings
//
//  Created by Sam Willsea on 1/2/17.
//  Copyright © 2017 Sam Willsea. All rights reserved.
//

import Foundation

func getDocumentsDirectory() -> URL {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    let documentsDirectory = paths[0]
    return documentsDirectory
}

// Path helpers
func imageURL(for memory: URL) -> URL {
    return memory.appendingPathExtension("jpg")
}
func thumbnailURL(for memory: URL) -> URL {
    return memory.appendingPathExtension("thumb")
}
func audioURL(for memory: URL) -> URL {
    return memory.appendingPathExtension("m4a")
}
func transcriptionURL(for memory: URL) -> URL {
    return memory.appendingPathExtension("txt")
}
