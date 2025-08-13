import 'dart:io';
import 'dart:convert';
import 'dart:async';

/// 소켓 서버 서비스 클래스
/// 클라이언트 연결을 관리하고 메시지를 브로드캐스트하는 기능을 제공
class SocketServer {
  // ===== 서버 상태 변수 =====
  ServerSocket? _server;
  final List<Socket> _clients = [];

  // ===== 스트림 컨트롤러들 =====
  final StreamController<String> _messagesController = StreamController<String>.broadcast();
  final StreamController<String> _statusController = StreamController<String>.broadcast();

  // ===== Getter 메서드들 =====

  /// 서버가 실행 중인지 확인
  bool get isRunning => _server != null;

  /// 메시지 스트림
  Stream<String> get messages => _messagesController.stream;

  /// 상태 스트림
  Stream<String> get status => _statusController.stream;

  /// 연결된 클라이언트 수
  int get clientCount => _clients.length;

  // ===== 서버 관리 메서드들 =====

  /// 서버 시작
  /// [port] - 서버가 리스닝할 포트 번호 (기본값: 8080)
  /// 반환값: 서버 정보 문자열
  Future<String> start({int port = 8080}) async {
    try {
      if (_server != null) {
        throw Exception('서버가 이미 실행 중입니다');
      }

      // 서버 시작
      _server = await ServerSocket.bind(InternetAddress.anyIPv4, port);
      _statusController.add('서버가 포트 $port에서 시작되었습니다');

      // 클라이언트 연결 리스닝
      _server!.listen((Socket client) {
        _handleClient(client);
      });

      // 로컬 IP 주소 가져오기
      final localIP = await _getLocalIPAddress();
      final serverInfo = '서버가 $localIP:$port에서 실행 중입니다';
      _statusController.add(serverInfo);

      return serverInfo;
    } catch (e) {
      final errorMessage = '서버 시작 실패: $e';
      _statusController.add(errorMessage);
      throw Exception(errorMessage);
    }
  }

  /// 서버 중지
  /// 모든 클라이언트 연결을 종료하고 서버를 정리
  Future<void> stop() async {
    try {
      // 모든 클라이언트 연결 종료
      for (final client in _clients) {
        await client.close();
      }
      _clients.clear();

      // 서버 종료
      await _server?.close();
      _server = null;

      _statusController.add('서버가 중지되었습니다');
    } catch (e) {
      _statusController.add('서버 중지 중 오류 발생: $e');
    }
  }

  // ===== 클라이언트 관리 메서드들 =====

  /// 클라이언트 연결 처리
  /// [client] - 연결된 클라이언트 소켓
  void _handleClient(Socket client) {
    final clientAddress = '${client.remoteAddress.address}:${client.remotePort}';
    _clients.add(client);
    _statusController.add('클라이언트 연결됨: $clientAddress');

    // 클라이언트로부터 메시지 수신
    client.listen(
      (data) {
        final message = utf8.decode(data).trim();
        _messagesController.add('[$clientAddress]: $message');

        // 모든 클라이언트에게 메시지 브로드캐스트
        broadcastMessage('Echo: $message');
      },
      onDone: () {
        _clients.remove(client);
        _statusController.add('클라이언트 연결 해제됨: $clientAddress');
      },
      onError: (error) {
        _clients.remove(client);
        _statusController.add('클라이언트 오류: $clientAddress - $error');
      },
    );

    // 환영 메시지 전송
    _sendWelcomeMessage(client);
  }

  /// 환영 메시지 전송
  /// [client] - 메시지를 받을 클라이언트
  void _sendWelcomeMessage(Socket client) {
    try {
      final welcomeMessage = '소켓 서버에 오신 것을 환영합니다!\n';
      client.add(utf8.encode(welcomeMessage));
    } catch (e) {
      _statusController.add('환영 메시지 전송 실패: $e');
    }
  }

