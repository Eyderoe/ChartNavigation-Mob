import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import 'models/manual_file_node.dart';
import 'models/manual_outline_node.dart';
import 'models/manual_pdf_session.dart';
import 'models/manual_tab.dart';
import 'services/manual_tree_service.dart';
import 'widgets/manual_browser_tab_bar.dart';
import 'widgets/manual_file_content_panel.dart';
import 'widgets/manual_home_tree_panel.dart';
import 'widgets/manual_outline_panel.dart';
import 'widgets/manual_pdf_toolbar.dart';

class ManualPage extends StatefulWidget {
  const ManualPage({
    super.key,
    required this.isDarkMode,
    required this.onThemeToggle,
  });

  final bool isDarkMode;
  final VoidCallback onThemeToggle;

  @override
  State<ManualPage> createState() => _ManualPageState();
}

class _ManualPageState extends State<ManualPage> {
  static const ManualTab _homeTab = ManualTab(
    id: 'home',
    title: '首页',
    path: ManualTreeService.rootFolderName,
    isHome: true,
  );

  final ManualTreeService _treeService = const ManualTreeService();
  final List<ManualTab> _tabs = <ManualTab>[_homeTab];
  final Map<String, ManualPdfSession> _pdfSessions =
      <String, ManualPdfSession>{};

