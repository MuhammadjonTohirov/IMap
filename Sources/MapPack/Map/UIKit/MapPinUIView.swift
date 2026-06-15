//
//  MapPinUIView.swift
//  IMap
//
//  Native UIKit port of the SwiftUI `PinView`. Renders the center pin for every
//  `PinState` (initial / loading / pinning / waiting / steady / searching) and
//  observes the shared `PinViewModel` so the UIKit and SwiftUI overlays are driven
//  by the same state.
//

import UIKit
import Combine

@MainActor
final class MapPinUIView: UIView {

    // MARK: - Geometry (matches PinView's 50/20/8 layout)
    private enum Layout {
        static let headSize: CGFloat = 50
        static let overlaySize: CGFloat = 28
        static let stalkWidth: CGFloat = 2
        static let stalkHeight: CGFloat = 20
        static let dotSize: CGFloat = 8
        /// Distance from the top of the view to the point the pin "points at".
        static let anchorFromTop: CGFloat = headSize + stalkHeight   // 70
        static let totalHeight: CGFloat = anchorFromTop + dotSize / 2 + 2
        /// Vertical bob travel while `.pinning` (mirrors PinView's 6 → 12 shift).
        static let bobBase: CGFloat = -6
        static let bobPeak: CGFloat = -12
        /// Drop applied while `.searching` so the head sits on the anchor point.
        static let searchingDrop: CGFloat = headSize / 2 + stalkHeight  // 45
    }

    /// The point inside this view (top-relative) that aligns with the map target.
    static var anchorOffsetFromTop: CGFloat { Layout.anchorFromTop }
    static var preferredSize: CGSize { CGSize(width: Layout.headSize, height: Layout.totalHeight) }

    // MARK: - Subviews
    private let pinBody = UIView()          // head + stalk (bobs together)
    private let headView = UIView()
    private let overlayCircle = UIView()    // solid dot for initial/loading/searching/steady
    private let spinnerLayer = CAShapeLayer()
    private let waitingStack = UIStackView()
    private let timeLabel = UILabel()
    private let unitLabel = UILabel()
    private let stalkView = UIView()
    private let anchorDot = UIView()

