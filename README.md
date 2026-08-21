# portrait_morph

A pointer-driven image morph effect for Flutter, powered by a custom
`dart:ui` fragment shader. Morphs between two images with an fbm-noise
wipe, edge ripple, and spring-eased transitions.

- Custom GLSL wipe with fbm noise and edge ripple, running as a real GPU
  fragment shader (not a `ShaderMask`/blend approximation)
- Transition origin and direction follow pointer entry
- Spring-eased progress (no linear snapping)
- Static fallback image while textures/shader are loading
- **Mobile:** press + drag drives the effect (no hover on touch)
- **Web / desktop:** hover drives the effect

## Platform support

| Platform | Support | Notes |
|---|---|---|
| Android / iOS | ✅ | Uses Impeller (or Skia) fragment shaders — ships with modern Flutter by default |
| Web | ✅ | Requires the **CanvasKit or Skwasm** renderer (Flutter's default web renderer). The legacy HTML renderer does **not** support fragment shaders — if you've forced `--web-renderer html`, remove that flag |
| macOS / Windows / Linux | ✅ | Same `dart:ui` fragment shader path as mobile |

If the shader fails to compile or an image fails to load on any platform
(e.g. an unsupported backend, or a bad `NetworkImage` URL), the widget falls
back to a static rendering of `imageA` instead of throwing.

## Install

```yaml
dependencies:
  portrait_morph: ^0.1.0
```

## Usage

```dart
import 'package:portrait_morph/portrait_morph.dart';

AspectRatio(
  aspectRatio: 1,
  child: ClipRRect(
    borderRadius: BorderRadius.circular(32),
    child: PortraitMorph(
      imageA: AssetImage('assets/day_landscape.png'),
      imageB: AssetImage('assets/night_landscape.png'),
      alt: 'Day to Night Landscape',
    ),
  ),
)
```

`imageA`/`imageB` accept any `ImageProvider` — `AssetImage`, `NetworkImage`,
`MemoryImage`, `FileImage` (not on web), etc. Same aspect ratio for both
images works best. Give the widget a bounded size (`AspectRatio`,
`SizedBox`, etc.) — it fills its parent.

Network images served from another origin need CORS headers on web.

See `example/` for a runnable demo.

## How it works

`FragmentProgram.fromAsset` compiles `shaders/portrait_morph.frag` once and
caches it. Each `PortraitMorph` instance resolves its two `ImageProvider`s
to raw `ui.Image`s via the standard Flutter image-resolution pipeline (so
caching/retry behaves like any `Image` widget), then a `Ticker` updates a
spring-eased `progress` value every frame and repaints a `CustomPainter`
that binds both textures and the current uniforms
(`resolution`, `imageSize`, `progress`, `time`, `origin`, `direction`) to
the shader.

Pointer handling splits by device kind: `MouseRegion` drives hover-based
entry/exit/move for mouse input (desktop, web), while a `Listener` handles
press/drag/release for touch and stylus input, so the same effect works
naturally on both interaction models without double-triggering.

## Limitations

- No automatic pause-when-off-screen — the ticker only pauses on app
  background/foreground (`AppLifecycleState`). Wrap in `VisibilityDetector`
  if you need scroll-based pausing in a long list.
- `dispose()` frees the decoded `ui.Image`s; if you rebuild this widget
  very frequently with new `ImageProvider`s (e.g. inside a fast-scrolling
  list), prefer stable/cached providers to avoid repeated decodes.
