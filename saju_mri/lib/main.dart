import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_screen.dart';
import 'screens/consent_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 광고 SDK(AdMob)는 동의 전에 초기화하지 않는다. 동의 후 진입하는 HomeScreen에서 초기화한다.
  // 스플래시 화면 없이 동의 여부에 따라 바로 분기
  final prefs = await SharedPreferences.getInstance();
  final consented = prefs.getBool('privacy_consent_v1') ?? false;
  runApp(SajuMajjangApp(consented: consented));
}

class SajuMajjangApp extends StatelessWidget {
  final bool consented;
  const SajuMajjangApp({super.key, required this.consented});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sai',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3B5BDB),
        ),
        useMaterial3: true,
      ),
      home: consented ? const HomeScreen() : const ConsentScreen(),
    );
  }
}