    private weak var model: PinViewModel?
    private var cancellable: AnyCancellable?

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Binds the pin to a model and renders its state reactively.
    func bind(to model: PinViewModel) {
        self.model = model
        cancellable = model.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in self?.apply(state: state) }
        apply(state: model.state)
    }

    // MARK: - Setup
    private func setup() {
        isUserInteractionEnabled = false
        backgroundColor = .clear

        headView.backgroundColor = .iPrimary
        headView.layer.masksToBounds = true

        overlayCircle.backgroundColor = .pinOverlayCircle
        overlayCircle.layer.masksToBounds = true

        spinnerLayer.fillColor = UIColor.clear.cgColor
        spinnerLayer.strokeColor = UIColor.pinOverlayCircle.cgColor
        spinnerLayer.lineWidth = 3
        spinnerLayer.lineCap = .round
        spinnerLayer.isHidden = true

        timeLabel.font = .systemFont(ofSize: 20, weight: .bold)
        timeLabel.textColor = .pinLabel
        timeLabel.textAlignment = .center
        unitLabel.font = .systemFont(ofSize: 12, weight: .medium)
        unitLabel.textColor = .pinLabel
        unitLabel.textAlignment = .center
        waitingStack.axis = .vertical
        waitingStack.alignment = .center
        waitingStack.addArrangedSubview(timeLabel)
        waitingStack.addArrangedSubview(unitLabel)

        stalkView.backgroundColor = .iPrimary

        anchorDot.backgroundColor = .iPrimary
        anchorDot.layer.masksToBounds = true

        pinBody.addSubview(headView)
        pinBody.addSubview(overlayCircle)
        pinBody.layer.addSublayer(spinnerLayer)
        pinBody.addSubview(waitingStack)
        pinBody.addSubview(stalkView)
        addSubview(pinBody)
        addSubview(anchorDot)
    }

    // MARK: - Layout
    override func layoutSubviews() {
        super.layoutSubviews()
        let width = bounds.width
        pinBody.frame = CGRect(x: 0, y: 0, width: width, height: Layout.anchorFromTop)

        headView.frame = CGRect(x: (width - Layout.headSize) / 2, y: 0, width: Layout.headSize, height: Layout.headSize)
        headView.layer.cornerRadius = Layout.headSize / 2

        let headCenter = CGPoint(x: headView.frame.midX, y: headView.frame.midY)

        overlayCircle.bounds = CGRect(x: 0, y: 0, width: Layout.overlaySize, height: Layout.overlaySize)
        overlayCircle.center = headCenter
        overlayCircle.layer.cornerRadius = Layout.overlaySize / 2

        spinnerLayer.frame = headView.frame
        let ringRadius = Layout.overlaySize / 2
        spinnerLayer.path = UIBezierPath(
            arcCenter: CGPoint(x: headView.bounds.midX, y: headView.bounds.midY),
            radius: ringRadius,
            startAngle: -.pi / 2,
            endAngle: .pi,
            clockwise: true
        ).cgPath

        waitingStack.frame = CGRect(x: headView.frame.minX, y: headCenter.y - 24, width: Layout.headSize, height: 48)

        stalkView.frame = CGRect(
            x: (width - Layout.stalkWidth) / 2,
            y: Layout.headSize,
            width: Layout.stalkWidth,
            height: Layout.stalkHeight
        )

        anchorDot.frame = CGRect(
            x: (width - Layout.dotSize) / 2,
            y: Layout.anchorFromTop - Layout.dotSize / 2,
            width: Layout.dotSize,
            height: Layout.dotSize
        )
        anchorDot.layer.cornerRadius = Layout.dotSize / 2
    }

    // MARK: - State rendering
    private func apply(state: PinState) {
        resetAnimations()

        // Defaults
        overlayCircle.isHidden = true
        spinnerLayer.isHidden = true
        waitingStack.isHidden = true
        stalkView.isHidden = false
        anchorDot.isHidden = false
        pinBody.transform = .identity
        overlayCircle.alpha = 1

        switch state {
        case .initial, .loading:
            overlayCircle.isHidden = false

        case .searching:
            overlayCircle.isHidden = false
            stalkView.isHidden = true
            anchorDot.isHidden = true
            pinBody.transform = CGAffineTransform(translationX: 0, y: Layout.searchingDrop)

        case .pinning:
            spinnerLayer.isHidden = false
            startBob()
            startSpinner()

        case let .waiting(time, unit):
            waitingStack.isHidden = false
            timeLabel.text = time
            unitLabel.text = unit.uppercased()

        case .steady:
            overlayCircle.isHidden = false
            startSteadyPulse()
        }
    }

    // MARK: - Animations
    private func startBob() {
        pinBody.transform = CGAffineTransform(translationX: 0, y: Layout.bobBase)
        UIView.animate(
            withDuration: 0.5,
            delay: 0,
            options: [.repeat, .autoreverse, .curveEaseInOut, .allowUserInteraction],
            animations: { [weak self] in
                self?.pinBody.transform = CGAffineTransform(translationX: 0, y: Layout.bobPeak)
            }
        )
    }

    private func startSpinner() {
        let rotation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotation.fromValue = 0
        rotation.toValue = 2 * Double.pi
        rotation.duration = 1
        rotation.repeatCount = .infinity
        spinnerLayer.add(rotation, forKey: "spin")
    }

    private func startSteadyPulse() {
        UIView.animate(
            withDuration: 0.5,
            delay: 0,
            options: [.repeat, .autoreverse, .curveEaseInOut, .allowUserInteraction],
            animations: { [weak self] in
                self?.overlayCircle.alpha = 0.5
            }
        )
    }

    private func resetAnimations() {
        pinBody.layer.removeAllAnimations()
        overlayCircle.layer.removeAllAnimations()
        spinnerLayer.removeAnimation(forKey: "spin")
    }
}
