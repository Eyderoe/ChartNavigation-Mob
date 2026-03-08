import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

enum ChartDrawingImageLayer { general, plane }

enum ChartDrawingLabelLayer { general, plane }

class ChartDrawingStroke {
  ChartDrawingStroke({
    required this.color,
    required this.width,
    List<Offset>? points,
  }) : points = points ?? <Offset>[];

  final Color color;
  final double width;
  final List<Offset> points;
}

class ChartDrawingImage {
  ChartDrawingImage({
    required this.image,
    required this.position,
    required this.size,
    this.rotationDegrees = 0.0,
    this.layer = ChartDrawingImageLayer.general,
  });

  final ui.Image image;
  final Offset position;
  final Size size;
  final double rotationDegrees;
  final ChartDrawingImageLayer layer;
}

class ChartDrawingLabel {
  ChartDrawingLabel({
    required this.text,
    required this.position,
    this.color = Colors.white,
    this.fontSize = 12,
    this.layer = ChartDrawingLabelLayer.general,
  });

  final String text;
  final Offset position;
  final Color color;
  final double fontSize;
  final ChartDrawingLabelLayer layer;
}

class ChartPdfSession {
  ChartPdfSession()
    : controller = PdfViewerController(),
      pageJumpController = TextEditingController(text: '1');

  final PdfViewerController controller;
  final TextEditingController pageJumpController;

  int currentPage = 1;
  int totalPages = 0;
  bool isDocumentLoading = false;
  String? errorText;
  Uint8List? documentBytes;
  List<Size> pdfPageSizes = const <Size>[];
  Map<String, dynamic>? tmapData;

  bool isDrawingMode = false;
  Color drawingColor = Colors.red;
  double drawingWidth = 3;
  final List<ChartDrawingStroke> drawingStrokes = <ChartDrawingStroke>[];
  final List<ChartDrawingImage> drawingImages = <ChartDrawingImage>[];
  final List<ChartDrawingLabel> drawingLabels = <ChartDrawingLabel>[];
  final ValueNotifier<int> drawTick = ValueNotifier<int>(0);

  void setCurrentPage(int page) {
    currentPage = page;
    pageJumpController.text = page.toString();
  }

  void setTotalPages(int total) {
    totalPages = total;
    if (currentPage > totalPages && totalPages > 0) {
      currentPage = totalPages;
    }
    pageJumpController.text = currentPage.toString();
  }

  void setDocumentLoading(bool value) {
    isDocumentLoading = value;
  }

  void setDocumentBytes(Uint8List? value) {
    documentBytes = value;
  }

  void setPdfPageSizes(List<Size> sizes) {
    pdfPageSizes = sizes;
  }

  void setTmapData(Map<String, dynamic>? data) {
    tmapData = data;
  }

  bool get hasDocumentBytes {
    return documentBytes != null && documentBytes!.isNotEmpty;
  }

  void setError(String message) {
    errorText = message;
  }

  void clearError() {
    errorText = null;
  }

  void toggleDrawingMode() {
    isDrawingMode = !isDrawingMode;
  }

  void setDrawingColor(Color color) {
    drawingColor = color;
  }

  void setDrawingWidth(double width) {
    drawingWidth = width;
  }

  void startStroke(Offset point) {
    drawingStrokes.add(
      ChartDrawingStroke(
        color: drawingColor,
        width: drawingWidth,
        points: <Offset>[point],
      ),
    );
    notifyDrawChanged();
  }

  void appendStrokePoint(Offset point) {
    if (drawingStrokes.isEmpty) {
      return;
    }
    drawingStrokes.last.points.add(point);
    notifyDrawChanged();
  }

  void undoStroke() {
    if (drawingStrokes.isEmpty) {
      return;
    }
    drawingStrokes.removeLast();
    notifyDrawChanged();
  }

  void clearStrokes() {
    if (drawingStrokes.isEmpty) {
      return;
    }
    drawingStrokes.clear();
    notifyDrawChanged();
  }

  void addDrawingImage(ChartDrawingImage image) {
    drawingImages.add(image);
    notifyDrawChanged();
  }

  Rect _resolvePageRect({int? pageNumber}) {
    final List<Rect> pageLayouts = controller.layout.pageLayouts;
    final int targetPageNumber =
        pageNumber ?? controller.pageNumber ?? currentPage;
    final int pageIndex = (targetPageNumber - 1).clamp(
      0,
      pageLayouts.length - 1,
    );
    return pageLayouts[pageIndex];
  }

  Offset toDocumentOffsetFromPage(Offset pageOffset, {int? pageNumber}) {
    final Rect pageRect = _resolvePageRect(pageNumber: pageNumber);
    return pageRect.topLeft + pageOffset;
  }

