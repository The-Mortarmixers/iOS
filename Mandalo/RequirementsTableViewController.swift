//
//  RequirementsTableViewController.swift
//  Mandalo
//
//  Created by Robert on 07.09.19.
//  Copyright © 2019 Kevin Schaefer. All rights reserved.
//

import UIKit
import SceneKit

class RequirementsTableViewController: UITableViewController {

    @IBOutlet weak var sceneView: SCNView!
    @IBOutlet weak var volumeLabel: UILabel!
    @IBOutlet weak var depthLabel: UILabel!
    @IBOutlet weak var heightLabel: UILabel!
    @IBOutlet weak var widthLabel: UILabel!
    @IBOutlet weak var areaLabel: UILabel!

    var measurements: Measurements?

    private var depth: Measurement<UnitLength> {
        return Measurement(value: Double(self.currentDepth), unit: .meters)
    }

    private var currentDepth: CGFloat = 0.03 {
        didSet {
            self.didUpdateDepth(depth: self.depth)
        }
    }

    private static let depthCoefficient: CGFloat = 2
    private let maximumDepth: CGFloat = 0.3
    private let minimumDepth: CGFloat = 0.002
    private let translationCoefficient: CGFloat = 800.0
    private let formatter: MeasurementFormatter = {
        let formatter = MeasurementFormatter()
        formatter.unitOptions = MeasurementFormatter.UnitOptions.providedUnit
        formatter.numberFormatter.maximumFractionDigits = 1
        return formatter
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.addPanGestureRecognizer()
        self.setupLabels()
    }


    private func getWallNode() -> SCNNode? {
        let rootNode = sceneView.scene?.rootNode
        return rootNode?.childNodes.first { $0.name == "box" }
    }

    private func addPanGestureRecognizer() {
        let recognizer = UIPanGestureRecognizer(target: self, action: #selector(didRecognizePan))
        self.sceneView.addGestureRecognizer(recognizer)
    }

    @objc private func didRecognizePan(recognizer: UIPanGestureRecognizer) {
        guard let box = getWallNode()?.geometry as? SCNBox
            else { return }

        if recognizer.state == .cancelled || recognizer.state == .ended || recognizer.state == .failed {
            self.currentDepth = box.width / RequirementsTableViewController.depthCoefficient
            return
        }

        let xTranslation = recognizer.translation(in: self.sceneView).x
        box.width = max(min(self.currentDepth + xTranslation / translationCoefficient, maximumDepth), minimumDepth) * RequirementsTableViewController.depthCoefficient
        self.didUpdateDepth(depth: Measurement(value: Double(box.width / RequirementsTableViewController.depthCoefficient), unit: .meters))
    }

    private func didUpdateDepth(depth: Measurement<UnitLength>) {
        depthLabel.text = "Tiefe:\t\t\(formatter.string(from: depth.converted(to: .centimeters)))"
        setVolumeLabel(depth: depth)
    }

    private func setupLabels() {
        guard let measurements = self.measurements
            else { return }

        self.depthLabel.text = "Tiefe:\t\t\(formatter.string(from: self.depth.converted(to: .centimeters)))"
        self.heightLabel.text = "Höhe:\t\t\(formatter.string(from: measurements.height.converted(to: .centimeters)))"
        self.widthLabel.text = "Breite:\t\t\(formatter.string(from: measurements.width.converted(to: .centimeters)))"
        let area = measurements.height.converted(to: .meters).value * measurements.width.converted(to: .meters).value
        self.areaLabel.text = "Fläche:\t\t\(formatter.string(from: Measurement(value: area, unit: UnitArea.squareMeters)))"
        setVolumeLabel(depth: self.depth)
    }

    private func setVolumeLabel(depth: Measurement<UnitLength>) {
        guard let measurements = self.measurements
            else { return }

        let volume = measurements.height.converted(to: .decimeters).value * measurements.width.converted(to: .decimeters).value * depth.converted(to: .decimeters).value
        self.volumeLabel.text = "\(formatter.string(from: Measurement(value: volume, unit: UnitVolume.liters)))"
    }
}
