//
//  VideoView.swift
//  VideoTransparentBackground
//
//  Created by Andrey Gordeev on 6/11/17.
//  Copyright © 2017 Andrey Gordeev (andrew8712@gmail.com). All rights reserved.
//

import UIKit
import GPUImage
import AVFoundation

class VideoView: GPUImageView {

    var movie: GPUImageMovie!
    var filter: GPUImageChromaKeyBlendFilter!
    var sourcePicture: GPUImagePicture!
    var firstImage: GPUImagePicture!
    var player = AVPlayer()
    var currentFilename: String?

    var isPlaying = false

    override func awakeFromNib() {
        super.awakeFromNib()
        customInit()
    }

    func customInit() {
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(play))
        addGestureRecognizer(gestureRecognizer)
        backgroundColor = UIColor.clear
    }

    func configure(fileName: String) {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "mp4") else { return }
        guard fileName != currentFilename else { return }
        currentFilename = fileName
        if let currentItem = player.currentItem {
            NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: currentItem)
        }
        let playerItem = AVPlayerItem(url: url)
        player.replaceCurrentItem(with: playerItem)

        NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinishPlaying(_:)), name: .AVPlayerItemDidPlayToEndTime, object: playerItem)

        filter = GPUImageChromaKeyBlendFilter()
        filter.thresholdSensitivity = 0.15
        filter.smoothing = 0.3
        filter.setColorToReplaceRed(1, green: 0, blue: 1)

        /// Getting video frame size and setting appropriate constraints.
        if let cgImage = thumbnailImage(url: url) {
            let scale = 1.0 / UIScreen.main.scale
            setConstraint(constant: CGFloat(cgImage.width) * scale, attribute: .width)
            setConstraint(constant: CGFloat(cgImage.height) * scale, attribute: .height)
        }

        movie = GPUImageMovie(playerItem: playerItem)
        movie.playAtActualSpeed = true
        movie.addTarget(filter)
        movie.startProcessing()

        let backgroundImage = UIImage(named: "transparent.png")
        sourcePicture = GPUImagePicture(image: backgroundImage, smoothlyScaleOutput: true)!
        sourcePicture.addTarget(filter)
        sourcePicture.processImage()

        filter.addTarget(self)
    }

    func play() {
        guard !isPlaying else { return }
        player.seek(to: kCMTimeZero)
        player.play()
        isPlaying = true
    }

    func stop() {
        player.pause()
        isPlaying = false
    }

    func playerDidFinishPlaying(_ notification: Notification) {
        guard player.currentItem == notification.object as? AVPlayerItem else { return }
        // Call player.seek(to: kCMTimeZero) if you want to make the first frame visible after playback is completed.
        isPlaying = false
    }

    private func thumbnailImage(url: URL) -> CGImage? {
        let asset = AVURLAsset(url: url)
        let assetGenerator = AVAssetImageGenerator(asset: asset)
        assetGenerator.appliesPreferredTrackTransform = true
        assetGenerator.apertureMode = AVAssetImageGeneratorApertureModeEncodedPixels
        let time = CMTimeMakeWithSeconds(1.0, 1)
        var actualTime: CMTime = CMTimeMake(0, 0)
        let cgImage = try? assetGenerator.copyCGImage(at: time, actualTime: &actualTime)
        return cgImage
    }

    // MARK: - Constraints

    private func getConstraint(attribute: NSLayoutAttribute) -> NSLayoutConstraint? {
        return constraints.first(where: {$0.identifier == "attribute\(attribute.rawValue)"})
    }

    private func setConstraint(constant: CGFloat, attribute: NSLayoutAttribute) {
        if let constraint = getConstraint(attribute: attribute) {
            constraint.constant = constant
        } else {
            let constraint = NSLayoutConstraint(item: self, attribute: attribute, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: constant)
            constraint.priority = 999
            constraint.identifier = "attribute\(attribute.rawValue)"
            addConstraint(constraint)
        }
    }
}
