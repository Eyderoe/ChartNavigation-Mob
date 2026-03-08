import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sfpdf;
import '../../affine/plane.pb.dart';
import 'models/chart_file_node.dart';
import 'models/chart_pdf_session.dart';
import 'models/chart_tab.dart';
import 'services/chart_tree_service.dart';
import 'widgets/chart_browser_tab_bar.dart';
import 'widgets/chart_file_content_panel.dart';
import 'widgets/chart_home_tree_panel.dart';
import 'widgets/chart_pdf_toolbar.dart';
import '../../affine/affine_transformer.dart';
import '../../affine/udp.dart';

class ChartPage extends StatefulWidget {
  const ChartPage({
    super.key,
    required this.isDarkMode,
    required this.onThemeToggle,
    required this.udpReceiver,
  });

  final bool isDarkMode;
  final VoidCallback onThemeToggle;
  final udpReceive udpReceiver;

  @override
  State<ChartPage> createState() => _ChartPageState();
}

class _ChartPageState extends State<ChartPage> {
  static const ChartTab _homeTab = ChartTab(
    id: 'home',
    title: '首页',
    path: ChartTreeService.rootFolderName,
    isHome: true,
  );

  late ChartPageHelper _chartPageHelper;
  final ChartTreeService _treeService = const ChartTreeService();
  final List<ChartTab> _tabs = <ChartTab>[_homeTab];
  final Map<String, ChartPdfSession> _pdfSessions = <String, ChartPdfSession>{};

  String _selectedTabId = _homeTab.id;
  List<ChartFileNode> _treeNodes = const <ChartFileNode>[];
  bool _isLoading = true;
  bool _lastWlanAvailable = false;
  Timer? _planeRenderTimer;
  ui.Image? _planeImagePrimary;
  ui.Image? _planeImageSecondary;
  bool _isPlaneRendering = false;
  String? _lastLoadedTmapKey;
  Map<String, dynamic>? _lastLoadedTmapData;

  @override
  void initState() {
    super.initState();
    _chartPageHelper = ChartPageHelper();
    _loadTree();
    // 初始化上次WLAN状态
    _lastWlanAvailable = _chartPageHelper.wlanAvailable;
    // 注册UDP回调函数
    widget.udpReceiver.addCallback((available) {
      if (available != _lastWlanAvailable) {
        setState(() {
          _chartPageHelper.wlanAvailable = available;
          _lastWlanAvailable = available;
          debugPrint('WLAN状态变化: $available');
        });
      }
    });
    _startPlaneRenderTimer();
  }

  @override
  void dispose() {
    _planeRenderTimer?.cancel();
    for (final ChartPdfSession session in _pdfSessions.values) {
      session.dispose();
    }
    _chartPageHelper.dispose();
    super.dispose();
  }

