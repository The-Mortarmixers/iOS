//
//  ScanViewController.swift
//  Mandalo
//
//  Created by Kevin Schaefer on 06.09.19.
//  Copyright © 2019 Kevin Schaefer. All rights reserved.
//

import UIKit
import AVFoundation

class ScanViewController: UIViewController {

    fileprivate var avCaptureSession: AVCaptureSession?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.prefersLargeTitles = true
    }

    override func viewWillAppear(_ animated: Bool) {
        setUpCaptureSession()
    }

    fileprivate func setUpCaptureSession() {
        guard avCaptureSession == nil else {
            avCaptureSession?.startRunning()
            return
        }

        let session = AVCaptureSession()
        // We don't need to control audio and video output settings
        session.sessionPreset = AVCaptureSession.Preset.inputPriority

        // Get the current camera and from that derive an input
        let camera = AVCaptureDevice.default(for: AVMediaType.video)
        let input = try? AVCaptureDeviceInput(device: camera!)

        guard input != nil else { return }

        // We need still image and data output to show and analyze the images
        let output = AVCapturePhotoOutput()
        let dataOutput = AVCaptureVideoDataOutput()

        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue.global(qos: .default))

        guard session.canAddInput(input!) && session.canAddOutput(output) && session.canAddOutput(dataOutput) else { return }

        // Add inputs and outputs to our session
        session.addInput(input!)
        session.addOutput(output)
        session.addOutput(dataOutput)

        // Determine the preview layer which will be shown to the user
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill

        // We do not want the previewLayer to be resized, but rather want it to be cut
        // so that only a given window is shown
        previewLayer.frame = view.bounds
        view.layer.masksToBounds = true

        previewLayer.connection?.videoOrientation = .portrait

        // Add the preview layer to our view and start the session
        view.layer.addSublayer(previewLayer)
        session.startRunning()
        self.avCaptureSession = session
    }
}


extension ScanViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let pixelBufferOptional = CMSampleBufferGetImageBuffer(sampleBuffer)

        guard let pixelBuffer = pixelBufferOptional else { return }

        let image = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        let detector = CIDetector.init(ofType: CIDetectorTypeQRCode, context: context, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])

        let featuresOptional = detector?.features(in: image)

        guard let features = featuresOptional, features.count > 0 else { return }

        guard let qrString = (features.first as? CIQRCodeFeature)?.messageString else { return }
        print(qrString)

        if qrString == "Techfest19" {
            avCaptureSession?.stopRunning()
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.performSegue(withIdentifier: "QRCodeScannedSegue", sender: nil)
            }
        }
    }
}