  // ===== 메시지 브로드캐스트 메서드들 =====

  /// 모든 클라이언트에게 메시지 브로드캐스트
  /// [message] - 브로드캐스트할 메시지
  void broadcastMessage(String message) {
    final data = utf8.encode('$message\n');
    final failedClients = <Socket>[];

    for (final client in _clients) {
      try {
        client.add(data);
      } catch (e) {
        failedClients.add(client);
        _statusController.add('클라이언트에게 메시지 전송 실패: $e');
      }
    }

    // 실패한 클라이언트들 제거
    _removeFailedClients(failedClients);
  }

  /// 실패한 클라이언트들 제거
  /// [failedClients] - 제거할 클라이언트 목록
  void _removeFailedClients(List<Socket> failedClients) {
    for (final client in failedClients) {
      _clients.remove(client);
      try {
        client.close();
      } catch (e) {
        // 클라이언트 종료 실패는 무시
      }
    }
  }

  // ===== 네트워크 유틸리티 메서드들 =====

  /// 로컬 IP 주소 가져오기
  /// WiFi 인터페이스를 우선적으로 찾아 IPv4 주소를 반환
  Future<String> _getLocalIPAddress() async {
    try {
      final interfaces = await NetworkInterface.list();

      // WiFi 인터페이스 우선 검색
      final wifiIP = _findWifiInterfaceIP(interfaces);
      if (wifiIP != null) {
        return wifiIP;
      }

      // 일반 IPv4 주소로 폴백
      final fallbackIP = _findFallbackIP(interfaces);
      if (fallbackIP != null) {
        return fallbackIP;
      }

      return 'localhost';
    } catch (e) {
      return 'localhost';
    }
  }

  /// WiFi 인터페이스에서 IP 주소 찾기
  /// [interfaces] - 네트워크 인터페이스 목록
  String? _findWifiInterfaceIP(List<NetworkInterface> interfaces) {
    for (final interface in interfaces) {
      final name = interface.name.toLowerCase();
      if (name.contains('wlan') || name.contains('wifi') || name.contains('wi-fi')) {
        for (final addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            return addr.address;
          }
        }
      }
    }
    return null;
  }

  /// 폴백 IP 주소 찾기
  /// [interfaces] - 네트워크 인터페이스 목록
  String? _findFallbackIP(List<NetworkInterface> interfaces) {
    for (final interface in interfaces) {
      for (final addr in interface.addresses) {
        if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
          return addr.address;
        }
      }
    }
    return null;
  }

  // ===== 공개 API 메서드들 =====

  /// 특정 클라이언트에게 메시지 전송
  /// [clientIndex] - 클라이언트 인덱스
  /// [message] - 전송할 메시지
  void sendToClient(int clientIndex, String message) {
    if (clientIndex >= 0 && clientIndex < _clients.length) {
      try {
        final client = _clients[clientIndex];
        final data = utf8.encode('$message\n');
        client.add(data);
      } catch (e) {
        _statusController.add('클라이언트 $clientIndex에게 메시지 전송 실패: $e');
      }
    }
  }

  /// 모든 클라이언트 연결 강제 종료
  Future<void> disconnectAllClients() async {
    for (final client in _clients) {
      try {
        await client.close();
      } catch (e) {
        // 클라이언트 종료 실패는 무시
      }
    }
    _clients.clear();
    _statusController.add('모든 클라이언트 연결이 강제 종료되었습니다');
  }

  /// 서버 상태 정보 가져오기
  Map<String, dynamic> getServerStatus() {
    return {'isRunning': isRunning, 'clientCount': clientCount, 'port': _server?.port, 'address': _server?.address.address};
  }

  // ===== 리소스 정리 =====

  /// 리소스 정리
  /// 서버를 중지하고 모든 스트림 컨트롤러를 닫음
  void dispose() {
    stop();
    _messagesController.close();
    _statusController.close();
  }
}
