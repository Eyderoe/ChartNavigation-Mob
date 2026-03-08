class ChartFileNode {
  const ChartFileNode({
    required this.name,
    required this.path,
    required this.isDirectory,
    this.children = const <ChartFileNode>[],
  });

  final String name;
  final String path;
  final bool isDirectory;
  final List<ChartFileNode> children;
}
