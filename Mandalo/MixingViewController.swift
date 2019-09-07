//
//  MixingViewController.swift
//  Mandalo
//
//  Created by Robert on 07.09.19.
//  Copyright © 2019 Kevin Schaefer. All rights reserved.
//

import UIKit
import SceneKit

class MixingViewController: UIViewController {

    var requirements: Requirements? {
        didSet {
            updateCurrentMassToMeasure()
        }
    }

    private var currentPart = Requirements.Part.allCases.first

    @IBOutlet weak var sceneView: SCNView!

    @IBOutlet weak var instructionHeadlineLabel: UILabel!
    @IBOutlet weak var instructionDetailsLabel: UILabel!

    private var waterNode: SCNNode?
    private var polymerNode: SCNNode?
    private var cementNode: SCNNode?
    private var sandNode: SCNNode?

    private var measurer = MassProvider(servicer: MQTTServicer.shared)
    private var currentMassToMeasure: Measurement<UnitMass>?

    private let formatter: MeasurementFormatter = {
        let formatter = MeasurementFormatter()
        formatter.unitOptions = MeasurementFormatter.UnitOptions.providedUnit
        formatter.numberFormatter.maximumFractionDigits = 1
        return formatter
    }()

    private let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.percentSymbol = "%"
        formatter.numberStyle = .percent
        return formatter
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        let rootNode = sceneView.scene?.rootNode
        waterNode = rootNode?.childNode(withName: "water", recursively: false)
        polymerNode = rootNode?.childNode(withName: "polymer", recursively: false)
        cementNode = rootNode?.childNode(withName: "cement", recursively: false)
        sandNode = rootNode?.childNode(withName: "sand", recursively: false)

        waterNode?.isHidden = true
        polymerNode?.isHidden = true
        cementNode?.isHidden = true
        sandNode?.isHidden = true

        setPivotsAndSizesToZero()

        measurer.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        measurer.zero()
        self.currentPart = Requirements.Part.allCases.first
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        // For testing, we use the timer
        MQTTServicer.shared.timer?.invalidate()
    }

    private func fillInstructionLabels(for percentageDone: Double,
                                       massToMeasure: Measurement<UnitMass>,
                                       measurement: Measurement<UnitMass>) {
        if percentageDone >= 1 {
            updateCurrentPart()

            if let currentPart = currentPart {
                instructionHeadlineLabel.text = "Great job! Next, start filling the \(currentPart.rawValue)"
            } else {
                // Done with recipe!
            }
        } else if let currentPart = currentPart {
            instructionHeadlineLabel.text = "\(numberFormatter.string(from: NSNumber(value: percentageDone))!) of \(currentPart.rawValue) filled. Still need \(formatter.string(from: massToMeasure - measurement))"
        }
    }

    private func updateCurrentPart() {
        guard let currentPart = self.currentPart
            else { return }

        guard let index = Requirements.Part.allCases.firstIndex(of: currentPart), index + 1 != Requirements.Part.allCases.endIndex
            else { self.currentPart = nil; self.currentMassToMeasure = nil; return }

        self.currentPart = Requirements.Part.allCases[index + 1]

        updateCurrentMassToMeasure()
        measurer.zero()
    }

    private func updateViews(for percentageDone: Double) {
        guard let currentPart = self.currentPart
            else { return }

        let node: SCNNode?

        switch currentPart {
        case .sand:
            node = self.sandNode
        case .cement:
            node = self.cementNode
        case .polymer:
            node = self.polymerNode
        case .water:
            node = self.waterNode
        }

        node?.isHidden = false
        self.setNodeGeometry(geometry: node?.geometry, node: node, percentageDone: percentageDone, currentPart: currentPart)
    }

    private func setNodeGeometry(geometry: SCNGeometry?, node: SCNNode?, percentageDone: Double, currentPart: Requirements.Part) {
        guard let cylinder = geometry as? SCNCylinder, let pivot = node?.pivot
            else { return }

        let fullHeight: CGFloat

        switch currentPart {
        case .sand:
            fullHeight = 0.4
        case .cement:
            fullHeight = 0.6
        case .polymer:
            fullHeight = 0.1
        case .water:
            fullHeight = 0.5
        }

        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.2
        let newHeight = CGFloat(min(percentageDone, 1)) * fullHeight
        let delta = newHeight - cylinder.height
        cylinder.height = newHeight
        node?.position.y += Float(delta) / 2
        SCNTransaction.commit()
    }

    private func updateCurrentMassToMeasure() {
        guard let currentPart = self.currentPart
            else { return }

        switch currentPart {
        case .sand:
            self.currentMassToMeasure = self.requirements?.sand
        case .cement:
            self.currentMassToMeasure = self.requirements?.cement
        case .polymer:
            self.currentMassToMeasure = self.requirements?.polymer
        case .water:
            self.currentMassToMeasure = self.requirements?.water
        }
    }

    private func setPivotsAndSizesToZero() {
        func setGeometryHeightToZero(node: SCNNode?) {
            guard let cylinder = node?.geometry as? SCNCylinder, let currentPart = self.currentPart
                else { return }
            cylinder.height = 0

            let fullHeight: CGFloat

            switch currentPart {
            case .sand:
                fullHeight = 0.4
            case .cement:
                fullHeight = 0.6
            case .polymer:
                fullHeight = 0.1
            case .water:
                fullHeight = 0.5
            }

            node?.position.y -= Float(fullHeight) / 2
        }

        setGeometryHeightToZero(node: self.waterNode)
        setGeometryHeightToZero(node: self.cementNode)
        setGeometryHeightToZero(node: self.polymerNode)
        setGeometryHeightToZero(node: self.sandNode)
    }
}

extension MixingViewController: MassProviderDelegate {
    func didReceiveZeroedMass(mass: Double) {
        guard let currentMassToMeasure = self.currentMassToMeasure
            else { return }

        let measure = Measurement.init(value: mass, unit: UnitMass.grams)
        let percentageDone = measure.converted(to: .grams).value / currentMassToMeasure.converted(to: .grams).value

        DispatchQueue.main.async {
            self.fillInstructionLabels(for: percentageDone, massToMeasure: currentMassToMeasure, measurement: measure)
            self.updateViews(for: percentageDone)
        }
    }
}
