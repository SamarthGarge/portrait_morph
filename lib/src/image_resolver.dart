import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

/// Resolves any [ImageProvider] (asset, network, memory, file...) down to a
/// raw [ui.Image] so it can be bound to a fragment shader sampler.
///
/// Uses Flutter's normal image cache/resolution pipeline — the same one
/// [Image] widgets use — so this behaves identically to standard `Image`
/// widgets across mobile, web, and desktop, including caching and retry
/// semantics for [NetworkImage].

Future<ui.Image> resolveUiImage(ImageProvider provider, BuildContext context) {
  final Completer<ui.Image> completer = Completer<ui.Image>();
  final ImageConfiguration config = createLocalImageConfiguration(context);
  final ImageStream stream = provider.resolve(config);
  late ImageStreamListener listener;
  listener = ImageStreamListener(
    (ImageInfo info, bool synchronousCall) {
      if (!completer.isCompleted) {
        completer.complete(info.image);
      }
      stream.removeListener(listener);
    },
    onError: (Object error, StackTrace? stackTrace) {
      if (!completer.isCompleted) {
        completer.completeError(error, stackTrace);
      }
      stream.removeListener(listener);
    },
  );
  stream.addListener(listener);
  return completer.future;
}
