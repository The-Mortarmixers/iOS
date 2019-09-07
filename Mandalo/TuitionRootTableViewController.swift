//
//  TuitionRootTableViewController.swift
//  Mandalo
//
//  Created by Robert on 07.09.19.
//  Copyright © 2019 Kevin Schaefer. All rights reserved.
//

import UIKit

class TuitionRootTableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.performSegue(withIdentifier: "showRequirementsSegue", sender: nil)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        if let destination = segue.destination as? RequirementsTableViewController {
            destination.measurements = Measurements(height: Measurement(value: 2, unit: .meters), width: Measurement(value: 4, unit: .meters))
        }
    }
}
