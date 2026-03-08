import 'dart:io';
import 'dart:async';
import 'plane.pb.dart';

class udpReceive {
  late RawDatagramSocket _socket;
  List<Function(bool)> _callbacks = [];
  bool _udpAvailable = false;
  int _num = 0;
  Timer? _timeoutTimer;
  List<Plane> planes = List.generate(64, (index) => Plane());
  static const String _multicastAddress = '239.255.73.16';
  static const int _port = 57316;
  static const List<int> _validPrefix = [0x40, 0x79, 0x54, 0x20];
  static const Duration _timeoutDuration = Duration(seconds: 3);

  udpReceive() {
    _initSocket();
  }

  void _initSocket() async {
    try {
      _socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        _port,
        reuseAddress: true,
        reusePort: true,
      );
      _socket.joinMulticast(InternetAddress(_multicastAddress));
      _socket.listen(_handleDatagram);
      _resetTimeout();
    } catch (e) {
      print('Error initializing UDP socket: e');
    }
  }

  void _handleDatagram(RawSocketEvent event) {
    if (event == RawSocketEvent.read) {
      Datagram? datagram = _socket.receive();
      if (datagram != null && datagram.data.length >= 5) {
        bool isValid = true;
        for (int i = 0; i < _validPrefix.length; i++) {
          if (datagram.data[i] != _validPrefix[i]) {
            isValid = false;
            break;
          }
        }

        if (isValid) {
          _udpAvailable = true;
          _num = datagram.data[4];
          
          // Parse data[5:] as Planes
          if (datagram.data.length > 5) {
            try {
              List<int> planeData = datagram.data.sublist(5);
              Planes planesData = Planes.fromBuffer(planeData);
              
              // Update planes list based on id
              for (Plane plane in planesData.planes) {
                if (plane.id >= 0 && plane.id < 64) {
                  // Convert altitude to feet.
                  plane.alt = (plane.alt * 3.28).round();
                  planes[plane.id] = plane;
                }
              }
            } catch (e) {
              print('Error parsing plane data: e');
            }
          }
          
          _notifyCallbacks();
          _resetTimeout();
        }
      }
    }
  }

  void _resetTimeout() {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(_timeoutDuration, () {
      if (_udpAvailable) {
        _udpAvailable = false;
        _notifyCallbacks();
      }
    });
  }

  void _notifyCallbacks() {
    for (var callback in _callbacks) {
      callback(_udpAvailable);
    }
  }

  void addCallback(Function(bool) callback) {
    _callbacks.add(callback);
  }

  void removeCallback(Function(bool) callback) {
    _callbacks.remove(callback);
  }

  bool get udpAvailable => _udpAvailable;

  int get num => _num;

  void dispose() {
    _timeoutTimer?.cancel();
    _socket.close();
  }
}
