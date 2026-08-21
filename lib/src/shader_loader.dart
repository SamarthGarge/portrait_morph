import 'dart:async';
import 'dart:ui' as ui;

/// Loads the compiled `portrait_morph.frag` program.
///
/// Package assets are always addressed with the `packages/<package_name>/`
/// prefix by consumers — including this package's own example app, which
/// depends on it as a path dependency. [ui.FragmentProgram.fromAsset]
/// caches the compiled program internally per key, but multiple
/// [PortraitMorph] instances mounting at once would otherwise each kick off
/// their own asset-bundle read+compile race; sharing one in-flight future
/// avoids that.

class PortraitMorphShaderLoader {
  PortraitMorphShaderLoader._();

  static const String assetKey =
      'packages/portrait_morph/shaders/portrait_morph.frag';

  static Future<ui.FragmentProgram>? _programFuture;

  static Future<ui.FragmentProgram> load() {
    return _programFuture ??= ui.FragmentProgram.fromAsset(assetKey);
  }
}
