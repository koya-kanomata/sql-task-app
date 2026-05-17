#!/bin/sh
set -eu

: "${POSTGRES_DB:?POSTGRES_DB is required}"
: "${POSTGRES_USER:?POSTGRES_USER is required}"
: "${APP_DB_USERNAME:?APP_DB_USERNAME is required}"
: "${APP_DB_PASSWORD:?APP_DB_PASSWORD is required}"

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" \
  --set app_db_username="$APP_DB_USERNAME" \
  --set app_db_password="$APP_DB_PASSWORD" <<'EOSQL'
SELECT format(
    'CREATE ROLE %I LOGIN PASSWORD %L NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT',
    :'app_db_username',
    :'app_db_password'
)
WHERE NOT EXISTS (
    SELECT 1 FROM pg_roles WHERE rolname = :'app_db_username'
)
\gexec

REVOKE CREATE ON SCHEMA public FROM PUBLIC;
GRANT USAGE ON SCHEMA public TO PUBLIC;

CREATE TABLE IF NOT EXISTS tasks (
    id                SERIAL PRIMARY KEY,
    title             VARCHAR(255) NOT NULL,
    description       TEXT,
    status            VARCHAR(50)  NOT NULL DEFAULT 'TODO',
    priority          VARCHAR(20)  NOT NULL DEFAULT 'MEDIUM',
    due_date          DATE,
    created_at        TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at        TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS sql_history (
    id                SERIAL PRIMARY KEY,
    executed_at       TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    query             TEXT         NOT NULL,
    outcome           VARCHAR(500),
    execution_time_ms NUMERIC(10, 3)
);

INSERT INTO tasks (title, description, status, priority, due_date) VALUES
    ('SQLアプリを作る',       'Spring Boot + PostgreSQLでタスク管理アプリを構築する',  'DOING',  'HIGH',   CURRENT_DATE),
    ('要件定義書を書く',      'ユーザーストーリーとER図を作成する',                      'TODO',   'HIGH',   CURRENT_DATE + INTERVAL '3 days'),
    ('UIデザインを決める',    'Figmaでワイヤーフレームを作成する',                        'TODO',   'MEDIUM', CURRENT_DATE + INTERVAL '7 days'),
    ('テストを書く',          'JUnitでコントローラーのユニットテストを実装する',           'TODO',   'MEDIUM', CURRENT_DATE + INTERVAL '14 days'),
    ('デプロイ手順を整備する','Dockerイメージのビルドとサーバへのデプロイ手順をまとめる', 'TODO',   'LOW',    CURRENT_DATE + INTERVAL '21 days'),
    ('コードレビュー',        'プルリクエストのレビューを実施する',                        'DONE',   'HIGH',   CURRENT_DATE - INTERVAL '2 days'),
    ('期限切れタスクのサンプル','このタスクは期限切れです',                                'TODO',   'LOW',    CURRENT_DATE - INTERVAL '5 days');

SELECT format('GRANT CONNECT ON DATABASE %I TO %I', current_database(), :'app_db_username')
\gexec
SELECT format('GRANT USAGE ON SCHEMA public TO %I', :'app_db_username')
\gexec
SELECT format('GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE tasks, sql_history TO %I', :'app_db_username')
\gexec
SELECT format('GRANT USAGE, SELECT, UPDATE ON ALL SEQUENCES IN SCHEMA public TO %I', :'app_db_username')
\gexec
EOSQL