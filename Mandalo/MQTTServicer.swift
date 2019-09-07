//
//  MQTTServicer.swift
//  Mandalo
//
//  Created by Robert on 07.09.19.
//  Copyright © 2019 Kevin Schaefer. All rights reserved.
//

import Foundation
import CocoaMQTT

class MQTTServicer {

    static let shared = MQTTServicer()

    private let mqtt: CocoaMQTT
    private static let mqttHost = "172.20.10.4"
    private static let mqttPort = 1883
    private let mixerStatusTopic = "mixer/status"
    private let mixerMassTopic = "mixer/mass"
    private(set) var isConnected = false
    private var delegates: [MQTTServicerDelegate] = []

    private init() {
        self.mqtt = CocoaMQTT(clientID: "App-" + String(ProcessInfo().processIdentifier),
                              host: MQTTServicer.mqttHost,
                              port: UInt16(MQTTServicer.mqttPort))
        self.mqtt.enableSSL = false
        self.mqtt.username = ""
        self.mqtt.password = ""
        self.mqtt.keepAlive = 3600
        self.mqtt.autoReconnect = true
        self.mqtt.willMessage = CocoaMQTTWill(topic: "/will", message: "dieout")
        self.mqtt.logLevel = .debug

        self.mqtt.didPublishMessage = { _, message, _ in
            print("Did publish Message: \(message.string) to topic: \(message.topic)")
        }
    }

    func reconnect() {
        guard !isConnected
            else { return }

        self.isConnected = self.mqtt.connect()
    }

    func beginReceivingMass() {
        mqtt.subscribe(self.mixerMassTopic)

        self.mqtt.didReceiveMessage = { [weak self] (mqtt, message, x) in
            mqtt.didReceiveMessage(mqtt, message, x)

            print("Did receive MQTT message on topic: \(message.topic), message: \(message.string)")

            if message.topic == self?.mixerMassTopic,
                let massString = message.string,
                let mass = Double(massString) {
                self?.delegates.forEach { $0.didReceiveMass(mass: mass) }
            }
        }
    }

    func sendStatus(status: Bool) {
        mqtt.publish(mixerStatusTopic, withString: status ? "ON" : "OFF", qos: .qos1)
    }

    func add(delegate: MQTTServicerDelegate) {
        delegates.append(delegate)
    }
}

protocol MQTTServicerDelegate: class {
    func didReceiveMass(mass: Double)
}
