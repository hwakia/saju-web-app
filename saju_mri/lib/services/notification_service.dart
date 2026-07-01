import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;

/// 오늘의 처방 로컬 알림 서비스.
/// 웹앱이 localStorage('sai_push_teasers_v1')에 저장한 며칠치 티저를 읽어
/// 각 날짜의 지정 시각에 로컬 알림으로 예약한다. (서버 없음, 기기 안에서만 처리)
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _inited = false;

  static Future<void> init() async {
    if (_inited) return;
    tzdata.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Seoul'));
    } catch (_) {}
    const androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _plugin.initialize(initSettings);
    _inited = true;
  }

  /// Android 13+ 알림 권한 요청. (동의 기반)
  static Future<bool> requestPermission() async {
    await init();
    final android =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    final granted = await android?.requestNotificationsPermission();
    return granted ?? true;
  }

  /// localStorage에서 읽은 JSON 문자열로 알림을 예약한다.
  static Future<void> scheduleFromJson(String? jsonStr) async {
    if (jsonStr == null) return;
    var s = jsonStr.trim();
    if (s.isEmpty || s == 'null' || s == '"null"') return;
    await init();

    // 최신 티저로 갱신: 기존 예약 전부 취소 후 재등록
    await _plugin.cancelAll();

    Map<String, dynamic> data;
    try {
      final decoded = jsonDecode(s);
      data = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    } catch (_) {
      return;
    }
    final items = (data['items'] as List?) ?? const [];
    if (items.isEmpty) return;

    const androidDetails = AndroidNotificationDetails(
      'sai_daily',
      '오늘의 처방',
      channelDescription: '매일 오늘의 핵심 처방 알림',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const details = NotificationDetails(android: androidDetails);

    final now = tz.TZDateTime.now(tz.local);
    int id = 2000;
    for (final it in items) {
      if (it is! Map) continue;
      final dateStr = it['date']?.toString();
      final hour = (it['hour'] is int) ? it['hour'] as int : 8;
      final title = it['title']?.toString() ?? '🌤 오늘의 처방';
      final body = it['body']?.toString() ?? '';
      if (dateStr == null) continue;
      final p = dateStr.split('-');
      if (p.length != 3) continue;
      final y = int.tryParse(p[0]);
      final mo = int.tryParse(p[1]);
      final d = int.tryParse(p[2]);
      if (y == null || mo == null || d == null) continue;
      final when = tz.TZDateTime(tz.local, y, mo, d, hour);
      if (!when.isAfter(now)) continue; // 지난 시각은 건너뜀
      try {
        await _plugin.zonedSchedule(
          id++,
          title,
          body,
          when,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (_) {}
    }
  }
}
