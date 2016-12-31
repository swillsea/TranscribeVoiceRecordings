//
//  MemoriesViewController.swift
//  TranscribeVoiceRecordings
//
//  Created by Sam Willsea on 12/30/16.
//  Copyright © 2016 Sam Willsea. All rights reserved.
//

import UIKit
import AVFoundation
import Speech
import Photos

class MemoriesViewController: UICollectionViewController {
    
    var memories = [URL]()

    override func viewDidLoad() {
        super.viewDidLoad()
        loadMemories()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkPermissions()
    }

    func loadMemories() {
        memories.removeAll()
        
        // attempt loading all memories
        guard let files = try? FileManager.default.contentsOfDirectory(at: getDocumentsDirectory(), includingPropertiesForKeys: nil, options: []) else {
            return
        }
        
        // add unique memories
        for file in files {
            let filename = file.lastPathComponent
            if filename.hasSuffix(".thumb") {
                let rootPath = filename.replacingOccurrences(of: ".thumb", with: "")
                let memoryPath = getDocumentsDirectory().appendingPathComponent(rootPath)
                memories.append(memoryPath)
            }
        }
        
        // only reload memories - ignore section[0] (search bar)
        collectionView?.reloadSections(IndexSet(integer: 1))
    }

    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    func checkPermissions() {
        let photosAuthorized = PHPhotoLibrary.authorizationStatus() == .authorized
        let recordingAuthorized = AVAudioSession.sharedInstance().recordPermission() == .granted
        let transcribeAuthorized = SFSpeechRecognizer.authorizationStatus() == .authorized
        
        let fullyAuthorized = photosAuthorized && recordingAuthorized && transcribeAuthorized
        
        if !fullyAuthorized {
            if let vc = storyboard?.instantiateViewController(withIdentifier: "FirstRun") {
                navigationController?.present(vc, animated: true)
            }
        }
    }
}
