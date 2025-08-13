import 'dart:io';
import 'package:flutter/material.dart';

/// DID 디스플레이 화면의 비즈니스 로직을 담당하는 모델 클래스
/// MVVM 패턴의 ViewModel 역할을 수행
class DIDDisplayScreenModel extends ChangeNotifier {
  // ===== 컨트롤러 및 상태 변수 =====
  final TextEditingController _portController = TextEditingController(text: '4040');
  final ScrollController _waitingScrollController = ScrollController();
  final ScrollController _completedScrollController = ScrollController();

  // 서버 소켓
  ServerSocket? _server;

  // 주문 관리 데이터
  final List<String> _waitingOrders = [];
  final List<String> _completedOrders = [];
  final Map<String, DateTime> _orderTimestamps = {};
  String? _latestCalledNumber;

  // ===== Getter 메서드들 =====

  /// 대기 중인 주문 목록
  List<String> get waitingOrders => List.unmodifiable(_waitingOrders);

  /// 완료된 주문 목록
  List<String> get completedOrders => List.unmodifiable(_completedOrders);

  /// 주문 타임스탬프 맵
  Map<String, DateTime> get orderTimestamps => Map.unmodifiable(_orderTimestamps);

  /// 최근 호출된 주문 번호
  String? get latestCalledNumber => _latestCalledNumber;

  /// 대기 중인 주문 수
  int get waitingOrdersCount => _waitingOrders.length;

  /// 완료된 주문 수
  int get completedOrdersCount => _completedOrders.length;

  /// 스크롤 컨트롤러들
  ScrollController get waitingScrollController => _waitingScrollController;
  ScrollController get completedScrollController => _completedScrollController;

  /// 포트 컨트롤러
  TextEditingController get portController => _portController;

  // ===== 초기화 메서드들 =====

  /// 모델 초기화
  DIDDisplayScreenModel() {
    _startServer();
  }

  // ===== 서버 관리 메서드들 =====

  /// 서버 시작
  Future<void> _startServer() async {
    try {
      final port = int.parse(_portController.text.trim());
      _server = await ServerSocket.bind(InternetAddress.anyIPv4, port);
      _server!.listen(_handleClient);
    } catch (e) {
      // 서버 시작 실패 시 에러 처리
      debugPrint('서버 시작 실패: $e');
    }
  }

  /// 서버 중지
  Future<void> _stopServer() async {
    if (_server != null) {
      await _server!.close();
      _server = null;
    }
  }

  /// 클라이언트 연결 처리
  void _handleClient(Socket client) {
    client.listen((data) => _processClientMessage(client, data), onDone: () => client.close(), onError: (error) => client.close());
  }

  /// 클라이언트 메시지 처리
  void _processClientMessage(Socket client, List<int> data) {
    final message = String.fromCharCodes(data).trim();
    if (message.isNotEmpty) {
      _processOrderMessage(message);
      client.write('주문 처리됨: $message\n');
    }
  }

  // ===== 주문 메시지 처리 메서드들 =====

  /// 주문 메시지 파싱 및 처리
  /// 형식: "*1W0000*" (대기), "*1A0000*" (완료), "*1D0000*" (삭제), "*1C0000*" (전체 삭제)
  void _processOrderMessage(String message) {
    final cleanMessage = _removeDelimiters(message);

    if (_isValidOrderMessage(cleanMessage)) {
      final action = cleanMessage[1];
      final orderNo = cleanMessage.substring(2);
      _executeOrderAction(action, orderNo);
    }
  }

  /// 메시지에서 구분자 제거
  String _removeDelimiters(String message) {
    if (message.startsWith('*') && message.endsWith('*')) {
      return message.substring(1, message.length - 1);
    }
    return message;
  }

  /// 유효한 주문 메시지인지 확인
  bool _isValidOrderMessage(String message) {
    return message.length == 6 && message.startsWith('1');
  }

  /// 주문 액션 실행
  void _executeOrderAction(String action, String orderNo) {
    switch (action) {
      case 'W': // 대기
        if (orderNo.isNotEmpty) _addToWaitList(orderNo);
        break;
      case 'A': // 완료
        if (orderNo.isNotEmpty) _addToCompleteList(orderNo);
        break;
      case 'D': // 삭제
        if (orderNo.isNotEmpty) _deleteOrder(orderNo);
        break;
      case 'C': // 전체 삭제
        _clearAllOrders();
        break;
    }
  }

