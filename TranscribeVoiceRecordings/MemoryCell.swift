//
//  MemoryCell.swift
//  TranscribeVoiceRecordings
//
//  Created by Sam Willsea on 12/30/16.
//  Copyright © 2016 Sam Willsea. All rights reserved.
//

import UIKit

class MemoryCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    
    override func awakeFromNib() {
        self.layer.borderColor = UIColor.white.cgColor
        self.layer.borderWidth = 3
        self.layer.cornerRadius = 10
    }
}
