class ManualFileNode {
  const ManualFileNode({
    required this.name,
    required this.path,
    required this.isDirectory,
    this.children = const <ManualFileNode>[],
  });

  final String name;
  final String path;
  final bool isDirectory;
  final List<ManualFileNode> children;
}
