import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../core/app_lang.dart';
import '../core/app_theme.dart';

/// صفحه برش، بزرگ‌نمایی و چرخش تصویر (Crop / Pan / Zoom / Rotate)
/// بدون وابستگی نیتیو — عملکرد کامل روی وب، اندروید و آی‌او‌اس
class ImageCropScreen extends StatefulWidget {
  const ImageCropScreen({
    super.key,
    required this.imageBytes,
    this.initialAspectRatio,
    this.title,
  });

  final Uint8List imageBytes;
  final double? initialAspectRatio;
  final String? title;

  static Future<Uint8List?> crop(
    BuildContext context, {
    required Uint8List bytes,
    double? initialAspectRatio,
    String? title,
  }) {
    return Navigator.of(context).push<Uint8List>(
      MaterialPageRoute(
        builder: (_) => ImageCropScreen(
          imageBytes: bytes,
          initialAspectRatio: initialAspectRatio,
          title: title,
        ),
      ),
    );
  }

  @override
  State<ImageCropScreen> createState() => _ImageCropScreenState();
}

class _CropAspectChoice {
  const _CropAspectChoice({
    required this.id,
    required this.labelKey,
    required this.ratio,
    required this.icon,
  });

  final String id;
  final String labelKey;
  final double? ratio;
  final IconData icon;
}

class _ImageCropScreenState extends State<ImageCropScreen> {
  final TransformationController _transformCtrl = TransformationController();

  ui.Image? _decodedImage;
  bool _loading = true;
  bool _processing = false;
  String? _errorMessage;

  int _rotationQuarterTurns = 0; // 0, 1, 2, 3 (0°, 90°, 180°, 270°)
  double? _selectedRatio; // null = free

