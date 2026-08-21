# portrait_morph

[![pub package](https://img.shields.io/pub/v/portrait_morph.svg)](https://pub.dev/packages/portrait_morph)
[![License: BSD-3-Clause](https://img.shields.io/badge/License-BSD_3--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)
[![Live Demo](https://img.shields.io/badge/demo-live_preview-success.svg)](https://samarthgarge.github.io/portrait_morph/)

A pointer-driven image morph effect for Flutter, powered by a custom
`dart:ui` fragment shader. Morphs between two images with an fbm-noise
wipe, edge ripple, and spring-eased transitions.

🎮 **[Try the Live Web Demo](https://samarthgarge.github.io/portrait_morph/)**

## Features

- **GPU-powered morph** — Custom GLSL wipe with fbm noise and edge ripple,
  running as a real GPU fragment shader (not a `ShaderMask`/blend approximation)
- **Pointer-aware** — Transition origin and direction follow pointer entry
- **Spring-eased** — Smooth spring-interpolated progress (no linear snapping)
- **Graceful fallback** — Static fallback image while textures/shader are loading
- **Cross-input** — Hover on desktop/web, press + drag on mobile/touch
- **Cross-platform** — Android, iOS, Web, macOS, Windows, and Linux

## Platform support

| Platform | Support | Notes |
|---|---|---|
| Android / iOS | ✅ | Uses Impeller (or Skia) fragment shaders — ships with modern Flutter by default |
| Web | ✅ | Requires the **CanvasKit or Skwasm** renderer (Flutter's default). The legacy HTML renderer does **not** support fragment shaders |
| macOS / Windows / Linux | ✅ | Same `dart:ui` fragment shader path as mobile |

If the shader fails to compile or an image fails to load on any platform
(e.g. an unsupported backend, or a bad `NetworkImage` URL), the widget
gracefully falls back to a static rendering of `imageA` instead of throwing.

## Getting started

### Installation

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  portrait_morph: ^1.0.0
```

Then run:

```bash
flutter pub get
```

### Prerequisites

- Flutter SDK `>=3.10.1`
- No additional native dependencies required

## Usage

### Basic example

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

### Using network images

```dart
PortraitMorph(
  imageA: NetworkImage('https://example.com/photo-a.jpg'),
  imageB: NetworkImage('https://example.com/photo-b.jpg'),
  alt: 'Photo morph',
)
```

### Parameters

| Parameter | Type | Required | Description |
|---|---|---|---|
| `imageA` | `ImageProvider` | ✅ | The image shown at rest / before interaction |
| `imageB` | `ImageProvider` | ✅ | The image morphed into on hover/press |
| `alt` | `String` | ✅ | Accessibility label for the morph widget |
| `fallbackFit` | `BoxFit` | ❌ | How the static fallback image is fit while loading (defaults to `BoxFit.cover`) |

### Tips

- `imageA`/`imageB` accept any `ImageProvider` — `AssetImage`, `NetworkImage`,
  `MemoryImage`, `FileImage` (not on web), etc.
- **Same aspect ratio** for both images works best.
- Give the widget a **bounded size** (`AspectRatio`, `SizedBox`, etc.) — it
  fills its parent.
- Network images served from another origin need **CORS headers** on web.

Check out the **[Live Demo](https://samarthgarge.github.io/portrait_morph/)** or browse [`example/`](example/) for the complete runnable demo source code.

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

## Known limitations

- No automatic pause-when-off-screen — the ticker only pauses on app
  background/foreground (`AppLifecycleState`). Wrap in `VisibilityDetector`
  if you need scroll-based pausing in a long list.
- `dispose()` frees the decoded `ui.Image`s; if you rebuild this widget
  very frequently with new `ImageProvider`s (e.g. inside a fast-scrolling
  list), prefer stable/cached providers to avoid repeated decodes.

## Contributing

Contributions are welcome! Please open an issue or submit a pull request on
[GitHub](https://github.com/SamarthGarge/portrait_morph).

## License

This project is licensed under the BSD 3-Clause License — see the
[LICENSE](LICENSE) file for details.
