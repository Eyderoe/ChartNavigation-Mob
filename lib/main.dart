import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';
import 'affine/udp.dart';
import 'pages/manual/manual_page.dart';
import 'pages/chart/chart_page.dart';
import 'pages/enroute/enroute_page.dart';
import 'pages/tools/tools_page.dart';
import 'pages/setting/setting_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  pdfrxFlutterInitialize(dismissPdfiumWasmWarnings: true);
  if (!kIsWeb) {
    await _createFolders();
  }
  runApp(const MyApp());
}

Future<void> _createFolders() async {
  // 要创建的文件夹列表
  List<String> folders = ['手册', '航图', '数据'];

  // 获取应用程序文档目录
  Directory appDocDir;
  try {
    appDocDir = await getApplicationDocumentsDirectory();
    debugPrint('应用文档目录: ${appDocDir.path}');
  } catch (e) {
    debugPrint('获取文档目录失败: $e');
    return;
  }

  for (String folder in folders) {
    Directory directory = Directory('${appDocDir.path}/$folder');
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
      debugPrint('创建文件夹: ${directory.path}');
    } else {
      debugPrint('文件夹已存在: ${directory.path}');
    }
  }

  // 确保临时目录存在
  try {
    Directory tempDir = await getTemporaryDirectory();
    debugPrint('临时目录: ${tempDir.path}');
    if (!tempDir.existsSync()) {
      tempDir.createSync(recursive: true);
      debugPrint('创建临时目录: ${tempDir.path}');
    }
  } catch (e) {
    debugPrint('获取或创建临时目录失败: $e');
  }

  // 确保Flutter VM服务需要的/tmp目录存在
  try {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    // 获取应用沙箱的根目录
    Directory sandboxRoot = appDocDir.parent;
    // 创建/tmp目录
    Directory tmpDir = Directory('${sandboxRoot.path}/tmp');
    debugPrint('Flutter VM服务临时目录: ${tmpDir.path}');
    if (!tmpDir.existsSync()) {
      tmpDir.createSync(recursive: true);
      debugPrint('创建Flutter VM服务临时目录: ${tmpDir.path}');
    }
  } catch (e) {
    debugPrint('创建Flutter VM服务临时目录失败: $e');
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late ThemeMode _themeMode;
  late udpReceive _udpReceiver;
  bool _lastUdpAvailable = false;

  @override
  void initState() {
    super.initState();
    final Brightness systemBrightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    _themeMode = systemBrightness == Brightness.dark
        ? ThemeMode.dark
        : ThemeMode.light;
    // 初始化 UDP 接收器
    _udpReceiver = udpReceive();
    // 添加回调函数示例
    _udpReceiver.addCallback((available) {
      if (available != _lastUdpAvailable) {
        _lastUdpAvailable = available;
        debugPrint('UDP 状态变化: $available');
        if (available) {
          debugPrint('收到有效 UDP 数据，num: ${_udpReceiver.num}');
        }
      }
    });
  }

  @override
  void dispose() {
    // 释放 UDP 接收器资源
    _udpReceiver.dispose();
    super.dispose();
  }

  void _toggleThemeMode() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark
          ? ThemeMode.light
          : ThemeMode.dark;
    });
  }

  bool get _isDarkMode => _themeMode == ThemeMode.dark;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Navigation Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: _themeMode,
      home: MainScreen(
        isDarkMode: _isDarkMode,
        onThemeToggle: _toggleThemeMode,
        udpReceiver: _udpReceiver,
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({
    super.key,
    required this.isDarkMode,
    required this.onThemeToggle,
    required this.udpReceiver,
  });

  final bool isDarkMode;
  final VoidCallback onThemeToggle;
  final udpReceive udpReceiver;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 2;

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = <Widget>[
      ManualPage(
        isDarkMode: widget.isDarkMode,
        onThemeToggle: widget.onThemeToggle,
      ),
      ChartPage(
        isDarkMode: widget.isDarkMode,
        onThemeToggle: widget.onThemeToggle,
        udpReceiver: widget.udpReceiver,
      ),
      const EnroutePage(),
      const ToolsPage(),
      const SettingPage(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: '手册'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: '航图'),
          BottomNavigationBarItem(icon: Icon(Icons.route), label: '航路'),
          BottomNavigationBarItem(icon: Icon(Icons.build), label: '工具'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: '设置'),
        ],
      ),
    );
  }
}
