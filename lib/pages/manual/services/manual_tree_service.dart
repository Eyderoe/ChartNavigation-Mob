import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/manual_file_node.dart';

class ManualTreeService {
  const ManualTreeService();

  static const String rootFolderName = '手册';

  Future<List<ManualFileNode>> loadTree() async {
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final Directory rootDirectory = Directory(
      '${appDocDir.path}${Platform.pathSeparator}$rootFolderName',
    );
    _log(
      'loadTree start. cwd=${Directory.current.path}, appDocDir=${appDocDir.path}, root=${rootDirectory.path}',
    );

    if (!await rootDirectory.exists()) {
      _log('root directory not found: ${rootDirectory.path}');
      return const <ManualFileNode>[];
    }

    final List<FileSystemEntity> entities = rootDirectory.listSync();
    _log(
      'raw entities(${entities.length}): ${entities.map((e) => e.path).join(', ')}',
    );
    final List<ManualFileNode> nodes =
        entities.map(_buildNode).whereType<ManualFileNode>().toList()
          ..sort(_compareNodes);
    _log(
      'visible nodes(${nodes.length}): ${nodes.map((node) => node.path).join(', ')}',
    );

    return nodes;
  }

  ManualFileNode? _buildNode(FileSystemEntity entity) {
    final bool isDirectory = entity is Directory;
    final String path = entity.path;
    final String name = path.split(Platform.pathSeparator).last;

    if (entity is File) {
      if (!_isPdfFile(path)) {
        return null;
      }

      return ManualFileNode(name: name, path: path, isDirectory: false);
    }

    if (isDirectory) {
      final List<ManualFileNode> children =
          entity.listSync().map(_buildNode).whereType<ManualFileNode>().toList()
            ..sort(_compareNodes);

      if (children.isEmpty) {
        return null;
      }

      return ManualFileNode(
        name: name,
        path: path,
        isDirectory: true,
        children: children,
      );
    }

    return null;
  }

  bool _isPdfFile(String path) {
    return path.toLowerCase().endsWith('.pdf');
  }

  int _compareNodes(ManualFileNode a, ManualFileNode b) {
    if (a.isDirectory == b.isDirectory) {
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    }

    return a.isDirectory ? -1 : 1;
  }

  void _log(String message) {
    debugPrint('[ManualTreeService] $message');
  }
}
