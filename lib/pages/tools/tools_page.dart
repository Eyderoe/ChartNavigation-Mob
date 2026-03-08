import 'package:flutter/material.dart';

class ToolsPage extends StatefulWidget {
  const ToolsPage({super.key});

  @override
  State<ToolsPage> createState() => _ToolsPageState();
}

class _ToolsPageState extends State<ToolsPage> {
  static const String _convertTabId = 'convert';
  static const String _noteTabId = 'note';
  static const String _rvsmTabId = 'rvsm';

  static const List<_ToolTab> _tabs = <_ToolTab>[
    _ToolTab(id: _convertTabId, title: '单位换算', icon: Icons.swap_horiz),
    _ToolTab(id: _noteTabId, title: '笔记', icon: Icons.sticky_note_2_outlined),
    _ToolTab(id: _rvsmTabId, title: 'RVSM', icon: Icons.image_outlined),
  ];

  String _selectedTabId = _convertTabId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _ToolsTabBar(
              tabs: _tabs,
              selectedTabId: _selectedTabId,
              onSelect: (tabId) {
                setState(() {
                  _selectedTabId = tabId;
                });
              },
            ),
            Expanded(
              child: IndexedStack(
                index: switch (_selectedTabId) {
                  _convertTabId => 0,
                  _noteTabId => 1,
                  _ => 2,
                },
                children: const [
                  _UnitConvertPanel(),
                  _NotesPanel(),
                  _RvsmPanel(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolTab {
  const _ToolTab({required this.id, required this.title, required this.icon});

  final String id;
  final String title;
  final IconData icon;
}

class _ToolsTabBar extends StatelessWidget {
  const _ToolsTabBar({
    required this.tabs,
    required this.selectedTabId,
    required this.onSelect,
  });

  final List<_ToolTab> tabs;
  final String selectedTabId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: scheme.surfaceContainerHighest,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final _ToolTab tab = tabs[index];
          final bool selected = tab.id == selectedTabId;

          return Material(
            color: selected ? scheme.surface : scheme.surfaceContainer,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => onSelect(tab.id),
              child: Container(
                constraints: const BoxConstraints(minWidth: 120, maxWidth: 220),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(tab.icon, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(tab.title, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        separatorBuilder: (_, index) => const SizedBox(width: 6),
        itemCount: tabs.length,
      ),
    );
  }
}

class _UnitConvertPanel extends StatefulWidget {
  const _UnitConvertPanel();

  @override
  State<_UnitConvertPanel> createState() => _UnitConvertPanelState();
}

class _UnitConvertPanelState extends State<_UnitConvertPanel> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          _ConverterPairCard(
            title: '长度转换',
            leftLabel: '英尺 (ft)',
            rightLabel: '米 (m)',
            leftToRight: (v) => v * 0.3048,
            rightToLeft: (v) => v / 0.3048,
          ),
          _ConverterPairCard(
            title: '距离转换',
            leftLabel: '千米 (km)',
            rightLabel: '海里 (nmi)',
            leftToRight: (v) => v / 1.852,
            rightToLeft: (v) => v * 1.852,
          ),
          _ConverterPairCard(
            title: '重量转换',
            leftLabel: '磅 (lb)',
            rightLabel: '千克 (kg)',
            leftToRight: (v) => v * 0.45359237,
            rightToLeft: (v) => v / 0.45359237,
          ),
        ],
      ),
    );
  }
}

class _ConverterPairCard extends StatefulWidget {
  const _ConverterPairCard({
    required this.title,
    required this.leftLabel,
    required this.rightLabel,
    required this.leftToRight,
    required this.rightToLeft,
  });

  final String title;
  final String leftLabel;
  final String rightLabel;
  final double Function(double value) leftToRight;
  final double Function(double value) rightToLeft;

  @override
  State<_ConverterPairCard> createState() => _ConverterPairCardState();
}

class _ConverterPairCardState extends State<_ConverterPairCard> {
  late final TextEditingController _leftController;
  late final TextEditingController _rightController;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _leftController = TextEditingController(text: '1');
    _rightController = TextEditingController(
      text: _formatNumber(widget.leftToRight(1)),
    );
  }

  @override
  void dispose() {
    _leftController.dispose();
    _rightController.dispose();
    super.dispose();
  }

  void _syncFromLeft(String text) {
    if (_isSyncing) {
      return;
    }
    final double? value = double.tryParse(text);
    _isSyncing = true;
    _rightController.text = value == null
        ? ''
        : _formatNumber(widget.leftToRight(value));
    _isSyncing = false;
  }

  void _syncFromRight(String text) {
    if (_isSyncing) {
      return;
    }
    final double? value = double.tryParse(text);
    _isSyncing = true;
    _leftController.text = value == null
        ? ''
        : _formatNumber(widget.rightToLeft(value));
    _isSyncing = false;
  }

