import 'package:flutter/material.dart';

class ChartPdfToolbar extends StatelessWidget {
  const ChartPdfToolbar({
    super.key,
    required this.enabled,
    required this.isDarkMode,
    required this.currentPage,
    required this.totalPages,
    required this.pageJumpController,
    required this.isDrawingMode,
    required this.selectedDrawingColor,
    required this.selectedDrawingWidth,
    required this.onThemeToggle,
    required this.onPageSubmitted,
    required this.onZoomInPressed,
    required this.onZoomOutPressed,
    required this.onFitPagePressed,
    required this.onFitWidthPressed,
    required this.onDrawingModeToggle,
    required this.onDrawingColorChanged,
    required this.onDrawingWidthChanged,
    required this.onClearDrawing,
    required this.onUndoDrawing,
  });

  final bool enabled;
  final bool isDarkMode;
  final int currentPage;
  final int totalPages;
  final TextEditingController pageJumpController;
  final bool isDrawingMode;
  final Color selectedDrawingColor;
  final double selectedDrawingWidth;
  final VoidCallback onThemeToggle;
  final ValueChanged<String> onPageSubmitted;
  final VoidCallback onZoomInPressed;
  final VoidCallback onZoomOutPressed;
  final VoidCallback onFitPagePressed;
  final VoidCallback onFitWidthPressed;
  final VoidCallback onDrawingModeToggle;
  final ValueChanged<Color> onDrawingColorChanged;
  final ValueChanged<double> onDrawingWidthChanged;
  final VoidCallback onClearDrawing;
  final VoidCallback onUndoDrawing;

  static const List<Color> _drawingColors = <Color>[
    Colors.red,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.blue,
    Colors.black,
    Colors.white,
  ];

  static const List<double> _drawingWidths = <double>[2, 4, 6, 8];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double t = ((constraints.maxWidth - 760) / 440)
            .clamp(0.0, 1.0)
            .toDouble();
        final double smallGap = 4 + (6 * t);
        final double mediumGap = 8 + (8 * t);
        final double jumpWidth = 60 + (16 * t);
        final double buttonPadding = 6 + (6 * t);
        final double groupGap = 8 + (24 * t);

        return Container(
          width: double.infinity,
          height: 52,
          padding: EdgeInsets.symmetric(horizontal: smallGap),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Text(
                  '页数[${enabled ? currentPage : 0}/${enabled ? totalPages : 0}]',
                ),
                SizedBox(width: smallGap),
                SizedBox(
                  width: jumpWidth,
                  child: TextField(
                    controller: pageJumpController,
                    enabled: enabled,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.go,
                    decoration: const InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(),
                      hintText: '页码',
                    ),
                    onSubmitted: onPageSubmitted,
                  ),
                ),
                SizedBox(width: mediumGap),
                const VerticalDivider(width: 1, indent: 12, endIndent: 12),
                SizedBox(width: groupGap),
                _ToolbarIconButton(
                  icon: Icons.zoom_in,
                  label: '放大',
                  enabled: enabled,
                  onPressed: onZoomInPressed,
                  horizontalPadding: buttonPadding,
                ),
                _ToolbarIconButton(
                  icon: Icons.zoom_out,
                  label: '缩小',
                  enabled: enabled,
                  onPressed: onZoomOutPressed,
                  horizontalPadding: buttonPadding,
                ),
                _ToolbarIconButton(
                  icon: Icons.fit_screen,
                  label: '适应界面',
                  enabled: enabled,
                  onPressed: onFitPagePressed,
                  horizontalPadding: buttonPadding,
                ),
                _ToolbarIconButton(
                  icon: Icons.view_week_outlined,
                  label: '适应宽度',
                  enabled: enabled,
                  onPressed: onFitWidthPressed,
                  horizontalPadding: buttonPadding,
                ),
                SizedBox(width: mediumGap),
                const VerticalDivider(width: 1, indent: 12, endIndent: 12),
                SizedBox(width: mediumGap),
                _ToolbarIconButton(
                  icon: isDrawingMode
                      ? Icons.edit_off_outlined
                      : Icons.draw_outlined,
                  label: isDrawingMode ? '退出绘制' : '绘制',
                  enabled: enabled,
                  onPressed: onDrawingModeToggle,
                  horizontalPadding: buttonPadding,
                ),
                if (isDrawingMode) ...[
                  SizedBox(width: smallGap),
                  const Text('颜色'),
                  SizedBox(width: smallGap),
                  for (final Color color in _drawingColors)
                    Padding(
                      padding: EdgeInsets.only(right: smallGap),
                      child: _ColorDotButton(
                        color: color,
                        selected: selectedDrawingColor == color,
                        onPressed: enabled
                            ? () => onDrawingColorChanged(color)
                            : null,
                      ),
                    ),
                  SizedBox(width: smallGap),
                  const Text('粗细'),
                  SizedBox(width: smallGap),
                  for (final double width in _drawingWidths)
                    Padding(
                      padding: EdgeInsets.only(right: smallGap),
                      child: _WidthButton(
                        widthValue: width,
                        selected: selectedDrawingWidth == width,
                        enabled: enabled,
                        onPressed: () => onDrawingWidthChanged(width),
                      ),
                    ),
                  _ToolbarIconButton(
                    icon: Icons.undo_outlined,
                    label: '上一步',
                    enabled: enabled,
                    onPressed: onUndoDrawing,
                    horizontalPadding: buttonPadding,
                  ),
                  _ToolbarIconButton(
                    icon: Icons.delete_sweep_outlined,
                    label: '清除',
                    enabled: enabled,
                    onPressed: onClearDrawing,
                    horizontalPadding: buttonPadding,
                  ),
                ],
                SizedBox(width: mediumGap),
                const VerticalDivider(width: 1, indent: 12, endIndent: 12),
                SizedBox(width: mediumGap),
                _ToolbarIconButton(
                  icon: isDarkMode
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
                  label: isDarkMode ? '亮色' : '暗色',
                  enabled: enabled,
                  onPressed: onThemeToggle,
                  horizontalPadding: buttonPadding,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ToolbarIconButton extends StatelessWidget {
  const _ToolbarIconButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onPressed,
    required this.horizontalPadding,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onPressed;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      style: TextButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}

class _ColorDotButton extends StatelessWidget {
  const _ColorDotButton({
    required this.color,
    required this.selected,
    required this.onPressed,
  });

  final Color color;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline,
            width: selected ? 2 : 1,
          ),
        ),
      ),
    );
  }
}

class _WidthButton extends StatelessWidget {
  const _WidthButton({
    required this.widthValue,
    required this.selected,
    required this.enabled,
    required this.onPressed,
  });

  final double widthValue;
  final bool selected;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(30, 28),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        side: BorderSide(
          color: selected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outline,
        ),
      ),
      onPressed: enabled ? onPressed : null,
      child: Text(widthValue.toInt().toString()),
    );
  }
}