  void _startPlaneRenderTimer() {
    _planeRenderTimer?.cancel();
    _planeRenderTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      unawaited(_renderPlanesTick());
    });
  }

  Future<void> _ensurePlaneImagesLoaded() async {
    if (_planeImagePrimary != null && _planeImageSecondary != null) {
      return;
    }
    final List<ByteData> assets = await Future.wait(<Future<ByteData>>[
      rootBundle.load('assets/images/plane.png'),
      rootBundle.load('assets/images/plane_2.png'),
    ]);
    _planeImagePrimary ??= await _decodeUiImage(assets[0].buffer.asUint8List());
    _planeImageSecondary ??= await _decodeUiImage(
      assets[1].buffer.asUint8List(),
    );
  }

  Future<ui.Image> _decodeUiImage(Uint8List bytes) async {
    final Completer<ui.Image> completer = Completer<ui.Image>();
    ui.decodeImageFromList(bytes, completer.complete);
    return completer.future;
  }

  Future<void> _renderPlanesTick() async {
    if (_isPlaneRendering) {
      return;
    }
    _isPlaneRendering = true;
    try {
      final ChartPdfSession? session = _currentPdfSession;
      if (session == null ||
          !session.hasDocumentBytes ||
          !session.controller.isReady ||
          !_chartPageHelper.wlanAvailable ||
          !_chartPageHelper.affineAvailable) {
        session?.clearImagesByLayer(ChartDrawingImageLayer.plane);
        session?.clearLabelsByLayer(ChartDrawingLabelLayer.plane);
        return;
      }

      await _ensurePlaneImagesLoaded();
      if (_planeImagePrimary == null || _planeImageSecondary == null) {
        return;
      }

      final List<Plane> validPlanes = widget.udpReceiver.planes
          .where((plane) => plane.hasLat() && plane.hasLon())
          .where((plane) => plane.lat != 0 || plane.lon != 0)
          .toList(growable: false);

      session.clearImagesByLayer(ChartDrawingImageLayer.plane, notify: false);
      session.clearLabelsByLayer(ChartDrawingLabelLayer.plane, notify: false);
      if (validPlanes.isEmpty) {
        session.notifyDrawChanged();
        return;
      }

      final Plane leadPlane = validPlanes.first;
      for (int i = 0; i < validPlanes.length; i++) {
        final Plane plane = validPlanes[i];
        if (i > 0) {
          final double distanceNm = _chartPageHelper.distanceNmBetweenLatLon(
            leadPlane.lat.toDouble(),
            leadPlane.lon.toDouble(),
            plane.lat.toDouble(),
            plane.lon.toDouble(),
          );
          final int altDiff = (plane.alt - leadPlane.alt).abs();
          if (distanceNm >= 30 || altDiff >= 9900) {
            continue;
          }
        }

        final result = _chartPageHelper.transformer.transform(
          plane.lat.toDouble(),
          plane.lon.toDouble(),
        );
        if (!result.x.isFinite || !result.y.isFinite) {
          continue;
        }
        session.drawImageOnPage(
          image: i == 0 ? _planeImagePrimary! : _planeImageSecondary!,
          centerInPage: Offset(result.x, result.y),
          size: const Size(32, 32),
          pageNumber: session.currentPage,
          rotationDegrees: _chartPageHelper.rotateDegree + plane.trk.toDouble(),
          layer: ChartDrawingImageLayer.plane,
          notify: false,
        );
        if (i > 0 && plane.flight.trim().isNotEmpty) {
          final int altDelta = plane.alt - leadPlane.alt;
          final int altDeltaHundreds = (altDelta / 100).round();
          final int absAltDeltaHundreds = altDeltaHundreds.abs();
          final String altDeltaText = altDeltaHundreds < 0
              ? '-${absAltDeltaHundreds.toString().padLeft(2, '0')}'
              : absAltDeltaHundreds.toString().padLeft(2, '0');
          final String vsArrow = plane.vs > 500
              ? '↑'
              : (plane.vs < -500 ? '↓' : '');
          session.drawLabelOnPage(
            text: '${plane.flight}(${plane.icao})\n$altDeltaText$vsArrow',
            positionInPage: Offset(result.x + 18, result.y - 18),
            pageNumber: session.currentPage,
            fontSize: 13,
            layer: ChartDrawingLabelLayer.plane,
            notify: false,
          );
        }
      }
      session.notifyDrawChanged();
    } catch (error) {
      debugPrint('绘制飞机图标失败: $error');
    } finally {
      _isPlaneRendering = false;
    }
  }

  Future<void> _loadTree() async {
    setState(() {
      _isLoading = true;
    });

    final List<ChartFileNode> nodes = await _treeService.loadTree();

    if (!mounted) {
      return;
    }

    setState(() {
      _treeNodes = nodes;
      _isLoading = false;
    });
  }

  Future<void> _openTabFromFile(ChartFileNode node) async {
    final int existingIndex = _tabs.indexWhere((tab) => tab.path == node.path);
    if (existingIndex != -1) {
      final String targetTabId = _tabs[existingIndex].id;
      setState(() {
        _selectedTabId = targetTabId;
      });
      _applyAffineForTabId(targetTabId);
      return;
    }

    final ChartTab tab = ChartTab(
      id: node.path,
      title: node.name,
      path: node.path,
    );

    final ChartPdfSession session = ChartPdfSession();
    session.setDocumentLoading(true);

    setState(() {
      _tabs.add(tab);
      _pdfSessions[tab.id] = session;
      _selectedTabId = tab.id;
    });
    _applyAffineForTabId(tab.id);

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

    String? nextSelectedTabId;
    setState(() {
      _tabs.removeAt(targetIndex);
      _pdfSessions.remove(tabId)?.dispose();
      if (_selectedTabId == tabId) {
        _selectedTabId = _tabs[targetIndex - 1].id;
        nextSelectedTabId = _selectedTabId;
      }
    });
    if (nextSelectedTabId != null) {
      _applyAffineForTabId(nextSelectedTabId!);
    }
  }

  void _applyAffineForTabId(String tabId) {
    final ChartTab tab = _tabs.firstWhere((item) => item.id == tabId);
    if (tab.isHome) {
      _chartPageHelper.setAffineData(null, '');
      return;
    }
    final ChartPdfSession? session = _pdfSessions[tabId];
    final String pdfFileName = tab.path.split(Platform.pathSeparator).last;
    _chartPageHelper.setAffineData(session?.tmapData, pdfFileName);
  }

  ChartTab get _currentTab {
    return _tabs.firstWhere((tab) => tab.id == _selectedTabId);
  }

  ChartPdfSession? get _currentPdfSession {
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

  Future<void> _zoomIn() async {
    final ChartPdfSession? session = _currentPdfSession;
    if (session == null || !session.controller.isReady) {
      return;
    }

    final double nextZoom = (session.controller.currentZoom + 0.25).clamp(
      1.0,
      3.0,
    );
    await session.controller.setZoom(
      session.controller.centerPosition,
      nextZoom,
      duration: Duration.zero,
    );
  }

  Future<void> _zoomOut() async {
    final ChartPdfSession? session = _currentPdfSession;
    if (session == null || !session.controller.isReady) {
      return;
    }

    final double nextZoom = (session.controller.currentZoom - 0.25).clamp(
      1.0,
      3.0,
    );
    await session.controller.setZoom(
      session.controller.centerPosition,
      nextZoom,
      duration: Duration.zero,
    );
  }

  Future<void> _fitPage() async {
    final ChartPdfSession? session = _currentPdfSession;
    if (session == null || !session.controller.isReady) {
      return;
    }
    final int pageNumber = session.controller.pageNumber ?? session.currentPage;
    final Matrix4? matrix = session.controller.calcMatrixForFit(
      pageNumber: pageNumber,
    );
    await session.controller.goTo(matrix, duration: Duration.zero);
  }

  Future<void> _fitWidth() async {
    final ChartPdfSession? session = _currentPdfSession;
    if (session == null || !session.controller.isReady) {
      return;
    }
    final int pageNumber = session.controller.pageNumber ?? session.currentPage;
    final Matrix4? matrix = session.controller.calcMatrixFitWidthForPage(
      pageNumber: pageNumber,
    );
    await session.controller.goTo(matrix, duration: Duration.zero);
  }

  Future<void> _jumpToPage(String inputText) async {
    final ChartPdfSession? session = _currentPdfSession;
    if (session == null || !session.controller.isReady) {
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
    await session.controller.goToPage(
      pageNumber: targetPage,
      duration: Duration.zero,
    );
    session.pageJumpController.text = targetPage.toString();
  }

  void _toggleDrawingMode() {
    final ChartPdfSession? session = _currentPdfSession;
    if (session == null) {
      return;
    }

    setState(() {
      session.toggleDrawingMode();
    });
  }

  void _setDrawingColor(Color color) {
    final ChartPdfSession? session = _currentPdfSession;
    if (session == null) {
      return;
    }

    setState(() {
      session.setDrawingColor(color);
    });
  }

  void _setDrawingWidth(double width) {
    final ChartPdfSession? session = _currentPdfSession;
    if (session == null) {
      return;
    }

    setState(() {
      session.setDrawingWidth(width);
    });
  }

  void _clearDrawing() {
    final ChartPdfSession? session = _currentPdfSession;
    if (session == null) {
      return;
    }

    setState(() {
      session.clearStrokes();
    });
  }

  void _undoDrawing() {
    final ChartPdfSession? session = _currentPdfSession;
    if (session == null) {
      return;
    }

    setState(() {
      session.undoStroke();
    });
  }

  void _handleDrawStart(Offset point) {
    final ChartPdfSession? session = _currentPdfSession;
    if (session == null || !session.isDrawingMode) {
      return;
    }
    session.startStroke(point);
  }

  void _handleDrawUpdate(Offset point) {
    final ChartPdfSession? session = _currentPdfSession;
    if (session == null || !session.isDrawingMode) {
      return;
    }
    session.appendStrokePoint(point);
  }

  void _handleDrawEnd() {}

  Future<void> _preparePdfForTab(String tabId, String path) async {
    final ChartPdfSession? session = _pdfSessions[tabId];
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

      final sfpdf.PdfDocument document = sfpdf.PdfDocument(inputBytes: bytes);
      final List<Size> pageSizes = <Size>[];
      try {
        if (document.pages.count <= 0) {
          throw Exception('未检测到可渲染页面');
        }
        for (int i = 0; i < document.pages.count; i++) {
          pageSizes.add(document.pages[i].size);
        }
      } finally {
        document.dispose();
      }

      // 读取对应的Tmap文件
      final Map<String, dynamic>? tmapData = await _loadTmapData(path);
      final String pdfFileName = path.split(Platform.pathSeparator).last;
      _chartPageHelper.setAffineData(tmapData, pdfFileName);

      if (!mounted) {
        return;
      }

      final ChartPdfSession? latestSession = _pdfSessions[tabId];
      if (latestSession == null) {
        return;
      }

      setState(() {
        latestSession.setDocumentBytes(bytes);
        latestSession.setPdfPageSizes(pageSizes);
        latestSession.setTmapData(tmapData);
        latestSession.setDocumentLoading(false);
        latestSession.clearError();
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      final ChartPdfSession? latestSession = _pdfSessions[tabId];
      if (latestSession == null) {
        return;
      }

      setState(() {
        latestSession.setDocumentBytes(null);
        latestSession.setPdfPageSizes(const <Size>[]);
        latestSession.setTmapData(null);
        latestSession.setDocumentLoading(false);
        latestSession.setError('PDF 预校验失败: $error');
      });
    }
  }

  String _resolveTmapFileName(String pdfPath) {
    final String pdfFileName = pdfPath.split(Platform.pathSeparator).last;
    return pdfFileName.length >= 4
        ? '${pdfFileName.substring(0, 4)}.Tmap'
        : '${pdfFileName.split('.').first}.Tmap';
  }

  Future<Map<String, dynamic>?> _loadTmapData(String pdfPath) async {
    final String tmapFileName = _resolveTmapFileName(pdfPath);
    if (_lastLoadedTmapKey == tmapFileName) {
      return _lastLoadedTmapData;
    }

    try {
      // 获取应用文档目录
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      // 构建Tmap文件路径（在数据文件夹中）
      final String tmapPath =
          '${appDocDir.path}${Platform.pathSeparator}数据${Platform.pathSeparator}$tmapFileName';

      final File tmapFile = File(tmapPath);
      if (!await tmapFile.exists()) {
        _lastLoadedTmapKey = tmapFileName;
        _lastLoadedTmapData = null;
        return null;
      }

      // 读取并解析Tmap文件
      final String tmapContent = await tmapFile.readAsString();
      final Map<String, dynamic> tmapData = json.decode(tmapContent);
      _lastLoadedTmapKey = tmapFileName;
      _lastLoadedTmapData = tmapData;
      return tmapData;
    } catch (e) {
      debugPrint('加载Tmap文件失败: $e');
      _lastLoadedTmapKey = tmapFileName;
      _lastLoadedTmapData = null;
      return null;
    }
  }

  Widget _buildPdfContent(ChartTab currentTab, ChartPdfSession currentSession) {
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

    final Widget viewer = ChartFileContentPanel(
      key: ValueKey<String>('chart_pdf_${currentTab.id}'),
      sourceName: currentTab.path,
      session: currentSession,
      onPageChanged: (page) {
        setState(() {
          currentSession.setCurrentPage(page);
        });
      },
      onDocumentLoaded: (controller) {
        setState(() {
          currentSession.clearError();
          currentSession.setTotalPages(controller.pageCount);
          currentSession.setCurrentPage(controller.pageNumber ?? 1);
        });
      },
      onDocumentLoadFailed: (message) {
        setState(() {
          currentSession.setError(message);
        });
      },
      onDrawStart: _handleDrawStart,
      onDrawUpdate: _handleDrawUpdate,
      onDrawEnd: _handleDrawEnd,
    );

    return viewer;
  }

  @override
  Widget build(BuildContext context) {
    final ChartTab currentTab = _currentTab;
    final ChartPdfSession? currentSession = _currentPdfSession;
    final double topInset = MediaQuery.paddingOf(context).top;
    final Color topBarColor = Theme.of(
      context,
    ).colorScheme.surfaceContainerHighest;

    return Scaffold(
      body: Column(
        children: [
          if (topInset > 0) Container(height: topInset, color: topBarColor),
          ChartBrowserTabBar(
            tabs: _tabs,
            selectedTabId: _selectedTabId,
            onSelect: (tabId) {
              setState(() {
                _selectedTabId = tabId;
              });
              _applyAffineForTabId(tabId);
            },
            onClose: _closeTab,
          ),
          if (currentSession != null)
            ChartPdfToolbar(
              enabled: true,
              isDarkMode: widget.isDarkMode,
              currentPage: currentSession.currentPage,
              totalPages: currentSession.totalPages,
              pageJumpController: currentSession.pageJumpController,
              isDrawingMode: currentSession.isDrawingMode,
              selectedDrawingColor: currentSession.drawingColor,
              selectedDrawingWidth: currentSession.drawingWidth,
              onThemeToggle: widget.onThemeToggle,
              onPageSubmitted: _jumpToPage,
              onZoomInPressed: _zoomIn,
              onZoomOutPressed: _zoomOut,
              onFitPagePressed: _fitPage,
              onFitWidthPressed: _fitWidth,
              onDrawingModeToggle: _toggleDrawingMode,
              onDrawingColorChanged: _setDrawingColor,
              onDrawingWidthChanged: _setDrawingWidth,
              onClearDrawing: _clearDrawing,
              onUndoDrawing: _undoDrawing,
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : currentTab.isHome
                ? ChartHomeTreePanel(
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

/// 航图页面的辅助类，管理仿射数据
class ChartPageHelper {
  bool affineAvailable = false;
  bool wlanAvailable = false;
  double rotateDegree = 0.0;
  final AffineTransformer transformer = AffineTransformer();

  ChartPageHelper();

  double distanceNmBetweenLatLon(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadiusNm = 3440.065;
    final double lat1Rad = lat1 * _degToRad;
    final double lon1Rad = lon1 * _degToRad;
    final double lat2Rad = lat2 * _degToRad;
    final double lon2Rad = lon2 * _degToRad;
    final double dLat = lat2Rad - lat1Rad;
    final double dLon = lon2Rad - lon1Rad;

    final double a =
        _sinSquared(dLat / 2) +
        math.cos(lat1Rad) * math.cos(lat2Rad) * _sinSquared(dLon / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusNm * c;
  }

  static const double _degToRad = math.pi / 180.0;

  double _sinSquared(double value) {
    final double sinValue = math.sin(value);
    return sinValue * sinValue;
  }

  void setAffineData(Map<String, dynamic>? tmapData, String pdfFileName) {
    if (tmapData == null) {
      affineAvailable = false;
      return;
    }

    // 提取PDF文件名（不含扩展名）
    final String baseName = pdfFileName.split('.').first;
    if (!tmapData.containsKey(baseName)) {
      affineAvailable = false;
      return;
    }

    final dynamic pageData = tmapData[baseName];
    if (pageData is! List || pageData.isEmpty) {
      affineAvailable = false;
      return;
    }

    // 读取rotate值和type值
    double threshold = 10.0;
    dynamic infoMap = null;

    // 检查pageData的第一个元素是否为List
    if (pageData[0] is List) {
      final dynamic innerList = pageData[0];

      // 检查innerList的第一个元素是否为Map
      if (innerList is List && innerList.isNotEmpty && innerList[0] is Map) {
        infoMap = innerList[0];

        // 读取rotate值
        if (infoMap.containsKey('rotate')) {
          rotateDegree = double.tryParse(infoMap['rotate'].toString()) ?? 0.0;
        }

        // 确定threshold值
        if (infoMap.containsKey('type') && infoMap['type'] == 'terminal') {
          threshold = 5.0;
        }
      }
    } else if (pageData[0] is Map) {
      // 处理直接是Map的情况
      infoMap = pageData[0];

      // 读取rotate值
      if (infoMap.containsKey('rotate')) {
        rotateDegree = double.tryParse(infoMap['rotate'].toString()) ?? 0.0;
      }

      // 确定threshold值
      if (infoMap.containsKey('type') && infoMap['type'] == 'terminal') {
        threshold = 5.0;
      }
    }

    // 处理数据
    List<dynamic> dataList = [];
    if (pageData[0] is List) {
      // 如果pageData[0]是List，那么数据在pageData[0]的子列表中
      final dynamic innerList = pageData[0];
      if (innerList is List && innerList.length > 1) {
        dataList = innerList.sublist(1);
      }
    } else if (pageData.length > 1) {
      // 如果pageData[0]是Map，那么数据在pageData的子列表中
      dataList = pageData.sublist(1);
    }

    final List<List<double>> processedData = [];

    for (final item in dataList) {
      if (item is List && item.length >= 4) {
        final List<double> row = [];
        for (int j = 0; j < 4; j++) {
          final value = double.tryParse(item[j].toString());
          if (value != null) {
            row.add(value);
          } else {
            break;
          }
        }
        if (row.length == 4) {
          processedData.add(row);
        }
      }
    }

    // 执行变换
    affineAvailable = transformer.loadData(processedData, threshold);

    // 如果变换成功，输出评估误差
    if (affineAvailable) {
      final evalResult = transformer.evaluate(printResult: true);
      print(
        'Affine transformation successful for $baseName. Processed ${processedData.length} points. RMS error: ${evalResult.rmsError.toStringAsFixed(2)}',
      );
    }
  }

  void dispose() {
    // 清理资源
  }
}
