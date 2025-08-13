import 'dart:ui';

import 'package:didtest/style/c_color.dart';
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

  // double getR(double radius) => getW(radius);
  double getW(double width) => MediaQuery.of(context).size.width * (width / 1920);
  double getH(double height) => MediaQuery.of(context).size.height * (height / 1080);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(color: CColor.bk7.color),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRect(
              child: SizedBox(
                width: getW(550),
                child: Stack(
                  alignment: Alignment.center,
                  fit: StackFit.expand,
                  children: [
                    Positioned.fill(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset("assets/images/example.jpg", fit: BoxFit.cover),
                          BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
                            child: Container(color: CColor.bk1.color.withOpacity(0.6)),
                          ),
                        ],
                      ),
                    ),

                    Positioned.fill(
                      child: Container(
                        // color: CColor.bk5.color,
                        padding: EdgeInsets.symmetric(horizontal: getW(20), vertical: getH(20)),
                        width: getW(550),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLatestCalledNumber(),
                            SizedBox(height: getH(20)),
                            _buildBanner(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: getW(50), vertical: getH(50)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildOrderTitle(title: "주문하신 메뉴가 나왔습니다.", subTitle: "your menu is ready."),
                    SizedBox(height: getH(30)),
                    _buildOrdersGrid(orders: _model.completedOrders.reversed.toList(), scrollController: _model.completedScrollController, length: 8),
                    SizedBox(height: getH(5)),
                    _buildOrderTitle(title: "메뉴 준비중 ...", subTitle: "Your menu is being created."),
                    SizedBox(height: getH(30)),
                    _buildOrdersGrid(orders: _model.waitingOrders.reversed.toList(), scrollController: _model.waitingScrollController, length: 12),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 배너
  Widget _buildBanner() {
    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(getW(15)),
        child: Container(
          decoration: BoxDecoration(
            color: CColor.brand2.color,
            borderRadius: BorderRadius.circular(getW(15)),
            // backgroundBlendMode: BlendMode.colorBurn,
            // border: Border.all(color: CColor.brand2.color, style: BorderStyle.solid, width: 1),
          ),
          child: Column(
            children: [
              Container(
                height: getH(160),
                decoration: BoxDecoration(
                  color: CColor.brand3.color,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(getW(15)), topRight: Radius.circular(getW(15))),
                  // border: Border.all(color: CColor.brand2.color, style: BorderStyle.solid, width: 1),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      "무더위 특별 이벤트",
                      style: TextStyle(fontSize: getW(35), fontWeight: FontWeight.w700, color: CColor.bk8.color),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      "세트 상품을 주문하면 빙수가 공짜 !",
                      style: TextStyle(fontSize: getW(28), fontWeight: FontWeight.w400, color: CColor.bk3.color),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              Expanded(child: Image.asset("assets/images/example.jpg", fit: BoxFit.cover)),
            ],
          ),
        ),
      ),
    );
  }

  /// 최근 호출 번호
  Widget _buildLatestCalledNumber() {
    return Container(
      decoration: BoxDecoration(
        color: CColor.brand2.color,
        borderRadius: BorderRadius.circular(getW(15)),
        border: Border.all(color: CColor.brand2.color, style: BorderStyle.solid, width: 1),
      ),
      padding: EdgeInsets.symmetric(horizontal: getW(20), vertical: getH(20)),
      height: getH(140),
      child: Center(
        child: AnimatedBuilder(
          animation: _blinkAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: _blinkAnimation.value,
              child: Text(
                _model.latestCalledNumber ?? '',
                style: TextStyle(fontSize: getW(80), fontWeight: FontWeight.w500, color: CColor.rev1.color),
              ),
            );
          },
        ),
      ),
    );
  }

  /// 주문 타이틀 영역
  Widget _buildOrderTitle({required String title, required String subTitle}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: getW(40), fontWeight: FontWeight.w700, color: CColor.bk1.color),
        ),
        Text(
          subTitle,
          style: TextStyle(fontSize: getW(28), fontWeight: FontWeight.w400, color: CColor.bk3.color),
        ),
      ],
    );
  }

  /// 주문 그리드 위젯 빌드
  Widget _buildOrdersGrid({required List<String> orders, required ScrollController scrollController, int crossAxisCount = 4, int length = 8}) {
    Color backgroundColor = (length == 8) ? CColor.brand2.color : CColor.bk8.color;
    Color borderColor = (length == 8) ? CColor.brand2.color : CColor.bk5.color;
    Color labelColor = (length == 8) ? CColor.rev1.color : CColor.brand1.color;
    double gridHeight = getH(125.2 * (length / crossAxisCount) + 20 * (length / crossAxisCount));

    return SizedBox(
      height: gridHeight,
      child: GridView.builder(
        controller: scrollController,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: crossAxisCount, mainAxisSpacing: getW(20), crossAxisSpacing: getH(20), mainAxisExtent: getH(125.2)),
        itemCount: length,
        itemBuilder: (context, index) {
          String? orderNo = (index < orders.length) ? orders[index] : null;
          return _buildOrderItem(orderNo: orderNo, backgroundColor: backgroundColor, borderColor: borderColor, labelColor: labelColor);
        },
      ),
    );
  }

  /// 개별 주문 아이템 위젯 빌드
  Widget _buildOrderItem({required String? orderNo, required Color backgroundColor, required Color borderColor, required Color labelColor}) {
    bool hasOrderNo = orderNo != null && orderNo.isNotEmpty;
    return Container(
      decoration: BoxDecoration(
        color: hasOrderNo ? backgroundColor : CColor.bk7.color,
        borderRadius: BorderRadius.circular(getW(15)),
        border: Border.all(color: hasOrderNo ? borderColor : CColor.bk5.color, style: BorderStyle.solid, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            orderNo ?? '',
            style: TextStyle(fontSize: getW(50), fontWeight: FontWeight.w500, color: labelColor),
          ),
        ],
      ),
    );
  }
}
