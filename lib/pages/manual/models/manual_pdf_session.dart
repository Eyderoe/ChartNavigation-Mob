import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'dart:typed_data';

import 'manual_outline_node.dart';

class ManualPdfSession {
  ManualPdfSession()
    : controller = PdfViewerController(),
      viewerKey = GlobalKey<SfPdfViewerState>(),
      pageJumpController = TextEditingController(text: '1');

  final PdfViewerController controller;
  final GlobalKey<SfPdfViewerState> viewerKey;
  final TextEditingController pageJumpController;

  PdfPageLayoutMode pageLayoutMode = PdfPageLayoutMode.single;
  int currentPage = 1;
  int totalPages = 0;
  bool isOutlineVisible = false;
  bool isOutlineLoading = false;
  bool isDocumentLoading = false;
  List<ManualOutlineNode> outlines = const <ManualOutlineNode>[];
  String? outlineHintText;
  String? errorText;
  Uint8List? documentBytes;

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

  void setOutlines(List<ManualOutlineNode> value) {
    outlines = value;
  }

  void setOutlineLoading(bool value) {
    isOutlineLoading = value;
  }

  void setDocumentLoading(bool value) {
    isDocumentLoading = value;
  }

  void setDocumentBytes(Uint8List? value) {
    documentBytes = value;
  }

  bool get hasDocumentBytes {
    return documentBytes != null && documentBytes!.isNotEmpty;
  }

  void setOutlineHint(String? value) {
    outlineHintText = value;
  }

  void toggleOutline() {
    isOutlineVisible = !isOutlineVisible;
  }

  void setError(String message) {
    errorText = message;
  }

  void clearError() {
    errorText = null;
  }

  void dispose() {
    controller.dispose();
    pageJumpController.dispose();
  }
}
