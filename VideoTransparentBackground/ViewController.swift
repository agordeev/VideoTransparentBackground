//
//  ViewController.swift
//  VideoTransparentBackground
//
//  Created by Andrey Gordeev on 6/11/17.
//  Copyright © 2017 Andrey Gordeev (andrew8712@gmail.com). All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var videoView: VideoView!

    override func viewDidLoad() {
        super.viewDidLoad()

        videoView.configure(fileName: "video")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        DispatchQueue.main.asyncAfter(
            deadline: DispatchTime.now() + Double(Int64(10.0 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: {
                self.videoView.play()
        })
    }
}

