import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdfrx/pdfrx.dart';

import '../models/chart_pdf_session.dart';

class ChartFileContentPanel extends StatelessWidget {
  const ChartFileContentPanel({
    super.key,
    required this.sourceName,
    required this.session,
    required this.onPageChanged,
    required this.onDocumentLoaded,
    required this.onDocumentLoadFailed,
    required this.onDrawStart,
    required this.onDrawUpdate,
    required this.onDrawEnd,
  });

  final String sourceName;
  final ChartPdfSession session;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<PdfViewerController> onDocumentLoaded;
  final ValueChanged<String> onDocumentLoadFailed;
  final ValueChanged<Offset> onDrawStart;
  final ValueChanged<Offset> onDrawUpdate;
  final VoidCallback onDrawEnd;

  @override
  Widget build(BuildContext context) {
    if (!session.hasDocumentBytes) {
      return const Center(child: Text('PDF 内容为空，无法加载'));
    }

    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color viewerBackground = isDarkMode
        ? const Color(0xFF1F1B24)
        : const Color(0xFFECE6F0);

    return ClipRect(
      child: Stack(
        children: [
          ColorFiltered(
            colorFilter: isDarkMode
                ? const ColorFilter.matrix([
                    -1,
                    0,
                    0,
                    0,
                    255,
                    0,
                    -1,
                    0,
                    0,
                    255,
                    0,
                    0,
                    -1,
                    0,
                    255,
                    0,
                    0,
                    0,
                    1,
                    0,
                  ])
                : const ColorFilter.matrix([
                    1,
                    0,
                    0,
                    0,
                    0,
                    0,
                    1,
                    0,
                    0,
                    0,
                    0,
                    0,
                    1,
                    0,
                    0,
                    0,
                    0,
                    0,
                    1,
                    0,
                  ]),
            child: Listener(
              onPointerSignal: (event) {
                if (event is! PointerScrollEvent ||
                    !session.controller.isReady) {
                  return;
                }
                final keys = HardwareKeyboard.instance.logicalKeysPressed;
                final bool zoomModifierPressed =
                    keys.contains(LogicalKeyboardKey.controlLeft) ||
                    keys.contains(LogicalKeyboardKey.controlRight) ||
                    keys.contains(LogicalKeyboardKey.metaLeft) ||
                    keys.contains(LogicalKeyboardKey.metaRight);
                if (!zoomModifierPressed) {
                  return;
                }
                final double nextZoom =
                    (session.controller.currentZoom +
                            (event.scrollDelta.dy < 0 ? 0.1 : -0.1))
                        .clamp(1.0, 3.0);
                session.controller.setZoom(
                  session.controller.localToDocument(event.localPosition),
                  nextZoom,
                  duration: Duration.zero,
                );
              },
              child: PdfViewer.data(
                session.documentBytes!,
                sourceName: sourceName,
                controller: session.controller,
                params: PdfViewerParams(
                  backgroundColor: viewerBackground,
                  textSelectionParams: const PdfTextSelectionParams(
                    enabled: false,
                  ),
                  maxScale: 3.0,
                  minScale: 1.0,
                  useAlternativeFitScaleAsMinScale: false,
                  onViewerReady: (_, controller) {
                    onDocumentLoaded(controller);
                  },
                  onPageChanged: (pageNumber) {
                    onPageChanged(pageNumber ?? 1);
                  },
                  onDocumentLoadFinished: (documentRef, succeeded) {
                    if (succeeded) {
                      return;
                    }
                    final listenable = documentRef.resolveListenable();
                    onDocumentLoadFailed(
                      (listenable.error ?? 'PDF 加载失败').toString(),
                    );
                  },
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: _DrawingOverlay(
              enabled: session.isDrawingMode,
              session: session,
              isDarkMode: isDarkMode,
              onDrawStart: onDrawStart,
              onDrawUpdate: onDrawUpdate,
              onDrawEnd: onDrawEnd,
            ),
          ),
          if (session.errorText != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: Theme.of(context).colorScheme.errorContainer,
                padding: const EdgeInsets.all(10),
                child: Text(
                  session.errorText!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DrawingPainter extends CustomPainter {
  _DrawingPainter({
    required this.strokes,
    required this.images,
    required this.labels,
    required this.controller,
    required this.isDarkMode,
    required Listenable repaint,
  }) : super(repaint: repaint);

  final List<ChartDrawingStroke> strokes;
  final List<ChartDrawingImage> images;
  final List<ChartDrawingLabel> labels;
  final PdfViewerController controller;
  final bool isDarkMode;

  @override
  void paint(Canvas canvas, Size size) {
    for (final ChartDrawingImage drawingImage in images) {
      final Offset topLeft = _toScreenOffset(drawingImage.position);
      final Offset bottomRight = _toScreenOffset(
        drawingImage.position +
            Offset(drawingImage.size.width, drawingImage.size.height),
      );
      final Rect destRect = Rect.fromPoints(topLeft, bottomRight);
      final Rect srcRect = Rect.fromLTWH(
        0,
        0,
        drawingImage.image.width.toDouble(),
        drawingImage.image.height.toDouble(),
      );
      final double rotationRadians =
          drawingImage.rotationDegrees * math.pi / 180;
      if (rotationRadians == 0.0) {
        canvas.drawImageRect(drawingImage.image, srcRect, destRect, Paint());
        continue;
      }

      canvas.save();
      canvas.translate(destRect.center.dx, destRect.center.dy);
      canvas.rotate(rotationRadians);
      final Rect rotatedRect = Rect.fromCenter(
        center: Offset.zero,
        width: destRect.width,
        height: destRect.height,
      );
      canvas.drawImageRect(drawingImage.image, srcRect, rotatedRect, Paint());
      canvas.restore();
    }

    for (final ChartDrawingStroke stroke in strokes) {
      if (stroke.points.length < 2) {
        if (stroke.points.isEmpty) {
          continue;
        }
        final Paint dotPaint = Paint()
          ..color = stroke.color
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.fill;
        canvas.drawCircle(
          _toScreenOffset(stroke.points.first),
          stroke.width / 2,
          dotPaint,
        );
        continue;
      }

      final Paint paint = Paint()
        ..color = stroke.color
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke.width;

      final Offset firstPoint = _toScreenOffset(stroke.points.first);
      final Path path = Path()..moveTo(firstPoint.dx, firstPoint.dy);
      for (int i = 1; i < stroke.points.length; i++) {
        final Offset point = _toScreenOffset(stroke.points[i]);
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, paint);
    }

    for (final ChartDrawingLabel label in labels) {
      final Color fillColor = isDarkMode ? Colors.white : Colors.black;
      final Color strokeColor = isDarkMode ? Colors.black : Colors.white;
      final TextPainter strokePainter = TextPainter(
        text: TextSpan(
          text: label.text,
          style: TextStyle(
            fontSize: label.fontSize,
            fontWeight: FontWeight.w600,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3
              ..color = strokeColor,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: size.width);
      final TextPainter fillPainter = TextPainter(
        text: TextSpan(
          text: label.text,
          style: TextStyle(
            color: fillColor,
            fontSize: label.fontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: size.width);
      final Offset textOffset = _toScreenOffset(label.position);
      strokePainter.paint(canvas, textOffset);
      fillPainter.paint(canvas, textOffset);
    }
  }

  Offset _toScreenOffset(Offset documentOffset) {
    if (!controller.isReady) {
      return documentOffset;
    }
    return controller.documentToLocal(documentOffset);
  }

  @override
  bool shouldRepaint(covariant _DrawingPainter oldDelegate) {
    return oldDelegate.strokes != strokes ||
        oldDelegate.images != images ||
        oldDelegate.labels != labels ||
        oldDelegate.controller != controller;
  }
}

class _DrawingOverlay extends StatefulWidget {
  const _DrawingOverlay({
    required this.enabled,
    required this.session,
    required this.isDarkMode,
    required this.onDrawStart,
    required this.onDrawUpdate,
    required this.onDrawEnd,
  });

  final bool enabled;
  final ChartPdfSession session;
  final bool isDarkMode;
  final ValueChanged<Offset> onDrawStart;
  final ValueChanged<Offset> onDrawUpdate;
  final VoidCallback onDrawEnd;

  @override
  State<_DrawingOverlay> createState() => _DrawingOverlayState();
}

class _DrawingOverlayState extends State<_DrawingOverlay> {
  bool _isDrawing = false;

  void _onPointerDown(PointerDownEvent event) {
    if (!widget.enabled) {
      return;
    }
    if (event.kind != PointerDeviceKind.mouse ||
        event.buttons != kPrimaryMouseButton) {
      return;
    }
    _isDrawing = true;
    widget.onDrawStart(_toDocumentOffset(event.localPosition));
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (!widget.enabled || !_isDrawing) {
      return;
    }
    widget.onDrawUpdate(_toDocumentOffset(event.localPosition));
  }

  void _onPointerUp(PointerEvent event) {
    if (!_isDrawing) {
      return;
    }
    _isDrawing = false;
    widget.onDrawEnd();
  }

  Offset _toDocumentOffset(Offset localPosition) {
    if (!widget.session.controller.isReady) {
      return localPosition;
    }
    return widget.session.controller.localToDocument(localPosition);
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !widget.enabled,
      child: ClipRect(
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: _onPointerDown,
          onPointerMove: _onPointerMove,
          onPointerUp: _onPointerUp,
          onPointerCancel: _onPointerUp,
          child: RepaintBoundary(
            child: CustomPaint(
              painter: _DrawingPainter(
                strokes: widget.session.drawingStrokes,
                images: widget.session.drawingImages,
                labels: widget.session.drawingLabels,
                controller: widget.session.controller,
                isDarkMode: widget.isDarkMode,
                repaint: Listenable.merge(<Listenable>[
                  widget.session.controller,
                  widget.session.drawTick,
                ]),
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
  }
}