  String _formatNumber(double value) {
    return value.toStringAsFixed(6).replaceFirst(RegExp(r'\.?0+$'), '');
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _ConverterInput(
                    label: widget.leftLabel,
                    controller: _leftController,
                    onChanged: _syncFromLeft,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.swap_horiz),
                ),
                Expanded(
                  child: _ConverterInput(
                    label: widget.rightLabel,
                    controller: _rightController,
                    onChanged: _syncFromRight,
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

class _ConverterInput extends StatelessWidget {
  const _ConverterInput({
    required this.label,
    required this.controller,
    required this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      onChanged: onChanged,
    );
  }
}

class _NotesPanel extends StatefulWidget {
  const _NotesPanel();

  @override
  State<_NotesPanel> createState() => _NotesPanelState();
}

class _NotesPanelState extends State<_NotesPanel> {
  static const List<Color> _palette = <Color>[
    Colors.black,
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
  ];

  late final _DrawingController _drawingController;
  late final TransformationController _transformController;
  Color _currentColor = Colors.black;
  double _strokeWidth = 3;
  bool _panZoomMode = false;
  Size? _lastViewportSize;
  static const double _canvasScaleFactor = 3;

  @override
  void initState() {
    super.initState();
    _drawingController = _DrawingController();
    _transformController = TransformationController();
  }

  @override
  void dispose() {
    _drawingController.dispose();
    _transformController.dispose();
    super.dispose();
  }

  void _syncInitialViewport(Size viewportSize) {
    if (_lastViewportSize == viewportSize) {
      return;
    }
    _lastViewportSize = viewportSize;
    final double dx = -viewportSize.width * (_canvasScaleFactor - 1) / 2;
    final double dy = -viewportSize.height * (_canvasScaleFactor - 1) / 2;
    _transformController.value = Matrix4.identity()
      ..translateByDouble(dx, dy, 0, 1);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  const Text('颜色'),
                  const SizedBox(width: 8),
                  ..._palette.map((color) {
                    final bool selected = color == _currentColor;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _currentColor = color;
                          });
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selected
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey.shade300,
                              width: selected ? 2 : 1,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(width: 12),
                  const Text('粗细'),
                  Expanded(
                    child: Slider(
                      min: 1,
                      max: 12,
                      value: _strokeWidth,
                      onChanged: (value) {
                        setState(() {
                          _strokeWidth = value;
                        });
                      },
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _drawingController.clearAll,
                    icon: const Icon(Icons.delete_sweep_outlined),
                    label: const Text('擦除所有'),
                  ),
                  const SizedBox(width: 8),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment<bool>(value: false, label: Text('绘制')),
                      ButtonSegment<bool>(value: true, label: Text('缩放拖动')),
                    ],
                    selected: {_panZoomMode},
                    onSelectionChanged: (selection) {
                      setState(() {
                        _panZoomMode = selection.first;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final Size viewportSize = Size(
                  constraints.maxWidth,
                  constraints.maxHeight,
                );
                _syncInitialViewport(viewportSize);
                final Size boardSize = Size(
                  viewportSize.width * _canvasScaleFactor,
                  viewportSize.height * _canvasScaleFactor,
                );

                return DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: InteractiveViewer(
                    transformationController: _transformController,
                    constrained: false,
                    minScale: 0.5,
                    maxScale: 4,
                    panEnabled: _panZoomMode,
                    scaleEnabled: _panZoomMode,
                    child: SizedBox(
                      width: boardSize.width,
                      height: boardSize.height,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onPanStart: _panZoomMode
                            ? null
                            : (details) => _drawingController.startStroke(
                                  details.localPosition,
                                  color: _currentColor,
                                  width: _strokeWidth,
                                ),
                        onPanUpdate: _panZoomMode
                            ? null
                            : (details) => _drawingController.appendPoint(
                                  details.localPosition,
                                ),
                        onPanEnd: _panZoomMode
                            ? null
                            : (_) => _drawingController.endStroke(),
                        onPanCancel: _panZoomMode
                            ? null
                            : _drawingController.endStroke,
                        child: RepaintBoundary(
                          child: CustomPaint(
                            painter: _DrawingPainter(controller: _drawingController),
                            isComplex: true,
                            willChange: true,
                            child: const SizedBox.expand(),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawingController extends ChangeNotifier {
  final List<_DrawStroke> strokes = <_DrawStroke>[];
  _DrawStroke? _activeStroke;

  void startStroke(
    Offset point, {
    required Color color,
    required double width,
  }) {
    _activeStroke = _DrawStroke(
      path: Path()..moveTo(point.dx, point.dy),
      color: color,
      width: width,
    );
    notifyListeners();
  }

  void appendPoint(Offset point) {
    final _DrawStroke? stroke = _activeStroke;
    if (stroke == null) {
      return;
    }
    stroke.path.lineTo(point.dx, point.dy);
    notifyListeners();
  }

  void endStroke() {
    final _DrawStroke? stroke = _activeStroke;
    if (stroke == null) {
      return;
    }
    strokes.add(stroke);
    _activeStroke = null;
    notifyListeners();
  }

  void clearAll() {
    strokes.clear();
    _activeStroke = null;
    notifyListeners();
  }
}

class _DrawStroke {
  _DrawStroke({required this.path, required this.color, required this.width});

  final Path path;
  final Color color;
  final double width;
}

class _DrawingPainter extends CustomPainter {
  _DrawingPainter({required this.controller}) : super(repaint: controller);

  final _DrawingController controller;

  @override
  void paint(Canvas canvas, Size size) {
    for (final _DrawStroke stroke in controller.strokes) {
      canvas.drawPath(stroke.path, _buildPaint(stroke.color, stroke.width));
    }
    final _DrawStroke? activeStroke = controller._activeStroke;
    if (activeStroke != null) {
      canvas.drawPath(
        activeStroke.path,
        _buildPaint(activeStroke.color, activeStroke.width),
      );
    }
  }

  Paint _buildPaint(Color color, double width) {
    return Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
  }

  @override
  bool shouldRepaint(covariant _DrawingPainter oldDelegate) {
    return oldDelegate.controller != controller;
  }
}

class _RvsmPanel extends StatelessWidget {
  const _RvsmPanel();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: InteractiveViewer(
        minScale: 0.5,
        maxScale: 4,
        child: Image.asset('assets/images/rvsm.png', fit: BoxFit.contain),
      ),
    );
  }
}
