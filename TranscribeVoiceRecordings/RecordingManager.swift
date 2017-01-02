//
//  RecordingManager.swift
//  TranscribeVoiceRecordings
//
//  Created by Sam Willsea on 1/2/17.
//  Copyright © 2017 Sam Willsea. All rights reserved.
//

import Foundation
import AVFoundation
import Speech

class RecordingManager: NSObject, AVAudioRecorderDelegate {
    
    static let sharedInstance: RecordingManager = RecordingManager()
    
    override private init() {}

    var audioRecorder: AVAudioRecorder?
    var recordingURL: URL! = getDocumentsDirectory().appendingPathComponent("recording.m4a")
    var audioPlayer: AVAudioPlayer?
    
    var activeMemory: URL!

    func beginRecording() {
        audioPlayer?.stop()
        
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord, with: .defaultToSpeaker)
            try AVAudioSession.sharedInstance().setActive(true)
            
            let settings = [ AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                             AVSampleRateKey: 44100,
                             AVNumberOfChannelsKey: 2,
                             AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue]
            
            audioRecorder = try AVAudioRecorder(url: recordingURL, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
        } catch let error {
            print("Failed to record: \(error)")
            finishRecording(success: false)
        }
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            finishRecording(success: false) //might happen if a phone call interrupts recording
        }
    }
    
    
    func finishRecording(success: Bool) {
        
        audioRecorder?.stop()
        guard success else { return }
        
        do {
            let memoryAudioURL = activeMemory.appendingPathExtension("m4a")
            print(memoryAudioURL)
            
            if FileManager.default.fileExists(atPath: memoryAudioURL.path) {
                try FileManager.default.removeItem(at: memoryAudioURL)
            }
            
            try FileManager.default.moveItem(at: recordingURL, to: memoryAudioURL)
            
            transcribeAudio(memory: activeMemory)
        } catch let error {
            print("Failed to complete recording: \(error)")
        }
    }
    
    func transcribeAudio(memory: URL) {
        
        let recognizer = SFSpeechRecognizer()
        let request = SFSpeechURLRecognitionRequest(url: audioURL(for: memory))
        
        recognizer?.recognitionTask(with: request){ [unowned self] result, error in
            guard let result = result else {
                print("there was an error: \(error!)")
                return
            }
            
            if result.isFinal {
                self.saveTranscription(result: result, forMemory: memory)
            }
        }
    }
    
    func saveTranscription(result: SFSpeechRecognitionResult, forMemory memory: URL) {
        let text = result.bestTranscription.formattedString
        let url =  transcriptionURL(for: memory)
        
        do {
            try text.write(to: url, atomically: true, encoding: .utf8)
            SpotlightManager.indexForSearch(memory: memory, text: text)
        } catch {
            print("Failed to save transcription")
        }
        
    }
    
    //Audio Playback
    func playAudio(forMemory memory: URL) {
        do {
            let audioName = audioURL(for: memory)
            if FileManager.default.fileExists(atPath: audioName.path) {
                audioPlayer = try AVAudioPlayer(contentsOf: audioName)
                audioPlayer?.play()
            }
            try printTranscription(forMemory: memory)
        } catch {
            print("Error loading audio")
        }
    }
    
    func printTranscription(forMemory memory: URL) throws {
        let transcriptionName = transcriptionURL(for: memory)
        if FileManager.default.fileExists(atPath: transcriptionName.path) {
            let contents = try String(contentsOf: transcriptionName)
            print(contents)
        }
    }
    
}
