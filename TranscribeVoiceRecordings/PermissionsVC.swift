//
//  ViewController.swift
//  TranscribeVoiceRecordings
//
//  Created by Sam Willsea on 12/30/16.
//  Copyright © 2016 Sam Willsea. All rights reserved.
//

import UIKit
import AVFoundation
import Speech
import Photos

class ViewController: UIViewController {
    
    @IBOutlet weak var decriptionLabel: UILabel!

    @IBAction func requestPermissions(_ sender: Any) {
        requestPhotoPermission()
    }
    
    func requestPhotoPermission() {
        PHPhotoLibrary.requestAuthorization { authstatus in
            DispatchQueue.main.async {
                self.processPhotoPermissionRequest(status: authstatus)
            }
        }
    }
    
    func processPhotoPermissionRequest(status: PHAuthorizationStatus) {
        if status == .authorized {
            self.requestRecordPermission()
        } else {
            self.decriptionLabel.text = "Photos permission was declined; please enable it in settings then tap Continue again."
        }
    }
    
    func requestRecordPermission() {
        AVAudioSession.sharedInstance().requestRecordPermission() { allowed in
            DispatchQueue.main.async {
                if allowed {
                    self.requestTranscribePermissions()
                } else {
                    self.decriptionLabel.text = "Recording permission was declined; please enable it in settings then tap Continue again."
                }
            }
        }
    }
    
    func requestTranscribePermissions() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                if authStatus == .authorized {
                    self.authorizationComplete()
                } else {
                    self.decriptionLabel.text = "Transcription permission was declined; please enable it in settings then tap Continue again."
                }
            }
        }
    }
    
    func authorizationComplete() {
        dismiss(animated: true)
    }

}

