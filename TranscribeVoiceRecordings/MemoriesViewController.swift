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
import CoreSpotlight
import MobileCoreServices

class MemoriesViewController: UICollectionViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UICollectionViewDelegateFlowLayout, AVAudioRecorderDelegate, UISearchBarDelegate {
    
    var allMemories = [URL]()
    var filteredMemories = [URL]()
    var activeMemory: URL!
    
    var searchQuery: CSSearchQuery?
    
    var audioRecorder: AVAudioRecorder?
    var recordingURL: URL!
    
    var audioPlayer: AVAudioPlayer?

    override func viewDidLoad() {
        super.viewDidLoad()
        loadMemories()
        setupNavBar()
        recordingURL = getDocumentsDirectory().appendingPathComponent("recording.m4a")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkPermissions()
    }
    
    func setupNavBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addImage))
    }
    
    
    // CollectionView
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 0
        default:
            return filteredMemories.count
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Memory", for: indexPath) as! MemoryCell
        setImage(forCell: cell, at: indexPath)
        addGestureRecognizer(toCell: cell)
        
        cell.layer.borderColor = UIColor.white.cgColor
        cell.layer.borderWidth = 3
        cell.layer.cornerRadius = 10
        
        return cell
    }
    
    func setImage(forCell cell: MemoryCell, at indexPath: IndexPath) {
        let memory = filteredMemories[indexPath.row]
        let imageName = thumbnailURL(for: memory).path
        let image = UIImage(contentsOfFile: imageName)
        cell.imageView.image = image
    }
    
    func addGestureRecognizer(toCell cell: MemoryCell) {
        let recognizer = UILongPressGestureRecognizer(target: self, action: #selector(memoryLongPress))
        recognizer.minimumPressDuration = 0.25
        cell.addGestureRecognizer(recognizer)
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        return collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "Header", for: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return section == 1 ? CGSize.zero : CGSize(width: 0, height: 50)
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let memory = filteredMemories[indexPath.row]
        playAudio(forMemory: memory)
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
    
    
    // Memory Recording
    
    func memoryLongPress(sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            let cell = sender.view as! MemoryCell
            if let index = collectionView?.indexPath(for: cell) {
                activeMemory = filteredMemories[index.row]
                beginRecording()
            }
            
        } else if sender.state == .ended {
            finishRecording(success: true)
        }
    }
    
    func beginRecording() {
        collectionView?.backgroundColor = .red
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
        collectionView?.backgroundColor = .darkGray
        
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
        let url =  self.transcriptionURL(for: memory)
        
        do {
            try text.write(to: url, atomically: true, encoding: .utf8)
            self.indexForSearch(memory: memory, text: text)
        } catch {
            print("Failed to save transcription")
        }
        
    }
    
    // Core Spotlight
    func indexForSearch(memory: URL, text: String) {
        
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
    
    // In-App searching
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filterMemories(text: searchText)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func filterMemories(text: String) {
        
        guard text.characters.count > 0 else {
            filteredMemories = allMemories
            UIView.performWithoutAnimation {
                collectionView?.reloadSections(IndexSet(integer: 1))
            }
            return
        }
        
        var allMatchingItems = [CSSearchableItem]()
        
        searchQuery?.cancel() // If the user keeps typing, we cancel the last search before researching
        
        // *\(text)* means any content, then the search text then any content. The c means case insensitive
        let queryString = "contentDescription == \"*\(text)*\"c"
        searchQuery = CSSearchQuery(queryString: queryString, attributes: nil)
        
        searchQuery?.foundItemsHandler = { items in
            allMatchingItems.append(contentsOf: items)
        }
        
        searchQuery?.completionHandler = { error in
            DispatchQueue.main.async { [unowned self] in
                self.activateFilter(forMatches: allMatchingItems)
            }
        }
    }
    
    func activateFilter(forMatches matches: [CSSearchableItem]) {
        filteredMemories = matches.map { item in
            return URL(fileURLWithPath: item.uniqueIdentifier)
        }
        
        UIView.performWithoutAnimation {
            collectionView?.reloadSections(IndexSet(integer: 1))
        }
    }
    
    // Image handling
    func addImage() {
        let vc = UIImagePickerController()
        vc.modalPresentationStyle = .formSheet
        vc.delegate = self
        navigationController?.present(vc, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        dismiss(animated: true)
        
        if let possibleImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            saveNewMemory(image: possibleImage)
            loadMemories()
        }
    }
    
    
    // Data source

    func saveNewMemory(image: UIImage) {
        let memoryName = "memory-\(Date().timeIntervalSince1970)"
        let imageName = memoryName + ".jpg"
        let thumbnailName = memoryName + ".thumb"
        
        do {
            
            let imagePath = getDocumentsDirectory().appendingPathComponent(imageName)
            if let jpegData = UIImageJPEGRepresentation(image, 80) {
                try jpegData.write(to: imagePath, options: [.atomicWrite])
            }
            
            if let thumbnail = image.resized(toWidth: 200) {
                let imagePath = getDocumentsDirectory().appendingPathComponent(thumbnailName)
                if let jpegData = UIImageJPEGRepresentation(thumbnail, 80) {
                    try jpegData.write(to: imagePath, options: [.atomicWrite])
                }
            }
            
        } catch {
            print("Failed to save to disk")
        }
    }
    
    func loadMemories() {
        allMemories.removeAll()
        
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
                allMemories.append(memoryPath)
            }
        }
        
        filteredMemories = allMemories
        // only reload memories - ignore section[0] (search bar)
        collectionView?.reloadSections(IndexSet(integer: 1))
    }

    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    
    // Permissions
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
}



extension UIImage {
    func resized(toWidth width: CGFloat) -> UIImage? {
        let scale = width / self.size.width
        let height = self.size.height * scale
        
        UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), false, 0)
        self.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
}
