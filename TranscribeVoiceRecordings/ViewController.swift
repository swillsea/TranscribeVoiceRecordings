//
//  ViewController.swift
//  TranscribeVoiceRecordings
//
//  Created by Sam Willsea on 12/30/16.
//  Copyright © 2016 Sam Willsea. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var decriptionLabel: UILabel!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func requestPermissions(_ sender: Any) {
    }

}

