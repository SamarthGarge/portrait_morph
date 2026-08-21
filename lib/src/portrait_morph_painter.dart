import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';

/// Paints the portrait-morph fragment shader into the given [size] each
/// frame, binding the two source textures and the current animation
/// uniforms. See `shaders/portrait_morph.frag` for the uniform layout —
/// the [setFloat] indices here must match that file's declaration order.

class PortraitMorphPainter extends CustomPainter {
  PortraitMorphPainter({
    required this.shader,
    required this.imageA,
    required this.imageB,
    required this.progress,
    required this.time,
    required this.origin,
    required this.direction,
  });

  final ui.FragmentShader shader;
  final ui.Image imageA;
  final ui.Image imageB;
  final double progress;
  final double time;
  final Offset origin;
  final Offset direction;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, imageA.width.toDouble())
      ..setFloat(3, imageA.height.toDouble())
      ..setFloat(4, progress)
      ..setFloat(5, time)
      ..setFloat(6, origin.dx)
      ..setFloat(7, origin.dy)
      ..setFloat(8, direction.dx)
      ..setFloat(9, direction.dy)
      ..setImageSampler(0, imageA)
      ..setImageSampler(1, imageB);

    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(covariant PortraitMorphPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.time != time ||
        oldDelegate.origin != origin ||
        oldDelegate.direction != direction ||
        oldDelegate.imageA != imageA ||
        oldDelegate.imageB != imageB;
  }
}
