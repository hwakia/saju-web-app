-- ============================================================
--  Sai — Supabase 자동 파기(pg_cron) 설정
--  목적: "30분 방 데이터 / 180일 이용통계 자동 삭제"를 트래픽과 무관하게
--        DB 레벨 예약작업으로 보장 (앱 세션 기반 정리는 보조).
--  실행: Supabase 대시보드 → SQL Editor 에 붙여넣고 1회 실행.
--        (Database → Extensions 에서 pg_cron 을 미리 켜도 됨)
-- ============================================================

-- 1) pg_cron 확장 활성화
create extension if not exists pg_cron;

-- 2) 만료된 방 데이터 정리 — 10분마다 expires_at 경과분 삭제
--    (케미방/맞짱방/맞짱결과: 생성·참여 후 30분 만료 → 최대 10분 내 정리)
select cron.schedule(
  'sai_cleanup_expired_rooms',
  '*/10 * * * *',
  $$
    delete from public.chemistry_rooms where expires_at < now();
    delete from public.battle_rooms   where expires_at < now();
    delete from public.battles        where expires_at < now();
  $$
);

-- 3) 이용 통계 로그 180일 경과분 정리 — 매일 03:30(UTC)
select cron.schedule(
  'sai_cleanup_old_app_events',
  '30 3 * * *',
  $$ delete from public.app_events where created_at < now() - interval '180 days'; $$
);

-- ── 확인 / 관리 ─────────────────────────────────────────────
-- 등록된 잡 보기:   select * from cron.job;
-- 실행 이력 보기:   select * from cron.job_run_details order by start_time desc limit 20;
-- 잡 해제(필요시):  select cron.unschedule('sai_cleanup_expired_rooms');
--                   select cron.unschedule('sai_cleanup_old_app_events');