  void drawCircleOnPage({
    required Offset centerInPage,
    double radius = 20,
    int steps = 36,
    int? pageNumber,
    Color? color,
    double? width,
    bool drawCenterDot = true,
  }) {
    final Offset center = toDocumentOffsetFromPage(
      centerInPage,
      pageNumber: pageNumber,
    );
    final Color strokeColor = color ?? drawingColor;
    final double strokeWidth = width ?? drawingWidth;

    final List<Offset> points = <Offset>[];
    for (int i = 0; i <= steps; i++) {
      final double angle = (i / steps) * 2 * math.pi;
      points.add(
        Offset(
          center.dx + radius * math.cos(angle),
          center.dy + radius * math.sin(angle),
        ),
      );
    }

    drawingStrokes.add(
      ChartDrawingStroke(
        color: strokeColor,
        width: strokeWidth,
        points: points,
      ),
    );

    if (drawCenterDot) {
      drawingStrokes.add(
        ChartDrawingStroke(
          color: strokeColor,
          width: strokeWidth,
          points: <Offset>[center],
        ),
      );
    }

    notifyDrawChanged();
  }

  void drawImageOnPage({
    required ui.Image image,
    required Offset centerInPage,
    required Size size,
    int? pageNumber,
    double rotationDegrees = 0.0,
    ChartDrawingImageLayer layer = ChartDrawingImageLayer.general,
    bool notify = true,
  }) {
    final Offset center = toDocumentOffsetFromPage(
      centerInPage,
      pageNumber: pageNumber,
    );
    final Offset topLeft = Offset(
      center.dx - size.width / 2,
      center.dy - size.height / 2,
    );
    drawingImages.add(
      ChartDrawingImage(
        image: image,
        position: topLeft,
        size: size,
        rotationDegrees: rotationDegrees,
        layer: layer,
      ),
    );
    if (notify) {
      notifyDrawChanged();
    }
  }

  Future<void> drawImageOnPageFromBytes({
    required Uint8List bytes,
    required Offset centerInPage,
    required Size size,
    int? pageNumber,
    double rotationDegrees = 0.0,
    ChartDrawingImageLayer layer = ChartDrawingImageLayer.general,
    bool notify = true,
  }) async {
    final Completer<ui.Image> completer = Completer<ui.Image>();
    ui.decodeImageFromList(bytes, completer.complete);
    final ui.Image image = await completer.future;
    drawImageOnPage(
      image: image,
      centerInPage: centerInPage,
      size: size,
      pageNumber: pageNumber,
      rotationDegrees: rotationDegrees,
      layer: layer,
      notify: notify,
    );
  }

  void clearImages({bool notify = true}) {
    if (drawingImages.isEmpty) {
      return;
    }
    drawingImages.clear();
    if (notify) {
      notifyDrawChanged();
    }
  }

  void clearImagesByLayer(ChartDrawingImageLayer layer, {bool notify = true}) {
    final int before = drawingImages.length;
    drawingImages.removeWhere((image) => image.layer == layer);
    if (notify && drawingImages.length != before) {
      notifyDrawChanged();
    }
  }

  void addDrawingLabel(ChartDrawingLabel label, {bool notify = true}) {
    drawingLabels.add(label);
    if (notify) {
      notifyDrawChanged();
    }
  }

  void drawLabelOnPage({
    required String text,
    required Offset positionInPage,
    int? pageNumber,
    Color color = Colors.white,
    double fontSize = 12,
    ChartDrawingLabelLayer layer = ChartDrawingLabelLayer.general,
    bool notify = true,
  }) {
    final Offset position = toDocumentOffsetFromPage(
      positionInPage,
      pageNumber: pageNumber,
    );
    addDrawingLabel(
      ChartDrawingLabel(
        text: text,
        position: position,
        color: color,
        fontSize: fontSize,
        layer: layer,
      ),
      notify: notify,
    );
  }

  void clearLabels({bool notify = true}) {
    if (drawingLabels.isEmpty) {
      return;
    }
    drawingLabels.clear();
    if (notify) {
      notifyDrawChanged();
    }
  }

  void clearLabelsByLayer(ChartDrawingLabelLayer layer, {bool notify = true}) {
    final int before = drawingLabels.length;
    drawingLabels.removeWhere((label) => label.layer == layer);
    if (notify && drawingLabels.length != before) {
      notifyDrawChanged();
    }
  }

  void notifyDrawChanged() {
    drawTick.value++;
  }

  void dispose() {
    drawTick.dispose();
    pageJumpController.dispose();
  }
}
