//
//  MandaloButton.swift
//  Mandalo
//
//  Created by Kevin Schaefer on 07.09.19.
//  Copyright © 2019 Kevin Schaefer. All rights reserved.
//

import UIKit

class MandaloButton: UIButton {
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        self.layer.cornerRadius = self.frame.size.height / 2.0
        self.clipsToBounds = true
    }

}
