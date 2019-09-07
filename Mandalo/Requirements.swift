//
//  Requirements.swift
//  Mandalo
//
//  Created by Robert on 07.09.19.
//  Copyright © 2019 Kevin Schaefer. All rights reserved.
//

import Foundation

struct Requirements {
    let sand: Measurement<UnitMass>
    let cement: Measurement<UnitMass>
    let polymer: Measurement<UnitMass>
    let water: Measurement<UnitMass>

    enum Part: String, CaseIterable {
        case sand
        case cement
        case polymer
        case water
    }
}
