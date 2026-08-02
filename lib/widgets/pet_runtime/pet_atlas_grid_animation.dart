import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Plays every unique sprite packed in an atlas page.
///
/// Rectangles and canvas offsets come from the V4 manifest because atlas
/// sprites are trimmed and cannot be divided into equal grid cells safely.
class PetAtlasGridAnimation extends StatefulWidget {
  const PetAtlasGridAnimation({
    super.key,
    required this.atlasAsset,
    required this.manifestAsset,
    required this.manifestAtlasAsset,
    this.fps = 5,
  });

  final String atlasAsset;
  final String manifestAsset;
  final String manifestAtlasAsset;
  final int fps;

  @override
  State<PetAtlasGridAnimation> createState() => _PetAtlasGridAnimationState();
}

class _PetAtlasGridAnimationState extends State<PetAtlasGridAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  ui.Image? _image;
  List<_AtlasFrame> _frames = const [];
  Object? _error;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        rootBundle.load(widget.atlasAsset),
        rootBundle.loadString(widget.manifestAsset),
      ]);
      final imageData = results[0] as ByteData;
      final manifestJson = results[1] as String;
      final frames = _readFrames(manifestJson);
      if (frames.isEmpty) {
        throw StateError('Atlas page has no frames in the V4 manifest.');
      }

      final bytes = imageData.buffer.asUint8List(
        imageData.offsetInBytes,
        imageData.lengthInBytes,
      );
      final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      final descriptor = await ui.ImageDescriptor.encoded(buffer);
      final codec = await descriptor.instantiateCodec();
      final decodedFrame = await codec.getNextFrame();
      codec.dispose();
      descriptor.dispose();
      buffer.dispose();

      if (!mounted) {
        decodedFrame.image.dispose();
        return;
      }

      _controller.duration = Duration(
        milliseconds: (frames.length * 1000 / widget.fps.clamp(1, 60)).round(),
      );
      setState(() {
        _image = decodedFrame.image;
        _frames = frames;
      });
      _controller.repeat();
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  List<_AtlasFrame> _readFrames(String manifestJson) {
    final manifest = jsonDecode(manifestJson) as Map<String, dynamic>;
    final animations =
        manifest['animations'] as Map<String, dynamic>? ?? const {};
    final uniqueFrames = <String, _AtlasFrame>{};

    for (final animation in animations.values.whereType<Map>()) {
      final pages = (animation['pages'] as List?)?.cast<dynamic>() ?? const [];
      final pageIndex = pages.indexWhere(
        (page) => page.toString() == widget.manifestAtlasAsset,
      );
      if (pageIndex < 0) continue;

      for (final rawFrame in (animation['frames'] as List? ?? const [])) {
        if (rawFrame is! Map || rawFrame['page'] != pageIndex) continue;
        final frame = _AtlasFrame.fromJson(rawFrame);
        uniqueFrames.putIfAbsent(frame.key, () => frame);
      }
    }

    final frames = uniqueFrames.values.toList(growable: false);
    frames.sort((a, b) {
      final rowComparison = a.source.top.compareTo(b.source.top);
      if (rowComparison != 0) return rowComparison;
      // Requested playback order: right to left, then move down one row.
      return b.source.left.compareTo(a.source.left);
    });
    return frames;
  }

  @override
  void dispose() {
    _controller.dispose();
    _image?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final image = _image;
    if (_error != null) {
      return const Center(child: Icon(Icons.image_not_supported_outlined));
    }
    if (image == null || _frames.isEmpty) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final index = (_controller.value * _frames.length).floor().clamp(
          0,
          _frames.length - 1,
        );
        return CustomPaint(
          painter: _AtlasFramePainter(image, _frames[index]),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _AtlasFrame {
  const _AtlasFrame({
    required this.source,
    required this.originalSize,
    required this.offset,
  });

  factory _AtlasFrame.fromJson(Map<dynamic, dynamic> json) => _AtlasFrame(
    source: Rect.fromLTWH(
      (json['x'] as num).toDouble(),
      (json['y'] as num).toDouble(),
      (json['width'] as num).toDouble(),
      (json['height'] as num).toDouble(),
    ),
    originalSize: Size(
      (json['originalWidth'] as num).toDouble(),
      (json['originalHeight'] as num).toDouble(),
    ),
    offset: Offset(
      (json['offsetX'] as num).toDouble(),
      (json['offsetY'] as num).toDouble(),
    ),
  );

  final Rect source;
  final Size originalSize;
  final Offset offset;

  String get key =>
      '${source.left}:${source.top}:${source.width}:${source.height}';
}

class _AtlasFramePainter extends CustomPainter {
  const _AtlasFramePainter(this.image, this.frame);

  final ui.Image image;
  final _AtlasFrame frame;

  @override
  void paint(Canvas canvas, Size size) {
    final widthScale = size.width / frame.originalSize.width;
    final heightScale = size.height / frame.originalSize.height;
    final scale = widthScale < heightScale ? widthScale : heightScale;
    final canvasOrigin = Offset(
      (size.width - frame.originalSize.width * scale) / 2,
      (size.height - frame.originalSize.height * scale) / 2,
    );
    final destination = Rect.fromLTWH(
      canvasOrigin.dx + frame.offset.dx * scale,
      canvasOrigin.dy + frame.offset.dy * scale,
      frame.source.width * scale,
      frame.source.height * scale,
    );

    canvas.drawImageRect(
      image,
      frame.source,
      destination,
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  @override
  bool shouldRepaint(covariant _AtlasFramePainter oldDelegate) =>
      oldDelegate.image != image || oldDelegate.frame != frame;
}
