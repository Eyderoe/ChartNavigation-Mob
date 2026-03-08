import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../models/manual_pdf_session.dart';

class ManualFileContentPanel extends StatelessWidget {
  const ManualFileContentPanel({
    super.key,
    required this.session,
    required this.onPageChanged,
    required this.onDocumentLoaded,
    required this.onDocumentLoadFailed,
  });

  final ManualPdfSession session;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<PdfDocumentLoadedDetails> onDocumentLoaded;
  final ValueChanged<String> onDocumentLoadFailed;

  @override
  Widget build(BuildContext context) {
    if (!session.hasDocumentBytes) {
      return const Center(child: Text('PDF 内容为空，无法加载'));
    }

    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color viewerBackground = isDarkMode
        ? const Color(0xFF1F1B24)
        : const Color(0xFFECE6F0);

    return Stack(
      children: [
        SfPdfViewerTheme(
          data: SfPdfViewerThemeData(backgroundColor: viewerBackground),
          child: ColorFiltered(
            colorFilter: isDarkMode
                ? const ColorFilter.matrix([
                    -1, 0, 0, 0, 255,
                    0, -1, 0, 0, 255,
                    0, 0, -1, 0, 255,
                    0, 0, 0, 1, 0,
                  ])
                : const ColorFilter.matrix([
                    1, 0, 0, 0, 0,
                    0, 1, 0, 0, 0,
                    0, 0, 1, 0, 0,
                    0, 0, 0, 1, 0,
                  ]),
            child: SfPdfViewer.memory(
              session.documentBytes!,
              key: session.viewerKey,
              controller: session.controller,
              canShowPaginationDialog: false,
              canShowScrollHead: true,
              pageLayoutMode: session.pageLayoutMode,
              onDocumentLoaded: onDocumentLoaded,
              onPageChanged: (details) => onPageChanged(details.newPageNumber),
              onDocumentLoadFailed: (details) {
                onDocumentLoadFailed('${details.error}: ${details.description}');
              },
            ),
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
    );
  }
}
