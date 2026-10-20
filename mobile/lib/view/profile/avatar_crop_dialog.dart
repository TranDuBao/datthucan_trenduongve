import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../common/color_extension.dart';

class AvatarCropDialog extends StatefulWidget {
  final Uint8List imageBytes;
  const AvatarCropDialog({super.key, required this.imageBytes});

  @override
  State<AvatarCropDialog> createState() => _AvatarCropDialogState();
}

class _AvatarCropDialogState extends State<AvatarCropDialog> {
  final TransformationController _transformController = TransformationController();
  bool _isCropping = false;

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  Future<Uint8List?> _cropImage() async {
    setState(() => _isCropping = true);
    try {
      final codec = await ui.instantiateImageCodec(widget.imageBytes);
      final frame = await codec.getNextFrame();
      final srcImg = frame.image;
      final iw = srcImg.width.toDouble();
      final ih = srcImg.height.toDouble();
      const cropDiameter = 280.0;

      final matrix = _transformController.value;
      final tx = -matrix.entry(0, 3);
      final ty = -matrix.entry(1, 3);
      final scale = matrix.entry(0, 0).clamp(0.01, 100.0);
      final displayScale = iw / cropDiameter;
      final srcSize = (cropDiameter / scale) * displayScale;
      final srcLeft = (tx / scale) * displayScale;
      final srcTop = (ty / scale) * displayScale;

      final safeLeft = srcLeft.clamp(0.0, (iw - srcSize).clamp(0.0, iw)).toDouble();
      final safeTop = srcTop.clamp(0.0, (ih - srcSize).clamp(0.0, ih)).toDouble();
      final safeSize = srcSize.clamp(1.0, min(iw - safeLeft, ih - safeTop)).toDouble();

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      const outSize = 400.0;
      canvas.clipPath(Path()..addOval(const Rect.fromLTWH(0, 0, outSize, outSize)));
      canvas.drawImageRect(
        srcImg,
        Rect.fromLTWH(safeLeft, safeTop, safeSize, safeSize),
        const Rect.fromLTWH(0, 0, outSize, outSize),
        Paint(),
      );
      final picture = recorder.endRecording();
      final img = await picture.toImage(outSize.toInt(), outSize.toInt());
      final bd = await img.toByteData(format: ui.ImageByteFormat.png);
      return bd?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Crop error: $e');
      return null;
    } finally {
      if (mounted) setState(() => _isCropping = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161920) : Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Chỉnh sửa ảnh đại diện',
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: isDark ? const Color(0xFF9096A5) : const Color(0xFF8C93A3),
                  ),
                  onPressed: () => Navigator.of(context).pop(null),
                ),
              ],
            ),
            Text(
              'Kéo & pinch để chỉnh vị trí ảnh',
              style: TextStyle(
                color: isDark ? const Color(0xFF9096A5) : const Color(0xFF8C93A3),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 280,
              height: 280,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ClipRect(
                    child: InteractiveViewer(
                      transformationController: _transformController,
                      minScale: 0.5,
                      maxScale: 4.0,
                      child: Image.memory(
                        widget.imageBytes,
                        fit: BoxFit.cover,
                        width: 280,
                        height: 280,
                      ),
                    ),
                  ),
                  IgnorePointer(
                    child: CustomPaint(
                      size: const Size(280, 280),
                      painter: _CircleMaskPainter(isDark: isDark),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
                      side: BorderSide(
                        color: isDark ? const Color(0xFF333846) : const Color(0xFFDDDDDD),
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => Navigator.of(context).pop(null),
                    child: Text(
                      'Hủy',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
                      backgroundColor: TColor.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _isCropping
                        ? null
                        : () async {
                            final result = await _cropImage();
                            if (context.mounted) Navigator.of(context).pop(result);
                          },
                    child: _isCropping
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            'Xác nhận',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
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

class _CircleMaskPainter extends CustomPainter {
  final bool isDark;
  _CircleMaskPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;
    final outerPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(Rect.fromCircle(center: center, radius: radius))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(outerPath, Paint()..color = Colors.black.withOpacity(0.5));
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = TColor.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
