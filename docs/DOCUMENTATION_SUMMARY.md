# IMap Documentation Summary

This folder contains the maintained markdown documentation for `IMap` / `MapPack`.

## Primary Entry Points

- `README.md` - package overview, install, and documentation index.
- `docs/docsQuickStart.md` - setup and common tasks.
- `docs/docsNavigationTrackingCore.md` - detailed guide for the new tracking engine.

## API References

- `docs/docsUniversalMapViewModel.md`
- `docs/docsMapProviderProtocol.md`
- `docs/docsUniversalMapMarkerProtocol.md`
- `docs/docsUniversalMapMarker.md`
- `docs/docsUniversalMapPolyline.md`
- `docs/docsUniversalMapCamera.md`
- `docs/docsMapInteractionDelegate.md`
- `docs/docsMarkerVisibilityManagement.md`

## Tracking Documents

- `docs/docsNavigationTrackingCore.md`
  - Session-level tracking flow.
  - Marker and polyline animation based on route progress.
  - Off-route detection and reroute integration.
  - Heading source priority and strategy control.

- `docs/docsRouteTrackingManager.md`
  - Low-level route snapping with threshold checks.
  - `NavigationRouteTrackingManager` usage.

## Notes

- `NavigationTrackingCore` symbols are re-exported by `MapPack`.
- Existing code should use direct `Navigation...` type names.
- Documentation in this folder is aligned with the extracted reusable tracking architecture.
