import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:didtest/screens/did_display_screen.dart';

/// 애플리케이션 진입점
/// Flutter 앱의 초기화 및 전역 설정을 담당
void main() {
  // Flutter 바인딩 초기화
  WidgetsFlutterBinding.ensureInitialized();

  // ===== 전역 앱 설정 =====

  // 웨이크락 활성화 - 화면이 꺼지지 않도록 함
  WakelockPlus.enable();

  // 가로 방향 강제 설정
  SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);

  // 전체화면 모드 설정
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // 앱 실행
  runApp(const MainApp());
}

/// 메인 애플리케이션 위젯
/// 앱의 테마, 라우팅, 전역 설정을 관리
class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // ===== 기본 설정 =====
      debugShowCheckedModeBanner: false,
      title: 'didtest',

      // ===== 테마 설정 =====
      theme: _buildAppTheme(),

      // ===== 홈 화면 =====
      home: const DIDDisplayScreen(),
    );
  }

  // ===== 테마 빌드 메서드들 =====

  /// 애플리케이션 테마 빌드
  /// Toss 앱 스타일을 참고한 모던하고 깔끔한 디자인
  ThemeData _buildAppTheme() {
    return ThemeData(
      // ===== 기본 색상 =====
      primarySwatch: Colors.blue,
      scaffoldBackgroundColor: const Color(0xFFF8F9FA),

      // ===== 폰트 설정 =====
      fontFamily: 'SF Pro Display',

      // ===== 버튼 테마 =====
      elevatedButtonTheme: _buildElevatedButtonTheme(),

      // ===== 입력 필드 테마 =====
      inputDecorationTheme: _buildInputDecorationTheme(),

      // ===== 카드 테마 =====
      cardTheme: _buildCardTheme(),

      // ===== 앱바 테마 =====
      appBarTheme: _buildAppBarTheme(),
    );
  }

  /// Elevated 버튼 테마 빌드
  ElevatedButtonThemeData _buildElevatedButtonTheme() {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
    );
  }

  /// 입력 필드 테마 빌드
  InputDecorationTheme _buildInputDecorationTheme() {
    return InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF007AFF), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade300),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade500, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  /// 카드 테마 빌드
  CardThemeData _buildCardTheme() {
    return CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      color: Colors.white,
      margin: const EdgeInsets.all(8),
    );
  }

  /// 앱바 테마 빌드
  AppBarTheme _buildAppBarTheme() {
    return AppBarTheme(
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: Colors.grey.shade800,
      centerTitle: true,
      titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.grey.shade800),
    );
  }
}
