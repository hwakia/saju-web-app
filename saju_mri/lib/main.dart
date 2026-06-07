import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_screen.dart';
import 'screens/consent_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();
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
      title: '사주키링',
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
