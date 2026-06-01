import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();
  runApp(const SajuMajjangApp());
}

class SajuMajjangApp extends StatelessWidget {
  const SajuMajjangApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '사주맞짱',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3B5BDB),
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