  String _selectedTabId = _homeTab.id;
  List<ManualFileNode> _treeNodes = const <ManualFileNode>[];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTree();
  }

  @override
  void dispose() {
    for (final ManualPdfSession session in _pdfSessions.values) {
      session.dispose();
    }
    super.dispose();
  }

  Future<void> _loadTree() async {
    setState(() {
      _isLoading = true;
    });

    final List<ManualFileNode> nodes = await _treeService.loadTree();

    if (!mounted) {
      return;
    }

    setState(() {
      _treeNodes = nodes;
      _isLoading = false;
    });
  }

  Future<void> _openTabFromFile(ManualFileNode node) async {
    final int existingIndex = _tabs.indexWhere((tab) => tab.path == node.path);
    if (existingIndex != -1) {
      setState(() {
        _selectedTabId = _tabs[existingIndex].id;
      });
      return;
    }

    final ManualTab tab = ManualTab(
      id: node.path,
      title: node.name,
      path: node.path,
    );

    final ManualPdfSession session = ManualPdfSession();
    session.setDocumentLoading(true);

    setState(() {
      _tabs.add(tab);
      _pdfSessions[tab.id] = session;
      _selectedTabId = tab.id;
    });

    await _preparePdfForTab(tab.id, tab.path);
  }

  void _closeTab(String tabId) {
    if (tabId == _homeTab.id) {
      return;
    }

    final int targetIndex = _tabs.indexWhere((tab) => tab.id == tabId);
    if (targetIndex == -1) {
      return;
    }

    setState(() {
      _tabs.removeAt(targetIndex);
      _pdfSessions.remove(tabId)?.dispose();
      if (_selectedTabId == tabId) {
        _selectedTabId = _tabs[targetIndex - 1].id;
      }
    });
  }

  ManualTab get _currentTab {
    return _tabs.firstWhere((tab) => tab.id == _selectedTabId);
  }

  ManualPdfSession? get _currentPdfSession {
    if (_currentTab.isHome) {
      return null;
    }
    return _pdfSessions[_selectedTabId];
  }

  void _showUnsupportedMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _toggleOutline() {
    final ManualPdfSession? session = _currentPdfSession;
    if (session == null) {
      return;
    }

    setState(() {
      session.toggleOutline();
    });

    if (session.isOutlineVisible &&
        !session.isOutlineLoading &&
        session.outlines.isEmpty) {
      _loadOutlinesForTab(_currentTab);
    }
  }

  void _jumpToOutlinePage(int pageNumber) {
    final ManualPdfSession? session = _currentPdfSession;
    if (session == null) {
      return;
    }

    final int maxPage = session.totalPages == 0 ? 1 : session.totalPages;
    final int targetPage = pageNumber.clamp(1, maxPage);
    session.controller.jumpToPage(targetPage);
    session.pageJumpController.text = targetPage.toString();
  }

  void _zoomIn() {
    final ManualPdfSession? session = _currentPdfSession;
    if (session == null) {
      return;
    }

    final double nextZoom = (session.controller.zoomLevel + 0.25).clamp(
      1.0,
      3.0,
    );
    session.controller.zoomLevel = nextZoom;
  }

  void _zoomOut() {
    final ManualPdfSession? session = _currentPdfSession;
    if (session == null) {
      return;
    }

    final double nextZoom = (session.controller.zoomLevel - 0.25).clamp(
      1.0,
      3.0,
    );
    session.controller.zoomLevel = nextZoom;
  }

  void _fitPage() {
    final ManualPdfSession? session = _currentPdfSession;
    if (session == null) {
      return;
    }

    setState(() {
      session.pageLayoutMode = PdfPageLayoutMode.single;
      session.controller.zoomLevel = 1.0;
    });
  }

  void _fitWidth() {
    final ManualPdfSession? session = _currentPdfSession;
    if (session == null) {
      return;
    }

    setState(() {
      session.pageLayoutMode = PdfPageLayoutMode.continuous;
      session.controller.zoomLevel = 1.0;
    });
  }

  void _jumpToPage(String inputText) {
    final ManualPdfSession? session = _currentPdfSession;
    if (session == null) {
      return;
    }

    final int? inputPage = int.tryParse(inputText.trim());
    if (inputPage == null) {
      _showUnsupportedMessage('请输入正确的页码');
      session.pageJumpController.text = session.currentPage.toString();
      return;
    }

    final int maxPage = session.totalPages == 0 ? 1 : session.totalPages;
    final int targetPage = inputPage.clamp(1, maxPage);
    session.controller.jumpToPage(targetPage);
    session.pageJumpController.text = targetPage.toString();
  }

  Future<void> _loadOutlinesForTab(ManualTab tab) async {
    if (tab.isHome) {
      return;
    }

    final ManualPdfSession? session = _pdfSessions[tab.id];
    if (session == null) {
      return;
    }
    if (session.isOutlineLoading) {
      return;
    }

    try {
      final Uint8List? bytes = session.documentBytes;
      if (bytes == null || bytes.isEmpty) {
        return;
      }

      if (mounted) {
        setState(() {
          session.setOutlineLoading(true);
          session.setOutlineHint(null);
        });
      }

      final PdfDocument document = PdfDocument(inputBytes: bytes);
      final List<ManualOutlineNode> outlines;
      try {
        outlines = _buildOutlineNodes(document.bookmarks, document);
      } finally {
        document.dispose();
      }

      if (!mounted) {
        return;
      }

      final ManualPdfSession? latestSession = _pdfSessions[tab.id];
      if (latestSession == null) {
        return;
      }

      setState(() {
        latestSession.setOutlines(outlines);
        latestSession.setOutlineLoading(false);
        latestSession.setOutlineHint(outlines.isEmpty ? '当前 PDF 无大纲' : null);
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      final ManualPdfSession? latestSession = _pdfSessions[tab.id];
      if (latestSession == null) {
        return;
      }
      setState(() {
        latestSession.setOutlineLoading(false);
        latestSession.setOutlines(const <ManualOutlineNode>[]);
        latestSession.setOutlineHint('大纲解析失败，请稍后重试');
      });
    }
  }

  Future<void> _preparePdfForTab(String tabId, String path) async {
    final ManualPdfSession? session = _pdfSessions[tabId];
    if (session == null) {
      return;
    }

    try {
      final File file = File(path);
      if (!await file.exists()) {
        throw Exception('文件不存在');
      }

      final Uint8List bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        throw Exception('文件内容为空');
      }

      final PdfDocument document = PdfDocument(inputBytes: bytes);
      try {
        if (document.pages.count <= 0) {
          throw Exception('未检测到可渲染页面');
        }
      } finally {
        document.dispose();
      }

      if (!mounted) {
        return;
      }

      final ManualPdfSession? latestSession = _pdfSessions[tabId];
      if (latestSession == null) {
        return;
      }

      setState(() {
        latestSession.setDocumentBytes(bytes);
        latestSession.setDocumentLoading(false);
        latestSession.clearError();
        latestSession.setOutlines(const <ManualOutlineNode>[]);
        latestSession.setOutlineHint(null);
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      final ManualPdfSession? latestSession = _pdfSessions[tabId];
      if (latestSession == null) {
        return;
      }

      setState(() {
        latestSession.setDocumentBytes(null);
        latestSession.setDocumentLoading(false);
        latestSession.setError('PDF 预校验失败: $error');
        latestSession.setOutlines(const <ManualOutlineNode>[]);
        latestSession.setOutlineHint('该 PDF 可能已损坏或格式不受支持');
      });
    }
  }

  List<ManualOutlineNode> _buildOutlineNodes(
    PdfBookmarkBase root,
    PdfDocument document,
  ) {
    final List<ManualOutlineNode> result = <ManualOutlineNode>[];

    for (int index = 0; index < root.count; index++) {
      final PdfBookmark bookmark = root[index];
      final String title = bookmark.title.trim().isEmpty
          ? '未命名条目 ${index + 1}'
          : bookmark.title;
      final int pageNumber = _resolveBookmarkPageNumber(bookmark, document);

      result.add(
        ManualOutlineNode(
          title: title,
          pageNumber: pageNumber,
          children: _buildOutlineNodes(bookmark, document),
        ),
      );
    }

    return result;
  }

  int _resolveBookmarkPageNumber(PdfBookmark bookmark, PdfDocument document) {
    final PdfDestination? destination = bookmark.destination;
    if (destination == null) {
      return 1;
    }

    try {
      final int pageIndex = document.pages.indexOf(destination.page);
      if (pageIndex >= 0) {
        return pageIndex + 1;
      }
    } catch (_) {
      return 1;
    }

    return 1;
  }

  Widget _buildPdfContent(
    ManualTab currentTab,
    ManualPdfSession currentSession,
  ) {
    if (currentSession.isDocumentLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!currentSession.hasDocumentBytes) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(currentSession.errorText ?? 'PDF 未就绪，无法加载'),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () {
                setState(() {
                  currentSession.setDocumentLoading(true);
                  currentSession.clearError();
                });
                _preparePdfForTab(currentTab.id, currentTab.path);
              },
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    final Widget viewer = ManualFileContentPanel(
      session: currentSession,
      onPageChanged: (page) {
        setState(() {
          currentSession.setCurrentPage(page);
        });
      },
      onDocumentLoaded: (_) {
        setState(() {
          currentSession.clearError();
          currentSession.setTotalPages(currentSession.controller.pageCount);
          currentSession.setCurrentPage(currentSession.controller.pageNumber);
        });
      },
      onDocumentLoadFailed: (message) {
        setState(() {
          currentSession.setError(message);
          currentSession.setOutlineLoading(false);
          currentSession.setOutlines(const <ManualOutlineNode>[]);
          currentSession.setOutlineHint('PDF 加载失败，无法读取大纲');
        });
      },
    );

    if (!currentSession.isOutlineVisible) {
      return viewer;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double outlineWidth = constraints.maxWidth * 0.25;

        return Row(
          children: [
            SizedBox(
              width: outlineWidth,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLowest,
                ),
                child: ManualOutlinePanel(
                  nodes: currentSession.outlines,
                  onOutlineTap: _jumpToOutlinePage,
                  isLoading: currentSession.isOutlineLoading,
                  hintText: currentSession.outlineHintText,
                ),
              ),
            ),
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            Expanded(child: viewer),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ManualTab currentTab = _currentTab;
    final ManualPdfSession? currentSession = _currentPdfSession;
    final double topInset = MediaQuery.paddingOf(context).top;
    final Color topBarColor = Theme.of(
      context,
    ).colorScheme.surfaceContainerHighest;

    return Scaffold(
      body: Column(
        children: [
          if (topInset > 0) Container(height: topInset, color: topBarColor),
          ManualBrowserTabBar(
            tabs: _tabs,
            selectedTabId: _selectedTabId,
            onSelect: (tabId) {
              setState(() {
                _selectedTabId = tabId;
              });
            },
            onClose: _closeTab,
          ),
          if (currentSession != null)
            ManualPdfToolbar(
              enabled: true,
              isDarkMode: widget.isDarkMode,
              currentPage: currentSession.currentPage,
              totalPages: currentSession.totalPages,
              pageJumpController: currentSession.pageJumpController,
              onThemeToggle: widget.onThemeToggle,
              onOutlinePressed: _toggleOutline,
              onPageSubmitted: _jumpToPage,
              onZoomInPressed: _zoomIn,
              onZoomOutPressed: _zoomOut,
              onFitPagePressed: _fitPage,
              onFitWidthPressed: _fitWidth,
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : currentTab.isHome
                ? ManualHomeTreePanel(
                    nodes: _treeNodes,
                    onFileOpen: _openTabFromFile,
                  )
                : currentSession == null
                ? const Center(child: Text('PDF 会话不存在，请重新打开文件'))
                : _buildPdfContent(currentTab, currentSession),
          ),
        ],
      ),
    );
  }
}
