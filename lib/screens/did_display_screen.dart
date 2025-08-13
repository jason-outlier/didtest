import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'did_display_screen_model.dart';

/// DID 디스플레이 화면 - 주문 상태를 실시간으로 표시하는 메인 화면
class DIDDisplayScreen extends StatefulWidget {
  const DIDDisplayScreen({super.key});

  @override
  State<DIDDisplayScreen> createState() => _DIDDisplayScreenState();
}

class _DIDDisplayScreenState extends State<DIDDisplayScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  // ===== 모델 및 컨트롤러 =====
  late final DIDDisplayScreenModel _model;
  late final AnimationController _blinkController;
  late final Animation<double> _blinkAnimation;

  // ===== 생명주기 메서드 =====

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  @override
  void dispose() {
    _disposeResources();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ensureLandscapeOrientation();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _onAppResumed();
    }
  }

  // ===== 초기화 메서드들 =====

  /// 앱 초기화 - 웨이크락, 애니메이션, 모델 초기화
  void _initializeApp() {
    _enableWakelock();
    _addLifecycleObserver();
    _initializeModel();
    _initializeBlinkAnimation();
    _setupOrientationAndFullscreen();
  }

  /// 웨이크락 활성화 - 화면이 꺼지지 않도록 함
  void _enableWakelock() {
    WakelockPlus.enable();
  }

  /// 생명주기 옵저버 추가
  void _addLifecycleObserver() {
    WidgetsBinding.instance.addObserver(this);
  }

  /// 모델 초기화
  void _initializeModel() {
    _model = DIDDisplayScreenModel();
    _model.addListener(_onModelChanged);
  }

  /// 깜빡임 애니메이션 초기화
  void _initializeBlinkAnimation() {
    _blinkController = AnimationController(duration: const Duration(milliseconds: 1000), vsync: this);
    _blinkAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut));
  }

  /// 화면 방향 및 전체화면 설정
  void _setupOrientationAndFullscreen() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    });
  }

  /// 리소스 정리
  void _disposeResources() {
    _blinkController.dispose();
    _model.removeListener(_onModelChanged);
    _model.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }

  /// 앱이 재개될 때 호출되는 메서드
  void _onAppResumed() {
    _enableWakelock();
    _ensureLandscapeOrientation();
    _ensureFullscreenMode();
  }

  /// 가로 방향 유지
  void _ensureLandscapeOrientation() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
  }

  /// 전체화면 모드 유지
  void _ensureFullscreenMode() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  /// 모델 상태 변경 시 호출되는 콜백
  void _onModelChanged() {
    if (mounted) {
      setState(() {});
      // 깜빡임 애니메이션 시작 여부 확인
      if (_model.shouldStartBlinking) {
        startBlinkingAnimation();
      }
    }
  }

  // ===== 애니메이션 메서드들 =====

  /// 깜빡임 애니메이션 시작 (모델에서 호출됨)
  void startBlinkingAnimation() {
    _blinkController.reset();
    for (int i = 0; i < 5; i++) {
      Future.delayed(Duration(milliseconds: i * 1000), () {
        if (mounted) {
          _blinkController.forward().then((_) {
            if (mounted) {
              _blinkController.reverse();
            }
          });
        }
      });
    }
  }

  // ===== UI 빌드 메서드들 =====

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(color: Colors.white70),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 완료된 주문 목록
            Expanded(
              child: _buildOrderList(
                title: '준비 완료',
                orders: _model.completedOrders,
                scrollController: _model.completedScrollController,
                backgroundColor: Colors.green.shade50,
                borderColor: Colors.green.shade200,
                emptyMessage: '',
                showTimestamp: false,
              ),
            ),
            // 대기 중인 주문 목록
            Expanded(
              child: _buildOrderList(
                title: '준비 중',
                orders: _model.waitingOrders,
                scrollController: _model.waitingScrollController,
                backgroundColor: Colors.orange.shade50,
                borderColor: Colors.orange.shade200,
                emptyMessage: '',
                showTimestamp: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 주문 목록 위젯 빌드
  Widget _buildOrderList({
    required String title,
    required List<String> orders,
    required ScrollController scrollController,
    required Color backgroundColor,
    required Color borderColor,
    required String emptyMessage,
    required bool showTimestamp,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor),
      ),
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 제목
            _buildTitle(title),
            const SizedBox(height: 16),
            // 주문 목록
            Expanded(
              child: _buildOrderListContent(
                orders: orders,
                scrollController: scrollController,
                backgroundColor: backgroundColor,
                borderColor: borderColor,
                emptyMessage: emptyMessage,
                showTimestamp: showTimestamp,
                title: title,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 제목 위젯 빌드
  Widget _buildTitle(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w600, color: Colors.grey.shade800),
        ),
      ],
    );
  }

  /// 주문 목록 내용 위젯 빌드
  Widget _buildOrderListContent({
    required List<String> orders,
    required ScrollController scrollController,
    required Color backgroundColor,
    required Color borderColor,
    required String emptyMessage,
    required bool showTimestamp,
    required String title,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: orders.isEmpty
          ? _buildEmptyState(emptyMessage)
          : _buildOrdersGrid(orders: orders, scrollController: scrollController, backgroundColor: backgroundColor, borderColor: borderColor, title: title),
    );
  }

  /// 빈 상태 위젯 빌드
  Widget _buildEmptyState(String emptyMessage) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 12),
          Text(
            emptyMessage,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  /// 주문 그리드 위젯 빌드
  Widget _buildOrdersGrid({required List<String> orders, required ScrollController scrollController, required Color backgroundColor, required Color borderColor, required String title}) {
    return Column(
      children: [
        // 최근 호출 번호 (완료 목록에만 표시)
        if (title == '준비 완료') _buildLatestCalledNumber(),
        // 주문 그리드
        Expanded(
          child: GridView.builder(
            controller: scrollController,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, mainAxisExtent: 100),
            itemCount: orders.length,
            itemBuilder: (context, index) => _buildOrderItem(orderNo: orders[index], backgroundColor: backgroundColor, borderColor: borderColor),
          ),
        ),
      ],
    );
  }

  /// 개별 주문 아이템 위젯 빌드
  Widget _buildOrderItem({required String orderNo, required Color backgroundColor, required Color borderColor}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: backgroundColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            orderNo,
            style: TextStyle(fontSize: 50, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
          ),
        ],
      ),
    );
  }

  /// 최근 호출 번호 위젯 빌드
  Widget _buildLatestCalledNumber() {
    return AnimatedBuilder(
      animation: _blinkAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _blinkAnimation.value,
          child: Text(
            _model.latestCalledNumber ?? '',
            style: const TextStyle(fontSize: 100, fontWeight: FontWeight.bold, color: Colors.black),
          ),
        );
      },
    );
  }
}
