//
//  MemoriesViewController.swift
//  TranscribeVoiceRecordings
//
//  Created by Sam Willsea on 12/30/16.
//  Copyright © 2016 Sam Willsea. All rights reserved.
//

import UIKit
import Photos
import Speech
import CoreSpotlight
import MobileCoreServices

class MemoriesViewController: UICollectionViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UICollectionViewDelegateFlowLayout, UISearchBarDelegate {
    
    var allMemories = [URL]()
    var filteredMemories = [URL]()
    
    var searchQuery: CSSearchQuery?

    override func viewDidLoad() {
        super.viewDidLoad()
        loadMemories()
        setupNavBar()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkPermissions()
    }
    
    private func setupNavBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addImage))
    }
    
    
    // CollectionView
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return section == 0 ? 0 : filteredMemories.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        return collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "Header", for: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return section == 1 ? CGSize.zero : CGSize(width: 0, height: 50)
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let memory = filteredMemories[indexPath.row]
        RecordingManager.sharedInstance.playAudio(forMemory: memory)
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Memory", for: indexPath) as! MemoryCell
        setImage(forCell: cell, at: indexPath)
        addGestureRecognizer(toCell: cell)
        return cell
    }
    
    private func setImage(forCell cell: MemoryCell, at indexPath: IndexPath) {
        let memory = filteredMemories[indexPath.row]
        let imageName = thumbnailURL(for: memory).path
        let image = UIImage(contentsOfFile: imageName)
        cell.imageView.image = image
    }
    
    private func addGestureRecognizer(toCell cell: MemoryCell) {
        let recognizer = UILongPressGestureRecognizer(target: self, action: #selector(cellRecievedLongPress))
        recognizer.minimumPressDuration = 0.25
        cell.addGestureRecognizer(recognizer)
    }
    
    func cellRecievedLongPress(sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            let cell = sender.view as! MemoryCell
            if let index = collectionView?.indexPath(for: cell) {
                collectionView?.backgroundColor = .red
                RecordingManager.sharedInstance.activeMemory = filteredMemories[index.row]
                RecordingManager.sharedInstance.beginRecording()
            }
            
        } else if sender.state == .ended {
            collectionView?.backgroundColor = .darkGray
            RecordingManager.sharedInstance.finishRecording(success: true)
        }
    }
    
    // In-App searching
    internal func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filterMemories(text: searchText)
    }
    
    internal func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    private func filterMemories(text: String) {
        
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
    
    private func activateFilter(forMatches matches: [CSSearchableItem]) {
        filteredMemories = matches.map { item in
            return URL(fileURLWithPath: item.uniqueIdentifier)
        }
        
        UIView.performWithoutAnimation {
            collectionView?.reloadSections(IndexSet(integer: 1))
        }
    }
    
    // Image handling
    func addImage() {
        let imageController = UIImagePickerController()
        imageController.modalPresentationStyle = .formSheet
        imageController.delegate = self
        navigationController?.present(imageController, animated: true)
    }
    
    internal func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        dismiss(animated: true)
        
        if let possibleImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            saveNewMemory(image: possibleImage)
            loadMemories()
        }
    }
    
    
    // Data source
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
    
    func saveNewMemory(image: UIImage) {
        let memoryName = "memory-\(Date().timeIntervalSince1970)"
        
        do {
            let jpegPath = getDocumentsDirectory().appendingPathComponent(memoryName + ".jpg")
            if let jpegData = UIImageJPEGRepresentation(image, 80) {
                try jpegData.write(to: jpegPath, options: [.atomicWrite])
            }
            
            let thumbPath = getDocumentsDirectory().appendingPathComponent(memoryName + ".thumb")
            if let thumbnail = image.resized(toWidth: 200), let jpegData = UIImageJPEGRepresentation(thumbnail, 80) {
                try jpegData.write(to: thumbPath, options: [.atomicWrite])
            }
        } catch {
            print("Failed to save to disk")
        }
    }
    
    
    
    // Permissions
    private func checkPermissions() {
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


