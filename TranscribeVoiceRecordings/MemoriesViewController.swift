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


    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkPermissions()
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
