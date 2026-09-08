import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Nine explicit image regions avoid drawImageNine seams on Android GPU drivers.
/// Slice coordinates are source pixels; the original art is never tinted.
class NineSliceGameFrame extends StatefulWidget {
  const NineSliceGameFrame({
    super.key,
    required this.child,
    required this.asset,
    required this.slice,
    this.assetScale = 3,
  });
  final Widget child;
  final String asset;
  final Rect slice;
  final double assetScale;

  @override
  State<NineSliceGameFrame> createState() => _NineSliceGameFrameState();
}

class _NineSliceGameFrameState extends State<NineSliceGameFrame> {
  ImageStream? _stream;
  ImageInfo? _info;
  late final ImageStreamListener _listener = ImageStreamListener((info, _) {
    if (!mounted) {
      info.dispose();
      return;
    }
    final old = _info;
    setState(() => _info = info);
    old?.dispose();
  }, onError: (Object _, StackTrace? _) {});

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolve();
  }

  @override
  void didUpdateWidget(covariant NineSliceGameFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.asset != widget.asset) _resolve();
  }

  void _resolve() {
    final next = AssetImage(
      widget.asset,
    ).resolve(createLocalImageConfiguration(context));
    if (_stream?.key == next.key) return;
    _stream?.removeListener(_listener);
    _stream = next..addListener(_listener);
  }

  @override
  void dispose() {
    _stream?.removeListener(_listener);
    _info?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _FramePainter(_info?.image, widget.slice, widget.assetScale),
    child: widget.child,
  );
}

class _FramePainter extends CustomPainter {
  _FramePainter(this.image, this.slice, this.scale);
  final ui.Image? image;
  final Rect slice;
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    final image = this.image;
    if (image == null) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(24)),
        Paint()..color = const Color(0xFFFFF6E4),
      );
      return;
    }
    final width = image.width.toDouble();
    final height = image.height.toDouble();
    final xs = [0.0, slice.left, slice.right, width];
    final ys = [0.0, slice.top, slice.bottom, height];
    final fixedWidth = (width - slice.width) / scale;
    final fixedHeight = (height - slice.height) / scale;
    final ratio = [
      1.0,
      size.width / fixedWidth,
      size.height / fixedHeight,
    ].reduce((a, b) => a < b ? a : b);
    final dx = [
      0.0,
      slice.left / scale * ratio,
      size.width - (width - slice.right) / scale * ratio,
      size.width,
    ];
    final dy = [
      0.0,
      slice.top / scale * ratio,
      size.height - (height - slice.bottom) / scale * ratio,
      size.height,
    ];
    final paint = Paint()
      ..filterQuality = FilterQuality.low
      ..isAntiAlias = false;
    for (var row = 0; row < 3; row++) {
      for (var col = 0; col < 3; col++) {
        canvas.drawImageRect(
          image,
          Rect.fromLTRB(xs[col], ys[row], xs[col + 1], ys[row + 1]),
          Rect.fromLTRB(dx[col], dy[row], dx[col + 1], dy[row + 1]),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FramePainter old) =>
      old.image != image || old.slice != slice || old.scale != scale;
}
