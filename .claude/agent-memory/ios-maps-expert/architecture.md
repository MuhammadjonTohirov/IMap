---
name: imap-architecture
description: IMap SDK structure — dual MapLibre/Google providers behind MapProviderProtocol, marker/polyline/camera hot-path conventions
metadata:
  type: project
---

# IMap SDK architecture

Swift package providing a unified map abstraction over **MapLibre Native** and **Google Maps SDK** for iOS. Consumed by the `umaptest` host app.

**Why:** single `MapProviderProtocol` lets the host swap map engines without touching call sites.
**How to apply:** changes to one provider usually need a mirrored change in the other; the protocol is the contract.

## Provider layout
- `Sources/MapPack/MapProviders/Libre/` — `MapLibreProvider` (owns `MapLibreWrapperModel: MLNMapViewDelegate`). SwiftUI via `MLNMapViewWrapper: UIViewRepresentable`.
- `Sources/MapPack/MapProviders/Google/` — `GoogleMapsProvider` (owns `GoogleMapsViewWrapperModel: GMSMapViewDelegate`). SwiftUI via `GoogleMapsViewWrapper: UIViewControllerRepresentable`.
- `Sources/MapPack/Map/UniversalMarker.swift` — `UniversalMarker` is a single class subclassing **GMSMarker** AND conforming to **MLNAnnotation** simultaneously (used by both engines).

## Marker model conventions
- `UniversalMarker.coordinate` is `dynamic` (KVO) for MapLibre annotation tracking; `position` is the GMSMarker coord. `set(coordinate:)` writes both.
- `worldHeading` = true compass heading; `compensatesForMapBearing` toggles subtracting map bearing; `rotation` is the displayed value.
- MapLibre rotates the **annotation view's CGAffineTransform**; Google sets `GMSMarker.rotation`. `lastAppliedViewRotation` caches the last applied angle to skip redundant CALayer writes (MapLibre side only).

## Hot-path notes (audited 2026)
- Google `refreshVisibleMarkers()` does viewport-based add/remove of markers (good) but is called on every camera idle/focus and re-scans `allMarkers`.
- Google `updateMarker` → `refreshVisibleMarkers()` on every per-frame marker update — full viewport rescan per location tick.
- MapLibre user-location custom view: `viewFor:` calls `setup(image:scale:)` which rebuilds icon frame each dequeue.
- Both polyline animators use 60fps `Timer` (not `CADisplayLink`) and rebuild the full `MLNPolyline`/`GMSMutablePath` each tick.
