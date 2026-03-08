import 'package:flutter/material.dart';

class ManualPdfToolbar extends StatelessWidget {
  const ManualPdfToolbar({
    super.key,
    required this.enabled,
    required this.isDarkMode,
    required this.currentPage,
    required this.totalPages,
    required this.pageJumpController,
    required this.onThemeToggle,
    required this.onOutlinePressed,
    required this.onPageSubmitted,
    required this.onZoomInPressed,
    required this.onZoomOutPressed,
    required this.onFitPagePressed,
    required this.onFitWidthPressed,
  });

  final bool enabled;
  final bool isDarkMode;
  final int currentPage;
  final int totalPages;
  final TextEditingController pageJumpController;
  final VoidCallback onThemeToggle;
  final VoidCallback onOutlinePressed;
  final ValueChanged<String> onPageSubmitted;
  final VoidCallback onZoomInPressed;
  final VoidCallback onZoomOutPressed;
  final VoidCallback onFitPagePressed;
  final VoidCallback onFitWidthPressed;

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
                _ToolbarIconButton(
                  icon: Icons.account_tree_outlined,
                  label: '大纲',
                  enabled: enabled,
                  onPressed: onOutlinePressed,
                  horizontalPadding: buttonPadding,
                ),
                SizedBox(width: smallGap),
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
