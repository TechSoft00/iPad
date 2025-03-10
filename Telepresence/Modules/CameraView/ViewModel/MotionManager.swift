//
//  MotionManager.swift
//  Telepresence
//
//  Created by Muhammad Junaid Babar on 2/24/25.
//


import CoreMotion
import UIKit

final class MotionManager {

    private(set) var orientation: UIDeviceOrientation = .unknown

    private let motionManager = CMMotionManager()

    init() {
        motionManager.accelerometerUpdateInterval = 0.2
        motionManager.gyroUpdateInterval = 0.2

        guard let queue = OperationQueue.current else { return }
        motionManager.startAccelerometerUpdates(to: queue) { [weak self] data, _ in
            guard let data = data else { return }
            self?.resolveOrientation(from: data)
        }
    }

    deinit {
        motionManager.stopAccelerometerUpdates()
    }

    private func resolveOrientation(from data: CMAccelerometerData) {
        let acceleration = data.acceleration
        var orientation: UIDeviceOrientation = self.orientation

        if acceleration.x >= 0.75 {
            orientation = .landscapeRight
        } else if acceleration.x <= -0.75 {
            orientation = .landscapeLeft
        } else if acceleration.y <= -0.75 {
            orientation = .portrait
        } else if acceleration.y >= 0.75 {
            orientation = .portraitUpsideDown
        }

        if orientation == self.orientation { return }
        self.orientation = orientation
    }

}
