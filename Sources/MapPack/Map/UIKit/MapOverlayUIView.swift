//
//  MapOverlayUIView.swift
//  IMap
//
//  Native UIKit overlay (center pin + address capsule) for the UIKit map path.
//  It is purely decorative (`isUserInteractionEnabled = false`) and renders the
//  same shared state the SwiftUI overlay uses: `UniversalMapViewModel.uiState`
//  and `pinModel`.
//

import UIKit
import Combine

@MainActor
final class MapOverlayUIView: UIView {

    private enum Layout {
        /// Extra lift of the address capsule above the pin (matches UniversalMapView).
        static let addressExtraOffset: CGFloat = 200
        static let addressHInset: CGFloat = 8
        static let addressVInset: CGFloat = 4
    }

    private unowned let viewModel: UniversalMapViewModel

    private let pinView = MapPinUIView()
    private let addressContainer = UIView()
    private let addressLabel = UILabel()

    private var cancellable: AnyCancellable?

    init(viewModel: UniversalMapViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        setup()
        bind()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        isUserInteractionEnabled = false
        backgroundColor = .clear

        addressContainer.backgroundColor = .black
        addressContainer.layer.masksToBounds = true

        addressLabel.font = .systemFont(ofSize: 14, weight: .medium)
        addressLabel.textColor = .white
        addressLabel.textAlignment = .center

        addressContainer.addSubview(addressLabel)
        addSubview(addressContainer)
        addSubview(pinView)

        pinView.bind(to: viewModel.pinModel)
    }

    private func bind() {
        cancellable = viewModel.$uiState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.refresh() }
        refresh()
    }

    /// Applies the latest UI state (address text + element visibility) and re-lays out.
    private func refresh() {
        let state = viewModel.uiState
        pinView.isHidden = !state.hasAddressPicker

        let name = state.addressInfo?.name
        addressLabel.text = name
        addressContainer.isHidden = !state.hasAddressView || (name?.isEmpty ?? true)

        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let bottomOffset = viewModel.pinViewBottomOffset

        // Pin: anchor point sits above the visual center by half the bottom offset,
        // matching `.padding(.bottom, pinViewBottomOffset)` in UniversalMapView.
        let pinSize = MapPinUIView.preferredSize
        let pinAnchorY = center.y - bottomOffset / 2
        pinView.frame = CGRect(
            x: center.x - pinSize.width / 2,
            y: pinAnchorY - MapPinUIView.anchorOffsetFromTop,
            width: pinSize.width,
            height: pinSize.height
        )

        // Address capsule: lifted further above the pin.
        if !addressContainer.isHidden {
            let maxWidth = bounds.width - 2 * Layout.addressHInset
            let textSize = addressLabel.sizeThatFits(CGSize(width: maxWidth, height: .greatestFiniteMagnitude))
            let capsuleSize = CGSize(
                width: min(textSize.width, maxWidth) + 2 * Layout.addressHInset,
                height: textSize.height + 2 * Layout.addressVInset
            )
            let capsuleCenterY = center.y - (bottomOffset + Layout.addressExtraOffset) / 2
            addressContainer.frame = CGRect(
                x: center.x - capsuleSize.width / 2,
                y: capsuleCenterY - capsuleSize.height / 2,
                width: capsuleSize.width,
                height: capsuleSize.height
            )
            addressContainer.layer.cornerRadius = capsuleSize.height / 2
            addressLabel.frame = addressContainer.bounds.insetBy(dx: Layout.addressHInset, dy: Layout.addressVInset)
        }
    }
}