  // ===== 주문 관리 메서드들 =====

  /// 대기 목록에 주문 추가
  void _addToWaitList(String orderNo) {
    _removeFromCompletedList(orderNo);
    _addToWaitingListIfNotExists(orderNo);
  }

  /// 완료 목록에서 주문 제거
  void _removeFromCompletedList(String orderNo) {
    if (_completedOrders.contains(orderNo)) {
      _completedOrders.remove(orderNo);
      _clearLatestCalledNumberIfNeeded(orderNo);
      notifyListeners();
    }
  }

  /// 최근 호출 번호가 해당 주문이면 제거
  void _clearLatestCalledNumberIfNeeded(String orderNo) {
    if (_latestCalledNumber == orderNo) {
      _latestCalledNumber = null;
    }
  }

  /// 대기 목록에 주문 추가 (중복 체크)
  void _addToWaitingListIfNotExists(String orderNo) {
    if (!_waitingOrders.contains(orderNo)) {
      _waitingOrders.add(orderNo);
      _orderTimestamps[orderNo] = DateTime.now();
      notifyListeners();
    }
  }

  /// 완료 목록에 주문 추가
  void _addToCompleteList(String orderNo) {
    _removeFromWaitingList(orderNo);
    _addToCompletedListIfNotExists(orderNo);
    _validateLatestCalledNumber();
  }

  /// 대기 목록에서 주문 제거
  void _removeFromWaitingList(String orderNo) {
    if (_waitingOrders.contains(orderNo)) {
      _waitingOrders.remove(orderNo);
      _orderTimestamps.remove(orderNo);
      notifyListeners();
    }
  }

  /// 완료 목록에 주문 추가 (중복 체크)
  void _addToCompletedListIfNotExists(String orderNo) {
    if (!_completedOrders.contains(orderNo)) {
      _completedOrders.add(orderNo);
      _latestCalledNumber = orderNo;
      // 깜빡임 애니메이션 트리거를 위한 플래그 설정
      notifyListeners();
    }
  }

  /// 주문 삭제
  void _deleteOrder(String orderNo) {
    _removeFromWaitingList(orderNo);
    _removeFromCompletedList(orderNo);
  }

  /// 모든 주문 삭제
  void _clearAllOrders() {
    _waitingOrders.clear();
    _completedOrders.clear();
    _orderTimestamps.clear();
    _latestCalledNumber = null;
    notifyListeners();
  }

  /// 최근 호출 번호 유효성 검증
  void _validateLatestCalledNumber() {
    if (_latestCalledNumber != null && !_completedOrders.contains(_latestCalledNumber)) {
      _latestCalledNumber = null;
      notifyListeners();
    }
  }

  // ===== 공개 API 메서드들 =====

  /// 수동으로 주문을 대기 목록에 추가 (테스트용)
  void addOrderToWaitList(String orderNo) {
    _addToWaitList(orderNo);
  }

  /// 수동으로 주문을 완료 목록에 추가 (테스트용)
  void addOrderToCompleteList(String orderNo) {
    _addToCompleteList(orderNo);
  }

  /// 수동으로 주문 삭제 (테스트용)
  void removeOrder(String orderNo) {
    _deleteOrder(orderNo);
  }

  /// 모든 주문 수동 삭제 (테스트용)
  void clearAllOrders() {
    _clearAllOrders();
  }

  /// 특정 주문이 대기 목록에 있는지 확인
  bool isOrderInWaitList(String orderNo) {
    return _waitingOrders.contains(orderNo);
  }

  /// 특정 주문이 완료 목록에 있는지 확인
  bool isOrderInCompleteList(String orderNo) {
    return _completedOrders.contains(orderNo);
  }

  /// 주문의 타임스탬프 가져오기
  DateTime? getOrderTimestamp(String orderNo) {
    return _orderTimestamps[orderNo];
  }

  /// 최근에 완료된 주문이 있는지 확인 (애니메이션 트리거용)
  bool get shouldStartBlinking {
    return _latestCalledNumber != null && _completedOrders.contains(_latestCalledNumber);
  }

  // ===== 리소스 정리 =====

  @override
  void dispose() {
    _portController.dispose();
    _waitingScrollController.dispose();
    _completedScrollController.dispose();
    _stopServer();
    super.dispose();
  }
}
