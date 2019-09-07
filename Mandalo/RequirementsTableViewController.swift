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

    private struct Requirements {
        let sand: Measurement<UnitMass>
        let cement: Measurement<UnitMass>
        let polymer: Measurement<UnitMass>
        let water: Measurement<UnitMass>
    }

    @IBOutlet weak var sceneView: SCNView!
    @IBOutlet weak var volumeLabel: UILabel!
    @IBOutlet weak var depthLabel: UILabel!
    @IBOutlet weak var heightLabel: UILabel!
    @IBOutlet weak var widthLabel: UILabel!
    @IBOutlet weak var areaLabel: UILabel!
    @IBOutlet weak var sandMassLabel: UILabel!
    @IBOutlet weak var cementMassLabel: UILabel!
    @IBOutlet weak var polymerMassLabel: UILabel!
    @IBOutlet weak var waterMassLabel: UILabel!
    @IBOutlet weak var totalMassLabel: UILabel!

    @IBOutlet weak var sandContentView: UIView!
    @IBOutlet weak var cementContentView: UIView!
    @IBOutlet weak var polymerContentView: UIView!
    @IBOutlet weak var waterContentView: UIView!
    

    var measurements: Measurements?

    private var depth: Measurement<UnitLength> {
        return Measurement(value: Double(self.currentDepth), unit: .meters)
    }

    private var volume: Measurement<UnitVolume> = Measurement(value: 0, unit: .liters)
    private var requirements: Requirements?

    private var currentDepth: CGFloat = 0.03 {
        didSet {
            self.didUpdateDepth(depth: self.depth)
        }
    }

    private static let depthCoefficient: CGFloat = 10
    private let maximumDepth: CGFloat = 0.1
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

        let xTranslation = recognizer.translation(in: self.sceneView).x * 0.5
        box.width = max(min(self.currentDepth + xTranslation / translationCoefficient, maximumDepth), minimumDepth) * RequirementsTableViewController.depthCoefficient
        self.didUpdateDepth(depth: Measurement(value: Double(box.width / RequirementsTableViewController.depthCoefficient), unit: .meters))
    }

    private func didUpdateDepth(depth: Measurement<UnitLength>) {
        depthLabel.text = "Tiefe:\t\t\(formatter.string(from: depth.converted(to: .centimeters)))"
        setVolume(depth: depth)
    }

    private func setupLabels() {
        guard let measurements = self.measurements
            else { return }

        self.depthLabel.text = "Tiefe:\t\t\(formatter.string(from: self.depth.converted(to: .centimeters)))"
        self.heightLabel.text = "Höhe:\t\t\(formatter.string(from: measurements.height.converted(to: .centimeters)))"
        self.widthLabel.text = "Breite:\t\t\(formatter.string(from: measurements.width.converted(to: .centimeters)))"
        let area = measurements.height.converted(to: .meters).value * measurements.width.converted(to: .meters).value
        self.areaLabel.text = "Fläche:\t\t\(formatter.string(from: Measurement(value: area, unit: UnitArea.squareMeters)))"
        setVolume(depth: self.depth)
    }

    private func setVolume(depth: Measurement<UnitLength>) {
        guard let measurements = self.measurements
            else { return }

        let volumeValue = measurements.height.converted(to: .decimeters).value * measurements.width.converted(to: .decimeters).value * depth.converted(to: .decimeters).value

        self.volume = Measurement(value: volumeValue, unit: UnitVolume.liters)
        self.volumeLabel.text = formatter.string(from: volume)
        self.calculateRequirements(volume: self.volume)
    }

    private func calculateRequirements(volume: Measurement<UnitVolume>) {
        let total = 12 + 3 + 0.1 + 0.4

        let literVolume = volume.converted(to: .liters).value
        let sandPart = 12 * Measurement(value: literVolume, unit: UnitMass.kilograms) / total
        let cementPart = 3 * Measurement(value: literVolume, unit: UnitMass.kilograms) / total
        let polymerPart = 0.1 * Measurement(value: literVolume, unit: UnitMass.kilograms) / total
        let waterPart = 0.4 * Measurement(value: literVolume, unit: UnitMass.kilograms) / total

        self.requirements = Requirements(sand: sandPart, cement: cementPart, polymer: polymerPart, water: waterPart)
        self.presentRequirements()
    }

    private func presentRequirements() {
        guard let requirements = self.requirements
            else { return }

        self.sandMassLabel.text = formatter.string(from: requirements.sand)
        self.cementMassLabel.text = formatter.string(from: requirements.cement)
        self.polymerMassLabel.text = formatter.string(from: requirements.polymer)
        self.waterMassLabel.text = formatter.string(from: requirements.water)

        self.totalMassLabel.text = formatter.string(from: requirements.sand + requirements.cement + requirements.polymer + requirements.water)
    }
}
