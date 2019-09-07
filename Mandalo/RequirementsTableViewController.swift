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

    var measurements: Measurements?

    private let maximumWidth: CGFloat = 0.3
    private var currentWidth: CGFloat = 0.03
    private let minimumWidth: CGFloat = 0.002
    private let translationCoefficient: CGFloat = 300.0

    override func viewDidLoad() {
        super.viewDidLoad()
        self.addPanGestureRecognizer()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 0
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
            currentWidth = box.width
            return
        }

        let xTranslation = recognizer.translation(in: self.sceneView).x
        box.width = max(min(currentWidth + xTranslation / translationCoefficient, maximumWidth), minimumWidth)
    }

}
