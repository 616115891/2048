//
//  ViewController.swift
//  2048
//
//  Created by apple on 16/7/12.
//  Copyright © 2016年 Keyon. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
    }

    @IBAction func startGame(sender: AnyObject) {
    let controller = NumberTileGame(dimension: 4, threshold: 2048)
        self.presentViewController(controller, animated: true, completion: nil)
        print("尼玛炸了")
    }

}

