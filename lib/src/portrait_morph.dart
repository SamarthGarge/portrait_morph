import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'image_resolver.dart';
import 'portrait_morph_painter.dart';
import 'shader_loader.dart';

/// A grayscale-friendly portrait container that morphs between two images
/// using a custom fragment shader. The transition origin follows the
/// pointer's entry point, ripple distortion runs along the wipe edge, and
/// progress eases in and out with spring-like interpolation.
///
/// * On desktop and web with a mouse, the effect is driven by hover.
/// * On touch devices (mobile/tablet), press and drag to drive the effect,
///   since there is no hover concept — release to reverse the morph.
///
/// Give this widget a bounded size (e.g. wrap it in an [AspectRatio] or a
/// fixed-size [SizedBox]) — same aspect ratio for both images works best.
class PortraitMorph extends StatefulWidget {
  const PortraitMorph({
    super.key,
    required this.imageA,
    required this.imageB,
    required this.alt,
    this.fallbackFit = BoxFit.cover,
  });

  /// The image shown at rest / before interaction.
  final ImageProvider imageA;

  /// The image morphed into on hover/press.
  final ImageProvider imageB;

  /// Accessibility label for the morph widget.
  final String alt;

  /// How the static fallback image is fit while the shader/textures are
  /// still loading, or if shader compilation fails on an unsupported
  /// backend.
  final BoxFit fallbackFit;

  @override
  State<PortraitMorph> createState() => _PortraitMorphState();
}