  static const List<_CropAspectChoice> _aspectRatios = [
    _CropAspectChoice(
      id: 'free',
      labelKey: 'crop_aspect_free',
      ratio: null,
      icon: Icons.crop_free_rounded,
    ),
    _CropAspectChoice(
      id: '1:1',
      labelKey: 'crop_aspect_1_1',
      ratio: 1.0,
      icon: Icons.crop_square_rounded,
    ),
    _CropAspectChoice(
      id: '4:5',
      labelKey: 'crop_aspect_4_5',
      ratio: 4.0 / 5.0,
      icon: Icons.crop_portrait_rounded,
    ),
    _CropAspectChoice(
      id: '16:9',
      labelKey: 'crop_aspect_16_9',
      ratio: 16.0 / 9.0,
      icon: Icons.crop_16_9_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedRatio = widget.initialAspectRatio;
    _decodeImage();
  }

  @override
  void dispose() {
    _transformCtrl.dispose();
    _decodedImage?.dispose();
    super.dispose();
  }

  Future<void> _decodeImage() async {
    try {
      final codec = await ui.instantiateImageCodec(widget.imageBytes);
      final frame = await codec.getNextFrame();
      if (!mounted) {
        frame.image.dispose();
        return;
      }
      setState(() {
        _decodedImage = frame.image;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _loading = false;
      });
    }
  }

  void _rotateClockwise() {
    setState(() {
      _rotationQuarterTurns = (_rotationQuarterTurns + 1) % 4;
      _transformCtrl.value = Matrix4.identity();
    });
  }

  void _resetTransform() {
    setState(() {
      _rotationQuarterTurns = 0;
      _transformCtrl.value = Matrix4.identity();
    });
  }

  Future<void> _applyCrop(Rect cropRectInViewport, Size viewportSize) async {
    final img = _decodedImage;
    if (img == null || _processing) return;

    setState(() => _processing = true);

    try {
      final resultBytes = await _renderCroppedBytes(
        image: img,
        cropRect: cropRectInViewport,
        viewportSize: viewportSize,
        transform: _transformCtrl.value,
        rotationTurns: _rotationQuarterTurns,
      );

      if (!mounted) return;
      Navigator.of(context).pop(resultBytes);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLang.tr('crop_error')}: $e'),
            backgroundColor: AppTok.danger(context),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _processing = false);
      }
    }
  }

  /// Calculates the transformation and draws the cropped region to a high-resolution PNG
  Future<Uint8List> _renderCroppedBytes({
    required ui.Image image,
    required Rect cropRect,
    required Size viewportSize,
    required Matrix4 transform,
    required int rotationTurns,
  }) async {
    final isRotated90or270 = rotationTurns % 2 != 0;
    final imgW = isRotated90or270
        ? image.height.toDouble()
        : image.width.toDouble();
    final imgH = isRotated90or270
        ? image.width.toDouble()
        : image.height.toDouble();

    // Calculate fitted layout size of image inside viewport
    final scaleFit = math.min(
      viewportSize.width / imgW,
      viewportSize.height / imgH,
    );
    final displayedW = imgW * scaleFit;
    final displayedH = imgH * scaleFit;
    final offsetX = (viewportSize.width - displayedW) / 2;
    final offsetY = (viewportSize.height - displayedH) / 2;

    // Viewport to image matrix
    // Point in viewport (pv) = transform * (Point on displayed image + (offsetX, offsetY))
    final matrix = Matrix4.identity()
      ..translate(offsetX, offsetY)
      ..multiply(transform);

    final inverted = Matrix4.tryInvert(matrix);

    // Target output size: cropRect aspect ratio with good resolution (min 800px, max 2400px)
    final cropAspect = cropRect.width / cropRect.height;
    final targetW = (cropRect.width > cropRect.height
            ? 1600.0
            : 1600.0 * cropAspect)
        .clamp(600.0, 2400.0);
    final targetH = (targetW / cropAspect).clamp(600.0, 2400.0);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, targetW, targetH));

    // Scale canvas from cropRect to target size
    final sx = targetW / cropRect.width;
    final sy = targetH / cropRect.height;
    canvas.scale(sx, sy);
    canvas.translate(-cropRect.left, -cropRect.top);

    // Apply viewport transform
    if (inverted != null) {
      canvas.transform(matrix.storage);
    }

    // Now draw image centered and rotated
    canvas.save();
    canvas.translate(displayedW / 2, displayedH / 2);
    canvas.rotate(rotationTurns * math.pi / 2);

    final rawW = image.width.toDouble();
    final rawH = image.height.toDouble();
    final drawRect = Rect.fromCenter(
      center: Offset.zero,
      width: isRotated90or270 ? displayedH : displayedW,
      height: isRotated90or270 ? displayedW : displayedH,
    );

    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, rawW, rawH),
      drawRect,
      Paint()..filterQuality = FilterQuality.high,
    );
    canvas.restore();

    final picture = recorder.endRecording();
    final renderedImage = await picture.toImage(targetW.round(), targetH.round());
    final byteData = await renderedImage.toByteData(format: ui.ImageByteFormat.png);
    renderedImage.dispose();

    if (byteData == null) {
      throw Exception('Failed to encode cropped image');
    }

    return byteData.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    final bg = const Color(0xFF100F17);
    final text = Colors.white;
    final accent = AppTok.accent(context);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: Text(
          widget.title ?? AppLang.tr('crop_image'),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            tooltip: AppLang.tr('crop_rotate'),
            onPressed: _rotateClockwise,
            icon: const Icon(Icons.rotate_right_rounded, color: Colors.white),
          ),
          IconButton(
            tooltip: AppLang.tr('crop_reset'),
            onPressed: _resetTransform,
            icon: const Icon(Icons.restart_alt_rounded, color: Colors.white),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : _errorMessage != null
              ? Center(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.white70),
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final viewportSize = Size(
                      constraints.maxWidth,
                      constraints.maxHeight - 110, // bottom bar space
                    );

                    final cropRect = _calculateCropRect(
                      viewportSize,
                      _selectedRatio,
                    );

                    return Column(
                      children: [
                        Expanded(
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // ── Interactive Image Viewer ──
                              InteractiveViewer(
                                transformationController: _transformCtrl,
                                minScale: 0.5,
                                maxScale: 4.0,
                                boundaryMargin: const EdgeInsets.all(300),
                                child: Center(
                                  child: RotatedBox(
                                    quarterTurns: _rotationQuarterTurns,
                                    child: RawImage(
                                      image: _decodedImage,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ),

                              // ── Non-interactive Crop Window & Grid Overlay ──
                              IgnorePointer(
                                child: CustomPaint(
                                  painter: _CropOverlayPainter(
                                    cropRect: cropRect,
                                    accentColor: accent,
                                  ),
                                  size: Size.infinite,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ── Bottom Controls Bar ──
                        _buildBottomBar(context, cropRect, viewportSize),
                      ],
                    );
                  },
                ),
    );
  }

  Rect _calculateCropRect(Size viewportSize, double? ratio) {
    const margin = 24.0;
    final maxW = viewportSize.width - margin * 2;
    final maxH = viewportSize.height - margin * 2;

    if (maxW <= 0 || maxH <= 0) {
      return Rect.fromLTWH(0, 0, viewportSize.width, viewportSize.height);
    }

    if (ratio == null) {
      // Free: 90% of screen bounds
      final w = maxW;
      final h = maxH;
      return Rect.fromCenter(
        center: Offset(viewportSize.width / 2, viewportSize.height / 2),
        width: w,
        height: h,
      );
    }

    double w;
    double h;
    if (maxW / maxH > ratio) {
      h = maxH;
      w = h * ratio;
    } else {
      w = maxW;
      h = w / ratio;
    }

    return Rect.fromCenter(
      center: Offset(viewportSize.width / 2, viewportSize.height / 2),
      width: w,
      height: h,
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    Rect cropRect,
    Size viewportSize,
  ) {
    final accent = AppTok.accent(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
      decoration: const BoxDecoration(
        color: Color(0xFF161520),
        border: Border(
          top: BorderSide(color: Color(0xFF262436), width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Aspect ratio chips ──
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _aspectRatios.map((item) {
                  final isSelected = item.ratio == _selectedRatio;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      selected: isSelected,
                      label: Text(
                        AppLang.tr(item.labelKey),
                        style: TextStyle(
                          color: isSelected ? Colors.black : Colors.white70,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                      avatar: Icon(
                        item.icon,
                        size: 16,
                        color: isSelected ? Colors.black : Colors.white70,
                      ),
                      selectedColor: accent,
                      backgroundColor: const Color(0xFF232130),
                      onSelected: (_) {
                        setState(() {
                          _selectedRatio = item.ratio;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),

            // ── Save & Cancel Actions ──
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _processing
                        ? null
                        : () => Navigator.of(context).pop(null),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Color(0xFF38354A)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(AppLang.tr('cancel')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: _processing
                        ? null
                        : () => _applyCrop(cropRect, viewportSize),
                    icon: _processing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : const Icon(Icons.check_rounded, color: Colors.black),
                    label: Text(
                      _processing
                          ? AppLang.tr('saving')
                          : AppLang.tr('crop_and_save'),
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: accent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// لایه سایه‌روشن، خطوط یک‌سوم و گوشه‌های راهنما روی کادر برش
class _CropOverlayPainter extends CustomPainter {
  const _CropOverlayPainter({
    required this.cropRect,
    required this.accentColor,
  });

  final Rect cropRect;
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    final fullRect = Offset.zero & size;

    // Darkened translucent mask outside crop rectangle
    final maskPaint = Paint()..color = const Color(0xB8000000);
    final path = Path()
      ..addRect(fullRect)
      ..addRect(cropRect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, maskPaint);

    // Crop border
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawRect(cropRect, borderPaint);

    // Rule of Thirds grid lines inside crop window
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final stepX = cropRect.width / 3;
    final stepY = cropRect.height / 3;

    canvas.drawLine(
      Offset(cropRect.left + stepX, cropRect.top),
      Offset(cropRect.left + stepX, cropRect.bottom),
      gridPaint,
    );
    canvas.drawLine(
      Offset(cropRect.left + stepX * 2, cropRect.top),
      Offset(cropRect.left + stepX * 2, cropRect.bottom),
      gridPaint,
    );
    canvas.drawLine(
      Offset(cropRect.left, cropRect.top + stepY),
      Offset(cropRect.right, cropRect.top + stepY),
      gridPaint,
    );
    canvas.drawLine(
      Offset(cropRect.left, cropRect.top + stepY * 2),
      Offset(cropRect.right, cropRect.top + stepY * 2),
      gridPaint,
    );

    // Accent corner indicators
    final cornerPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.square;
    const cornerLen = 18.0;

    // Top-Left
    canvas.drawLine(
      cropRect.topLeft,
      cropRect.topLeft + const Offset(cornerLen, 0),
      cornerPaint,
    );
    canvas.drawLine(
      cropRect.topLeft,
      cropRect.topLeft + const Offset(0, cornerLen),
      cornerPaint,
    );

    // Top-Right
    canvas.drawLine(
      cropRect.topRight,
      cropRect.topRight + const Offset(-cornerLen, 0),
      cornerPaint,
    );
    canvas.drawLine(
      cropRect.topRight,
      cropRect.topRight + const Offset(0, cornerLen),
      cornerPaint,
    );

    // Bottom-Left
    canvas.drawLine(
      cropRect.bottomLeft,
      cropRect.bottomLeft + const Offset(cornerLen, 0),
      cornerPaint,
    );
    canvas.drawLine(
      cropRect.bottomLeft,
      cropRect.bottomLeft + const Offset(0, -cornerLen),
      cornerPaint,
    );

    // Bottom-Right
    canvas.drawLine(
      cropRect.bottomRight,
      cropRect.bottomRight + const Offset(-cornerLen, 0),
      cornerPaint,
    );
    canvas.drawLine(
      cropRect.bottomRight,
      cropRect.bottomRight + const Offset(0, -cornerLen),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CropOverlayPainter oldDelegate) =>
      oldDelegate.cropRect != cropRect ||
      oldDelegate.accentColor != accentColor;
}
