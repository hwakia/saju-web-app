-- Sai — Supabase 보안: RLS(Row Level Security) 활성화
-- 목적: 공개 anon 키로 테이블이 통째로 조회/덤프되는 것을 차단한다.
-- 전제: 앱(app.py)은 SUPABASE_SERVICE_KEY(service_role)로 접근하며, service_role 키는
--       RLS를 우회하므로 아래 설정 후에도 앱 기능은 정상 동작한다.
--       (Streamlit Secrets에 SUPABASE_SERVICE_KEY가 설정돼 있어야 함. anon 키만 쓰면
--        아래 설정 후 방 기능이 막히니 반드시 service_role 키 사용을 확인할 것.)
--
-- 실행: Supabase 대시보드 → SQL Editor → 아래 붙여넣고 RUN.

-- 1) 모든 테이블에 RLS 활성화 (정책을 추가하지 않으면 anon/public 접근은 0건)
alter table public.chemistry_rooms enable row level security;
alter table public.battle_rooms    enable row level security;
alter table public.battles          enable row level security;
alter table public.app_events       enable row level security;

-- 2) (선택) 외부에서 anon 키로 들어온 요청을 명시적으로 전부 차단하는 정책.
--    RLS만 켜도 정책이 없으면 차단되지만, 의도를 분명히 남기고 싶을 때 사용.
--    service_role 키는 RLS를 우회하므로 이 정책에 영향받지 않는다.
-- (필요 시 주석 해제)
-- create policy "deny anon all" on public.chemistry_rooms for all to anon using (false) with check (false);
-- create policy "deny anon all" on public.battle_rooms    for all to anon using (false) with check (false);
-- create policy "deny anon all" on public.battles          for all to anon using (false) with check (false);
-- create policy "deny anon all" on public.app_events       for all to anon using (false) with check (false);

-- 3) 검증: 아래 쿼리로 4개 테이블의 rowsecurity 가 모두 true 인지 확인.
select schemaname, tablename, rowsecurity
from pg_tables
where schemaname = 'public'
  and tablename in ('chemistry_rooms','battle_rooms','battles','app_events')
order by tablename;
