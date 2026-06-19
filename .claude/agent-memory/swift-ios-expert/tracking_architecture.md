---
name: tracking-architecture
description: How IMap's two location-tracking systems relate, and where the per-frame navigation hot path actually is
metadata:
  type: project
---

# IMap tracking architecture (verified 2026-06-15)

There are TWO independent location-tracking systems. Don't conflate them.

1. `MapPack/Tracker/LocationTrackingManager` — owns its own `CLLocationManager`, drives
   simple camera follow (`.currentLocation` / `.marker` modes). Its delegate calls
   `handleLocationUpdateThrottled` (defined in `MapProviders/Libre/MapLibreProvider+SmoothTrack.swift`,
   NOT in the manager file). Throttle state is `static` on the type — a latent multi-instance bug.

2. `NavigationTrackingCore` (standalone target, no map SDK deps) — the real turn-by-turn engine.
   Driven by `umaptest/ContentViewModel`, which uses its OWN `LocationProviding` (not the manager's
   CLLocationManager) and only uses the manager for `trackMarker` camera follow. So during navigation,
   `LocationTrackingManager.handleLocationUpdate*` is effectively dead code.

**Why this matters / how to apply:** The navigation per-frame hot path is NOT "once per GPS fix."
`ContentViewModel.animateRouteProgress` runs a 30fps `CADisplayLink` (`NavigationRouteProgressAnimationService`)
between each GPS fix; its `onUpdate` calls `renderRouteProgress`, which calls geometry
`coordinate(at:)` + `heading(at:)` (itself 2× `coordinate(at:)`) + `remainingRoute(from:)` — all O(n)
linear scans of the full polyline from index 0 — and then rebuilds a fresh `MLNPolyline`/`MapPolyline`
from N coords. So geometry-scan and polyline-rebuild costs are paid ~30×/sec, not ~1×/sec. Rate any
optimization there as higher impact than a per-fix view would suggest.
