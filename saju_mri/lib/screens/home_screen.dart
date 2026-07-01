import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late final WebViewController _webViewController;
  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;
  bool _isLoading = true;
  bool _hasError = false;
  bool _personalizedAds = false; // 광고 개인화 동의(기본=비맞춤형)

  // ─── 전면광고 ───────────────────────────────────────────────
  InterstitialAd? _interstitialAd;
  bool _isInterstitialReady = false;
  int _pageLoadCount = 0;         // 페이지 로드 횟수 카운터
  static const int _adEveryN = 10; // N번 페이지 로드마다 전면광고 노출 (5→10, 광고 피로 완화)

  // ─── 광고 ID (프로덕션 AdMob 광고 단위) ───
  static const String _bannerAdUnitId =
      'ca-app-pub-9539448818887468/9345493232'; // 배너 광고
  static const String _interstitialAdUnitId =
      'ca-app-pub-9539448818887468/8611299982'; // 전면광고

  // app_ok=1: Flutter 앱에서 이미 동의한 경우 Streamlit 동의 게이트 우회
  static const String _sajuUrl =
      'https://saju-web-app-hwaki.streamlit.app/?app_ok=1';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initWebView();
    _maybeInitNotifications();
    // 동의 후 진입하는 HomeScreen에서만 광고 SDK 초기화·로드 (동의 전 전송 방지)
    MobileAds.instance.initialize().then((_) async {
      if (!mounted) return;
      final prefs = await SharedPreferences.getInstance();
      _personalizedAds = prefs.getBool('admob_consent_v1') ?? false;
      if (!mounted) return;
      _loadBannerAd();
      _loadInterstitialAd();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 다른 앱에 다녀오거나 오래 방치한 뒤 복귀하면 끊긴 연결을 자동 복구한다.
    if (state == AppLifecycleState.resumed && _hasError) {
      _reload();
    }
  }

  void _initWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            // Streamlit URL에서 app_ok=1 이 사라지면 다시 붙여준다
            final uri = Uri.tryParse(request.url);
            if (uri != null &&
                uri.host.contains('streamlit.app') &&
                uri.queryParameters['app_ok'] != '1') {
              final fixed = uri.replace(
                queryParameters: {
                  ...uri.queryParameters,
                  'app_ok': '1',
                },
              );
              _webViewController.loadRequest(fixed);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onPageStarted: (_) {
            setState(() {
              _isLoading = true;
              _hasError = false;
            });
          },
          onPageFinished: (_) {
            setState(() => _isLoading = false);
            _pageLoadCount++;
            // N번째 페이지 로드마다 전면광고 표시 (첫 로드 제외)
            if (_pageLoadCount > 1 &&
                _pageLoadCount % _adEveryN == 0 &&
                _isInterstitialReady) {
              _showInterstitialAd();
            }
            _syncDailyNotifications();
          },
          onWebResourceError: (error) {
            // 광고·이미지 등 부속 리소스 오류로는 오류 화면을 띄우지 않는다.
            // 메인 페이지 로드 실패일 때만 오류 화면 표시.
            if (error.isForMainFrame ?? true) {
              setState(() {
                _isLoading = false;
                _hasError = true;
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(_sajuUrl));
  }

  // ── 오늘의 처방 로컬 알림 ─────────────────────────────────
  // 동의(notif_consent_v1) 시 Android 13+ 알림 권한을 요청한다.
  Future<void> _maybeInitNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('notif_consent_v1') ?? true) {
        await NotificationService.requestPermission();
      }
    } catch (_) {}
  }

  // 페이지 로드 시 웹앱이 localStorage에 넣어둔 7일치 티저를 읽어 알림 예약.
  Future<void> _syncDailyNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!(prefs.getBool('notif_consent_v1') ?? true)) return;
      final raw = await _webViewController.runJavaScriptReturningResult(
        "localStorage.getItem('sai_push_teasers_v1')",
      );
      String js = raw.toString();
      if (js.isEmpty || js == 'null') return;
      // Android는 결과를 JSON 인코딩 문자열로 감싸 반환할 수 있어 한 겹 해제
      if (js.startsWith('"') && js.endsWith('"')) {
        try {
          final unq = jsonDecode(js);
          if (unq is String) js = unq;
        } catch (_) {}
      }
      if (js == 'null' || js.isEmpty) return;
      await NotificationService.scheduleFromJson(js);
    } catch (_) {}
  }

  // 광고 개인화 미동의 시 비맞춤형 광고로 요청
  AdRequest _buildAdRequest() => AdRequest(nonPersonalizedAds: !_personalizedAds);

  // ─── 전면광고 로드 ───────────────────────────────────────────
  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: _buildAdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialReady = true;
          _interstitialAd!.fullScreenContentCallback =
              FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitialAd = null;
              _isInterstitialReady = false;
              _loadInterstitialAd(); // 다음 광고 미리 로드
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _interstitialAd = null;
              _isInterstitialReady = false;
              _loadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _isInterstitialReady = false;
        },
      ),
    );
  }

  void _showInterstitialAd() {
    if (_isInterstitialReady && _interstitialAd != null) {
      _interstitialAd!.show();
      _isInterstitialReady = false;
    }
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: _bannerAdUnitId,
      size: AdSize.banner,
      request: _buildAdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() => _isBannerLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          setState(() => _isBannerLoaded = false);
        },
      ),
    )..load();
  }

  Future<bool> _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  void _reload() async {
    final connected = await _checkConnectivity();
    if (!connected) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('인터넷 연결을 확인해주세요.'),
            backgroundColor: Color(0xFF2F1C36),
          ),
        );
      }
      return;
    }
    setState(() {
      _hasError = false;
      _isLoading = true;
    });
    _webViewController.reload();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final canGoBack = await _webViewController.canGoBack();
        if (canGoBack) {
          await _webViewController.goBack();
        } else {
          // 루트 도달 시 종료 확인만 표시
          // (뒤로가기 종료 시 전면광고는 AdMob 방해 광고 정책 위반 소지가 있어 제거)
          if (mounted) {
            _showExitDialog();
          }
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              // WebView 영역
              Expanded(
                child: Stack(
                  children: [
                    // 오류 화면
                    if (_hasError)
                      _buildErrorScreen()
                    else
                      WebViewWidget(controller: _webViewController),

                    // 로딩 인디케이터
                    if (_isLoading && !_hasError)
                      const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              color: Color(0xFFE8C87A),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Sai 불러오는 중...',
                              style: TextStyle(
                                color: Color(0xFFCDB98F),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // 하단 배너 광고
              if (_isBannerLoaded && _bannerAd != null)
                SizedBox(
                  height: _bannerAd!.size.height.toDouble(),
                  width: double.infinity,
                  child: AdWidget(ad: _bannerAd!),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Container(
      color: const Color(0xFF1A0D1F),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 64,
              color: Color(0xFF7A6A55),
            ),
            const SizedBox(height: 20),
            const Text(
              '연결할 수 없습니다',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFF3E6C8),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '인터넷 연결을 확인하고 다시 시도해주세요.',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFFBFA884),
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: _reload,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('다시 시도'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE8C87A),
                foregroundColor: const Color(0xFF3A2405),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('앱 종료'),
        content: const Text('Sai를 종료하시겠습니까?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _webViewController.loadRequest(Uri.parse(_sajuUrl));
            },
            child: const Text('처음 화면으로'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              SystemNavigator.pop();
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFE8C87A),
            ),
            child: const Text('종료'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    super.dispose();
  }
}
