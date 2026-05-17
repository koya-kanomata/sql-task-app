#!/bin/bash
docker exec sql-task-db psql -U taskuser -d sqltaskdb << 'EOF'
CREATE TABLE IF NOT EXISTS tasks (
    id          SERIAL PRIMARY KEY,
    title       VARCHAR(255) NOT NULL,
    description TEXT,
    status      VARCHAR(50)  NOT NULL DEFAULT 'TODO',
    priority    VARCHAR(20)  NOT NULL DEFAULT 'MEDIUM',
    due_date    DATE,
    created_at  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS sql_history (
    id              SERIAL PRIMARY KEY,
    executed_at     TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    query           TEXT         NOT NULL,
    outcome         VARCHAR(500),
    execution_time_ms NUMERIC(10, 3)
);

INSERT INTO tasks (title, description, status, priority, due_date) VALUES
    ('SQLアプリを作る',       'Spring Boot + PostgreSQLでタスク管理アプリを構築する',  'DOING',  'HIGH',   CURRENT_DATE),
    ('要件定義書を書く',      'ユーザーストーリーとER図を作成する',                      'TODO',   'HIGH',   CURRENT_DATE + INTERVAL '3 days'),
    ('UIデザインを決める',    'Figmaでワイヤーフレームを作成する',                        'TODO',   'MEDIUM', CURRENT_DATE + INTERVAL '7 days'),
    ('テストを書く',          'JUnitでコントローラーのユニットテストを実装する',           'TODO',   'MEDIUM', CURRENT_DATE + INTERVAL '14 days'),
    ('デプロイ手順を整備する','Dockerイメージのビルドとサーバへのデプロイ手順をまとめる', 'TODO',   'LOW',    CURRENT_DATE + INTERVAL '21 days'),
    ('コードレビュー',        'プルリクエストのレビューを実施する',                        'DONE',   'HIGH',   CURRENT_DATE - INTERVAL '2 days'),
    ('期限切れタスクのサンプル','このタスクは期限切れです',                                'TODO',   'LOW',    CURRENT_DATE - INTERVAL '5 days')
ON CONFLICT DO NOTHING;

\dt
SELECT COUNT(*) FROM tasks;
EOF
echo "DB init done: $?"