class _PortraitMorphState extends State<PortraitMorph>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  ui.FragmentShader? _shader;
  ui.Image? _imageA;
  ui.Image? _imageB;
  Ticker? _ticker;
  bool _failed = false;
  bool _loadRequested = false;

  double _progress = 0;
  double _time = 0;
  Duration _lastElapsed = Duration.zero;
  bool _hovering = false;
  Offset _origin = const Offset(0.5, 0.5);
  Offset _direction = const Offset(1, 0);
  Offset? _lastPointerUv;
  bool _appVisible = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Deferred to didChangeDependencies since resolving ImageProviders
    // needs an InheritedWidget-aware BuildContext.
    if (!_loadRequested) {
      _loadRequested = true;
      _load();
    }
  }

  @override
  void didUpdateWidget(covariant PortraitMorph oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageA != widget.imageA ||
        oldWidget.imageB != widget.imageB) {
      _imageA = null;
      _imageB = null;
      _failed = false;
      _load();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appVisible = state == AppLifecycleState.resumed;
    if (_appVisible) {
      _lastElapsed = Duration.zero;
    }
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        PortraitMorphShaderLoader.load(),
        resolveUiImage(widget.imageA, context),
        resolveUiImage(widget.imageB, context),
      ]);
      if (!mounted) return;
      final program = results[0] as ui.FragmentProgram;
      setState(() {
        _shader = program.fragmentShader();
        _imageA = results[1] as ui.Image;
        _imageB = results[2] as ui.Image;
      });
      _lastElapsed = Duration.zero;
      _ticker ??= createTicker(_tick);
      if (!_ticker!.isActive) {
        _ticker!.start();
      }
    } catch (_) {
      // Unsupported backend (e.g. legacy web HTML renderer without
      // fragment-shader support), a bad image URL, or a decode failure —
      // fall back to the static image instead of crashing the tree.
      if (mounted) setState(() => _failed = true);
    }
  }

  void _tick(Duration elapsed) {
    if (!_appVisible) {
      _lastElapsed = elapsed;
      return;
    }
    final double dt = _lastElapsed == Duration.zero
        ? 0.0
        : ((elapsed - _lastElapsed).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _lastElapsed = elapsed;
    _time += dt;

    final double target = _hovering ? 1.0 : 0.0;
    final double stiffness = _hovering ? 2.4 : 2.0;
    final double k = 1 - math.exp(-stiffness * dt);
    _progress += (target - _progress) * k;

    // Settle exactly at rest so the shader stops doing ripple work once
    // fully idle, and skip pointless rebuilds when nothing is moving.
    if (_progress.abs() < 0.0005 && target == 0.0) {
      _progress = 0.0;
    }
    setState(() {});
  }

  Offset _edgeDirection(double x, double y) {
    final double dxLeft = x;
    final double dxRight = 1 - x;
    final double dyBottom = y;
    final double dyTop = 1 - y;
    final double minDist = math.min(
      math.min(dxLeft, dxRight),
      math.min(dyBottom, dyTop),
    );
    if (minDist == dxLeft) return const Offset(1, 0);
    if (minDist == dxRight) return const Offset(-1, 0);
    if (minDist == dyBottom) return const Offset(0, 1);
    return const Offset(0, -1);
  }

  Offset _toUv(Offset local, Size size) {
    final double x = (local.dx / size.width).clamp(0.0, 1.0);
    final double y = (local.dy / size.height).clamp(0.0, 1.0);
    return Offset(x, y);
  }

  void _enterAt(Offset local, Size size) {
    final Offset uv = _toUv(local, size);
    _origin = uv;
    _direction = _edgeDirection(uv.dx, uv.dy);
    _lastPointerUv = uv;
    _hovering = true;
  }

  void _moveAt(Offset local, Size size) {
    final Offset uv = _toUv(local, size);
    final Offset? last = _lastPointerUv;
    if (last != null && _progress < 0.15) {
      final Offset v = uv - last;
      final double mag = v.distance;
      if (mag > 0.01) {
        _direction = v / mag;
      }
    }
    _lastPointerUv = uv;
  }

  void _exitAt(Offset local, Size size) {
    final Offset uv = _toUv(local, size);
    _origin = uv;
    final Offset edge = _edgeDirection(uv.dx, uv.dy);
    _direction = Offset(-edge.dx, -edge.dy);
    _hovering = false;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.dispose();
    _imageA?.dispose();
    _imageB?.dispose();
    super.dispose();
  }

  Widget _fallback() {
    return Image(
      image: widget.imageA,
      fit: widget.fallbackFit,
      excludeFromSemantics: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool ready =
        !_failed && _shader != null && _imageA != null && _imageB != null;

    return Semantics(
      image: true,
      label: widget.alt,
      child: ClipRect(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final Size size = constraints.biggest;

            if (!ready || size.isEmpty) {
              return _fallback();
            }

            final painter = CustomPaint(
              size: size,
              painter: PortraitMorphPainter(
                shader: _shader!,
                imageA: _imageA!,
                imageB: _imageB!,
                progress: _progress,
                time: _time,
                origin: _origin,
                direction: _direction,
              ),
            );

            return MouseRegion(
              onEnter: (e) => setState(() => _enterAt(e.localPosition, size)),
              onHover: (e) => setState(() => _moveAt(e.localPosition, size)),
              onExit: (e) => setState(() => _exitAt(e.localPosition, size)),
              child: Listener(
                // Touch/stylus drive the effect via press + drag, since
                // there's no hover concept on touch devices. Mouse pointer
                // events are handled by MouseRegion above to avoid double
                // triggering.
                onPointerDown: (e) {
                  if (e.kind == PointerDeviceKind.mouse) return;
                  setState(() => _enterAt(e.localPosition, size));
                },
                onPointerMove: (e) {
                  if (e.kind == PointerDeviceKind.mouse) return;
                  setState(() => _moveAt(e.localPosition, size));
                },
                onPointerUp: (e) {
                  if (e.kind == PointerDeviceKind.mouse) return;
                  setState(() => _exitAt(e.localPosition, size));
                },
                onPointerCancel: (e) {
                  if (e.kind == PointerDeviceKind.mouse) return;
                  setState(() => _exitAt(e.localPosition, size));
                },
                child: painter,
              ),
            );
          },
        ),
      ),
    );
  }
}
