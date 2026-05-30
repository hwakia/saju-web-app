-- 사주MRI PostgreSQL 초기화 SQL
-- Oracle VM Docker PostgreSQL에서 1회 실행

-- ── 케미 방 ────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS chemistry_rooms (
  id                 text PRIMARY KEY,
  max_participants   integer NOT NULL DEFAULT 5,
  participants       jsonb   NOT NULL DEFAULT '[]'::jsonb,
  status             text    NOT NULL DEFAULT 'waiting',  -- waiting | full
  chemistry_result   jsonb,
  expires_at         timestamptz NOT NULL,
  created_at         timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_chemistry_rooms_expires ON chemistry_rooms (expires_at);

-- ── 맞짱 방 ────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS battle_rooms (
  id               text PRIMARY KEY,
  max_participants integer NOT NULL DEFAULT 5,
  participants     jsonb   NOT NULL DEFAULT '[]'::jsonb,
  status           text    NOT NULL DEFAULT 'waiting',
  expires_at       timestamptz NOT NULL,
  created_at       timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_battle_rooms_expires ON battle_rooms (expires_at);

-- ── 맞짱 결과 (단순 공유용) ────────────────────────────────────────
CREATE TABLE IF NOT EXISTS battles (
  id            text PRIMARY KEY,
  participants  jsonb NOT NULL DEFAULT '[]'::jsonb,
  expires_at    timestamptz NOT NULL,
  created_at    timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_battles_expires ON battles (expires_at);

-- ── 방문 이벤트 Analytics ──────────────────────────────────────────
CREATE TABLE IF NOT EXISTS app_events (
  id          bigserial PRIMARY KEY,
  created_at  timestamptz NOT NULL DEFAULT now(),
  session_id  text,
  event_name  text,
  page_name   text,
  source      text,
  app_version text,
  is_admin    boolean DEFAULT false,
  metadata    jsonb DEFAULT '{}'::jsonb
);

CREATE INDEX IF NOT EXISTS idx_app_events_created ON app_events (created_at DESC);

-- ── 만료 데이터 자동 삭제 (pg_cron 설치 시) ─────────────────────
-- SELECT cron.schedule('cleanup-expired', '0 * * * *',
--   $$ DELETE FROM chemistry_rooms WHERE expires_at < now();
--      DELETE FROM battle_rooms    WHERE expires_at < now();
--      DELETE FROM battles         WHERE expires_at < now(); $$);
