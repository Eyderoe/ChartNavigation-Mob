import 'package:flutter/material.dart';

import '../models/manual_tab.dart';

class ManualBrowserTabBar extends StatelessWidget {
  const ManualBrowserTabBar({
    super.key,
    required this.tabs,
    required this.selectedTabId,
    required this.onSelect,
    required this.onClose,
  });

  final List<ManualTab> tabs;
  final String selectedTabId;
  final ValueChanged<String> onSelect;
  final ValueChanged<String> onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final ManualTab tab = tabs[index];
          final bool selected = tab.id == selectedTabId;

          return _TabItem(
            tab: tab,
            selected: selected,
            onTap: () => onSelect(tab.id),
            onClose: tab.isHome ? null : () => onClose(tab.id),
          );
        },
        separatorBuilder: (_, index) => const SizedBox(width: 6),
        itemCount: tabs.length,
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.tab,
    required this.selected,
    required this.onTap,
    this.onClose,
  });

  final ManualTab tab;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Material(
      color: selected ? scheme.surface : scheme.surfaceContainer,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minWidth: 120, maxWidth: 220),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                tab.isHome ? Icons.home : Icons.picture_as_pdf_outlined,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(tab.title, overflow: TextOverflow.ellipsis)),
              if (onClose != null)
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: onClose,
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.close, size: 14),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
