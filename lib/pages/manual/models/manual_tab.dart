class ManualTab {
  const ManualTab({
    required this.id,
    required this.title,
    required this.path,
    this.isHome = false,
  });

  final String id;
  final String title;
  final String path;
  final bool isHome;
}
