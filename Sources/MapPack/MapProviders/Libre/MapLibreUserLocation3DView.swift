import CoreLocation
import RealityKit
import UIKit

@MainActor
final class MapLibreUserLocation3DView: UIView {
    private enum Layout {
        static let cameraDistance: Float = 3.2
        static let normalizedModelExtent: Float = 1.5
        static let shadowSize = CGSize(width: 24, height: 24)
        static let snapshotDelayNanoseconds: UInt64 = 100_000_000
    }

    private let configuration: UserLocation3DModel
    private let realityView: ARView
    private let snapshotView = UIImageView()
    private let shadowView = UIView()
    private let sceneAnchor = AnchorEntity(world: .zero)
    private let headingRoot = Entity()
    private let camera = PerspectiveCamera()

    private var renderState = MapLibreUserLocation3DRenderState()
    private var snapshotRevision: UInt?
    private var snapshotTask: Task<Void, Never>?
    private var entity: Entity?
    private var isViewHierarchyConfigured = false
    private var isSceneConfigured = false

    init(model prototype: Entity, configuration: UserLocation3DModel) {
        self.configuration = configuration
        self.entity = prototype
        self.realityView = ARView(
            frame: CGRect(origin: .zero, size: configuration.viewportSize),
            cameraMode: .nonAR,
            automaticallyConfigureSession: false
        )
        super.init(frame: CGRect(origin: .zero, size: configuration.viewportSize))
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        configureViewHierarchy()

        if !isSceneConfigured, let prototype = entity {
            configureScene(with: prototype)
            entity = nil
            isSceneConfigured = true
            renderState.invalidate()
        }

        updateSceneTransforms()
        scheduleSnapshot()
        setNeedsLayout()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()

        guard window != nil else {
            snapshotTask?.cancel()
            snapshotTask = nil
            return
        }

        if snapshotRevision != renderState.revision {
            scheduleSnapshot()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        realityView.frame = bounds
        snapshotView.frame = bounds
        layoutShadow()
    }

    func setDisplayHeading(_ degrees: CLLocationDirection) {
        guard renderState.setDisplayHeading(degrees) else { return }
        updateSceneTransforms()
        scheduleSnapshot()
    }

    func setMapPitch(_ degrees: CGFloat) {
        guard renderState.setMapPitch(degrees) else { return }
        updateSceneTransforms()
        scheduleSnapshot()
        setNeedsLayout()
    }

    private func configureViewHierarchy() {
        guard !isViewHierarchyConfigured else { return }
        isViewHierarchyConfigured = true

        clipsToBounds = false
        isUserInteractionEnabled = false
        isAccessibilityElement = true
        accessibilityLabel = "Current location and direction"

        shadowView.backgroundColor = UIColor.black.withAlphaComponent(0.16)
        shadowView.layer.cornerRadius = Layout.shadowSize.height / 2
        shadowView.layer.shadowColor = UIColor.black.cgColor
        shadowView.layer.shadowOpacity = 0.35
        shadowView.layer.shadowRadius = 5
        shadowView.layer.shadowOffset = CGSize(width: 0, height: 2)
        shadowView.isUserInteractionEnabled = false
        addSubview(shadowView)

        realityView.backgroundColor = .clear
        realityView.isOpaque = false
        realityView.isUserInteractionEnabled = false
        realityView.environment.background = .color(.clear)
        realityView.contentScaleFactor = 2
        realityView.renderOptions.insert(.disableDepthOfField)
        realityView.renderOptions.insert(.disableGroundingShadows)
        realityView.renderOptions.insert(.disableHDR)
        realityView.renderOptions.insert(.disableMotionBlur)
        realityView.renderOptions.insert(.disableCameraGrain)
        addSubview(realityView)

        snapshotView.backgroundColor = .clear
        snapshotView.contentMode = .scaleAspectFit
        snapshotView.isHidden = true
        snapshotView.isUserInteractionEnabled = false
        addSubview(snapshotView)
    }

    private func configureScene(with prototype: Entity) {
        let model = prototype.clone(recursive: true)
        headingRoot.addChild(model)

        let bounds = headingRoot.visualBounds(
            recursive: true,
            relativeTo: headingRoot
        )
        let center = bounds.center
        model.position += SIMD3<Float>(-center.x, -bounds.min.y, -center.z)

        let horizontalExtent = max(bounds.extents.x, bounds.extents.z)
        if horizontalExtent > .ulpOfOne {
            let requestedScale = max(configuration.relativeScale, 0.01)
            let scale = Layout.normalizedModelExtent * requestedScale / horizontalExtent
            headingRoot.scale = SIMD3<Float>(repeating: scale)
            headingRoot.position.y = 0.3
        }

        camera.camera = PerspectiveCameraComponent(
            near: 0.01,
            far: 20,
            fieldOfViewInDegrees: 38
        )

        let light = DirectionalLight()
        light.light = DirectionalLightComponent(
            color: .white,
            intensity: 2_500,
            isRealWorldProxy: false
        )
        light.look(
            at: MapLibreUserLocation3DProjection.sceneLocationAnchor,
            from: SIMD3<Float>(-2, 4, -3),
            relativeTo: sceneAnchor
        )

        sceneAnchor.addChild(headingRoot)
        sceneAnchor.addChild(camera)
        sceneAnchor.addChild(light)
        realityView.scene.addAnchor(sceneAnchor)
    }

    private func updateSceneTransforms() {
        let heading = renderState.displayHeading + configuration.headingOffset
        headingRoot.orientation = simd_quatf(
            angle: -Float(heading * .pi / 180),
            axis: SIMD3<Float>(0, 1, 0)
        )

        let cameraPosition = MapLibreUserLocation3DProjection.cameraPosition(
            pitch: renderState.mapPitch,
            distance: Layout.cameraDistance
        )
        camera.look(
            // World zero is the model's horizontal ground-center and the map
            // annotation's geographic coordinate. Keeping it at the virtual
            // camera target prevents the arrow tip from drifting onto the
            // current-location point as the map tilts.
            at: MapLibreUserLocation3DProjection.sceneLocationAnchor,
            from: cameraPosition,
            upVector: SIMD3<Float>(0, 0, -1),
            relativeTo: sceneAnchor
        )
    }

    private func scheduleSnapshot() {
        guard isSceneConfigured, window != nil else { return }

        snapshotTask?.cancel()
        attachRealityViewIfNeeded()
        snapshotView.isHidden = true

        let revision = renderState.revision
        snapshotTask = Task { @MainActor [weak self] in
            do {
                try await Task.sleep(nanoseconds: Layout.snapshotDelayNanoseconds)
            } catch {
                return
            }

            guard let self, self.renderState.isCurrent(revision) else { return }
            self.captureSnapshot(for: revision)
        }
    }

    private func captureSnapshot(for revision: UInt) {
        realityView.snapshot(saveToHDR: false) { [weak self] image in
            guard let self,
                  let image,
                  self.window != nil,
                  self.renderState.isCurrent(revision) else {
                return
            }

            self.snapshotView.image = image
            self.snapshotView.isHidden = false
            self.snapshotRevision = revision
            self.snapshotTask = nil

            // RealityKit otherwise maintains its own render loop alongside
            // MapLibre. A cached marker needs no GPU work while the map pans.
            self.realityView.removeFromSuperview()
        }
    }

    private func attachRealityViewIfNeeded() {
        guard realityView.superview == nil else { return }
        insertSubview(realityView, belowSubview: snapshotView)
        realityView.frame = bounds
    }

    private func layoutShadow() {
        shadowView.bounds = CGRect(origin: .zero, size: Layout.shadowSize)
        shadowView.layer.shadowPath = UIBezierPath(
            ovalIn: shadowView.bounds
        ).cgPath
        shadowView.center = MapLibreUserLocation3DProjection.screenLocationAnchor(
            in: bounds
        )
        shadowView.transform = CGAffineTransform(
            scaleX: 1,
            y: MapLibreUserLocation3DProjection.shadowVerticalScale(
                pitch: renderState.mapPitch
            )
        )
    }
}
