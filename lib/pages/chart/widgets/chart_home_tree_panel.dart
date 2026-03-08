import 'package:flutter/material.dart';

import '../models/chart_file_node.dart';

class ChartHomeTreePanel extends StatelessWidget {
  const ChartHomeTreePanel({
    super.key,
    required this.nodes,
    required this.onFileOpen,
  });

  final List<ChartFileNode> nodes;
  final ValueChanged<ChartFileNode> onFileOpen;

  @override
  Widget build(BuildContext context) {
    if (nodes.isEmpty) {
      return const Center(child: Text('航图目录为空，请在“航图”文件夹中添加 PDF 文件'));
    }

    return ListView(
      key: const PageStorageKey<String>('chart_home_tree_scroll'),
      padding: const EdgeInsets.all(12),
      children: nodes.map((node) {
        return _TreeNode(node: node, onFileOpen: onFileOpen);
      }).toList(),
    );
  }
}

class _TreeNode extends StatelessWidget {
  const _TreeNode({required this.node, required this.onFileOpen});

  final ChartFileNode node;
  final ValueChanged<ChartFileNode> onFileOpen;

  @override
  Widget build(BuildContext context) {
    if (!node.isDirectory) {
      return ListTile(
        contentPadding: const EdgeInsets.only(left: 8, right: 8),
        leading: const Icon(Icons.picture_as_pdf_outlined),
        title: Text(node.name),
        onTap: () => onFileOpen(node),
      );
    }

    return ExpansionTile(
      key: PageStorageKey<String>('chart_tree_${node.path}'),
      tilePadding: const EdgeInsets.only(left: 8, right: 8),
      leading: const Icon(Icons.folder_outlined),
      collapsedIconColor: Theme.of(context).colorScheme.onSurfaceVariant,
      iconColor: Theme.of(context).colorScheme.primary,
      title: Text(node.name),
      children: node.children
          .map(
            (child) => Padding(
              padding: const EdgeInsets.only(left: 12),
              child: _TreeNode(node: child, onFileOpen: onFileOpen),
            ),
          )
          .toList(),
    );
  }
}
