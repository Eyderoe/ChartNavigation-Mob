class ManualOutlineNode {
  const ManualOutlineNode({
    required this.title,
    required this.pageNumber,
    this.children = const <ManualOutlineNode>[],
  });

  final String title;
  final int pageNumber;
  final List<ManualOutlineNode> children;
}
