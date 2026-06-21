import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';

class ConsentScreen extends StatefulWidget {
  const ConsentScreen({super.key});

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  bool _age14 = false;

  Future<void> _acceptAndProceed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('privacy_consent_v1', true);
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
              // 헤더
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B5BDB),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.self_improvement,
                        size: 44,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Sai',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '서비스 이용 전 개인정보 처리방침을 확인해 주세요',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFFAAAAAA),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // 개인정보 처리 핵심 안내
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF12122A),
                  border: Border.all(color: const Color(0xFF3B5BDB), width: 1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📋 개인정보 수집·이용 안내',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF93B4FF),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _infoRow('수집 항목', '별명, 분석 점수·등급 (케미·맞짱 방 이용 시)'),
                    _infoRow('저장 위치', '해외 서버 (개인정보보호법 제28조의8에 따라 동의 후 이용)'),
                    _infoRow('보유 기간', '방 입장 후 30분 자동 삭제'),
                    _infoRow('비저장 항목', '생년월일·사주 팔자·성별'),
                    _infoRow('이용 제한', '만 14세 미만 이용 불가'),
                    const Divider(color: Color(0xFF2A2A4A), height: 20),
                    _infoRow('광고', 'Google AdMob 배너·전면 광고가 표시됩니다'),
                    _infoRow('광고 식별자', 'Google 광고 ID(GAID)가 Google LLC(미국)로 전송될 수 있습니다'),
                    const SizedBox(height: 10),
                    const Text(
                      '* 생년월일 등 민감 정보는 기기 내에서만 처리되며 서버에 저장되지 않습니다.\n'
                      '* 광고 식별자 수집은 「개인정보 보호법」상 국외 이전에 해당하며, '
                      '본 동의로 이에 동의하는 것으로 간주합니다.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF888888),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 개인정보처리방침 링크 안내
              Center(
                child: TextButton.icon(
                  onPressed: () => _showFullPolicy(context),
                  icon: const Icon(
                    Icons.open_in_new,
                    size: 14,
                    color: Color(0xFF93B4FF),
                  ),
                  label: const Text(
                    '개인정보 처리방침 전문 보기',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF93B4FF),
                      decoration: TextDecoration.underline,
                      decorationColor: Color(0xFF93B4FF),
                    ),
                  ),
                ),
              ),

                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 만 14세 이상 확인 (필수) — 체크해야 동의 버튼 활성화
              Row(
                children: [
                  Checkbox(
                    value: _age14,
                    onChanged: (v) => setState(() => _age14 = v ?? false),
                    activeColor: const Color(0xFF3B5BDB),
                    checkColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF555577)),
                  ),
                  const Expanded(
                    child: Text(
                      '본인은 만 14세 이상이며, 위 내용에 동의합니다. (필수)',
                      style: TextStyle(color: Color(0xFFCCCCCC), fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // 동의 버튼 (하단 고정 — 내용은 위에서 스크롤)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _age14 ? _acceptAndProceed : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B5BDB),
                    disabledBackgroundColor: const Color(0xFF2A2A4A),
                    foregroundColor: Colors.white,
                    disabledForegroundColor: const Color(0xFF555577),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    '동의하고 시작하기',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF888888),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFFCCCCCC),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFullPolicy(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF12122A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, scrollController) => Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF3B5BDB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '개인정보 처리방침',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '시행일: 2026-06-14 · 최종 수정: 2026-06-14 · 서비스명: Sai (Saju Analysis Interactive)',
                      style: TextStyle(fontSize: 11, color: Color(0xFF888888)),
                    ),
                    const SizedBox(height: 16),
                    _policyText(),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text(
                          '닫기',
                          style: TextStyle(color: Color(0xFF93B4FF)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _policyText() {
    const style = TextStyle(
      fontSize: 12,
      color: Color(0xFFCCCCCC),
      height: 1.7,
    );
    const headStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.bold,
      color: Color(0xFF93B4FF),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text('1. 개인정보의 처리 목적', style: headStyle),
        SizedBox(height: 4),
        Text(
          'Sai는 사주 원국 분석, 케미 방·맞짱 방 기능 제공 등을 위해 '
          '정보주체의 동의를 바탕으로 개인정보를 처리합니다.',
          style: style,
        ),
        SizedBox(height: 12),
        Text('2. 수집하는 개인정보 항목', style: headStyle),
        SizedBox(height: 4),
        Text(
          '케미 방·맞짱 방 참여 시 별명(최대 10자)과 분석 점수·등급만 저장됩니다. '
          '생년월일시, 성별, 사주 원국 간지(8글자) 등은 서버에 저장되지 않습니다.',
          style: style,
        ),
        SizedBox(height: 12),
        Text('3. 보유 및 이용 기간', style: headStyle),
        SizedBox(height: 4),
        Text(
          '방 생성·입장 시각으로부터 30분 후 자동 삭제됩니다. '
          '별도 요청 없이도 서버에서 완전히 파기됩니다.',
          style: style,
        ),
        SizedBox(height: 12),
        Text('4. 위탁 및 국외 이전', style: headStyle),
        SizedBox(height: 4),
        Text(
          '데이터는 Oracle Cloud 춘천 리전(대한민국 소재)에 저장되며 국외 이전이 발생하지 않습니다. '
          '소스 코드 관리에 GitHub(미국)를 이용하나 개인정보는 저장되지 않습니다.',
          style: style,
        ),
        SizedBox(height: 12),
        Text('5. 만 14세 미만 아동', style: headStyle),
        SizedBox(height: 4),
        Text(
          '본 서비스는 만 14세 미만 아동의 개인정보를 처리하지 않습니다. '
          '생년월일 입력 시 만 14세 미만으로 확인되면 서비스 이용이 차단됩니다.',
          style: style,
        ),
        SizedBox(height: 12),
        Text('6. 안전성 확보조치', style: headStyle),
        SizedBox(height: 4),
        Text(
          '서버는 방화벽(UFW)으로 보호되며, SSH는 공개키 인증만 허용합니다. '
          'DB는 외부 직접 접근을 차단하고 컨테이너 내부 통신만 허용합니다. '
          'DB 접근 정보는 환경 변수에만 보관하며 코드에 노출하지 않습니다.',
          style: style,
        ),
        SizedBox(height: 12),
        Text('7. 문의처', style: headStyle),
        SizedBox(height: 4),
        Text(
          '개인정보 보호책임자: 신성윤\n연락처: hwakia@gmail.com',
          style: style,
        ),
      ],
    );
  }
}
