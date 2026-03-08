import 'package:flutter/material.dart';

import '../models/manual_outline_node.dart';

class ManualOutlinePanel extends StatelessWidget {
  const ManualOutlinePanel({
    super.key,
    required this.nodes,
    required this.onOutlineTap,
    this.isLoading = false,
    this.hintText,
  });

  final List<ManualOutlineNode> nodes;
  final ValueChanged<int> onOutlineTap;
  final bool isLoading;
  final String? hintText;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    if (hintText != null && hintText!.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(hintText!, textAlign: TextAlign.center),
        ),
      );
    }

    if (nodes.isEmpty) {
      return const Center(child: Text('当前 PDF 无大纲'));
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: nodes
          .map(
            (node) => _OutlineNodeItem(node: node, onOutlineTap: onOutlineTap),
          )
          .toList(),
    );
  }
}

class _OutlineNodeItem extends StatelessWidget {
  const _OutlineNodeItem({required this.node, required this.onOutlineTap});

  final ManualOutlineNode node;
  final ValueChanged<int> onOutlineTap;

  @override
  Widget build(BuildContext context) {
    if (node.children.isEmpty) {
      return ListTile(
        dense: true,
        leading: const Icon(Icons.chevron_right, size: 18),
        title: Text(node.title, overflow: TextOverflow.ellipsis),
        onTap: () => onOutlineTap(node.pageNumber),
      );
    }

    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 12),
      leading: const Icon(Icons.subdirectory_arrow_right, size: 18),
      title: Text(node.title, overflow: TextOverflow.ellipsis),
      children: node.children
          .map(
            (child) => Padding(
              padding: const EdgeInsets.only(left: 10),
              child: _OutlineNodeItem(node: child, onOutlineTap: onOutlineTap),
            ),
          )
          .toList(),
    );
  }
}
