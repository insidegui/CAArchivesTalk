//
//  ViewController.swift
//  CAArchivesTalk
//
//  Created by Guilherme Rambo on 02/06/19.
//  Copyright © 2019 Guilherme Rambo. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override var prefersStatusBarHidden: Bool {
        return true
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    private func loadArchive(named name: String) -> CALayer {
        guard let data = NSDataAsset(name: name)?.data else {
            fatalError("Failed to load \(name) asset")
        }

        guard let dict = NSKeyedUnarchiver.unarchiveObject(with: data) as? [String: Any] else {
            fatalError("Invalid \(name) asset")
        }

        guard let rootLayer = dict["rootLayer"] as? CALayer else {
            fatalError("Couldn't find root layer in \(name)")
        }

        return rootLayer
    }

    private lazy var rootLayer: CALayer = {
        return self.loadArchive(named: "Talk")
    }()

    private lazy var particleLayer: CAEmitterLayer = {
        return self.loadArchive(named: "ParticleDot").sublayers!.first as! CAEmitterLayer
    }()

    private lazy var containerLayer: CALayer = {
        return rootLayer.sublayers!.first!
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        containerLayer.isGeometryFlipped = true

        view.backgroundColor = .black
        view.layer.addSublayer(rootLayer)

        pauseSlideLayers()

        let tap = UITapGestureRecognizer(target: self, action: #selector(nextSlide))
        view.addGestureRecognizer(tap)

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        pan.minimumNumberOfTouches = 2
        view.addGestureRecognizer(pan)
    }

    @objc private func handlePan(_ recognizer: UIPanGestureRecognizer) {
        switch recognizer.state {
        case .began:
            self.particleLayer.birthRate = 100
            view.layer.addSublayer(particleLayer)
        case .cancelled, .ended, .failed:
            CATransaction.begin()
            CATransaction.setAnimationDuration(0.4)
            CATransaction.setCompletionBlock {
                self.particleLayer.removeFromSuperlayer()
            }
            self.particleLayer.birthRate = 0
            CATransaction.commit()
        default:
            break
        }

        particleLayer.emitterPosition = recognizer.location(in: view)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        view.resizeLayer(rootLayer)
    }

    private var currentSlide = 0

    private lazy var slideCount: Int = {
        return containerLayer.sublayers!.count
    }()

    @objc private func nextSlide() {
        currentSlide += 1

        guard currentSlide < slideCount else { return }

        play(layer: containerLayer.sublayers![currentSlide])
    }

    private func pauseSlideLayers() {
        containerLayer.sublayers?.forEach { layer in
            layer.timeOffset = 0
            layer.speed = 0
        }
    }

    private func play(layer: CALayer) {
        layer.speed = 1
        layer.beginTime = CACurrentMediaTime()
    }


}

extension UIView {

    func resizeLayer(_ targetLayer: CALayer?) {
        guard let targetLayer = targetLayer else { return }

        let layerWidth = targetLayer.bounds.width
        let layerHeight = targetLayer.bounds.height

        let aspectWidth  = bounds.width / layerWidth
        let aspectHeight = bounds.height / layerHeight

        let ratio = min(aspectWidth, aspectHeight)

        let scale = CATransform3DMakeScale(ratio,
                                           ratio,
                                           1)
        let translation = CATransform3DMakeTranslation((bounds.width - (layerWidth * ratio))/2.0,
                                                       (bounds.height - (layerHeight * ratio))/2.0,
                                                       0)

        targetLayer.transform = CATransform3DConcat(scale, translation)
    }

}
