//
//  MassProvider.swift
//  Mandalo
//
//  Created by Robert on 07.09.19.
//  Copyright © 2019 Kevin Schaefer. All rights reserved.
//

import Foundation

class MassProvider: MQTTServicerDelegate {

    var delegate: MassProviderDelegate?

    private var lastAbsoluteMeasure: Double = 0
    private var zeroMeasure: Double = 0
    private var wasZeroed: Bool = false

    init(servicer: MQTTServicer) {
        servicer.add(delegate: self)
    }

    func zero() {
        zeroMeasure = lastAbsoluteMeasure
        wasZeroed = true
    }

    func didReceiveMass(mass: Double) {
        lastAbsoluteMeasure = mass

        guard wasZeroed
            else { return }

        delegate?.didReceiveZeroedMass(mass: mass - zeroMeasure)
    }
}

protocol MassProviderDelegate {
    func didReceiveZeroedMass(mass: Double)
}
