-- タスクテーブル
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

-- SQL実行履歴テーブル
CREATE TABLE IF NOT EXISTS sql_history (
    id              SERIAL PRIMARY KEY,
    executed_at     TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    query           TEXT         NOT NULL,
    outcome         VARCHAR(500),
    execution_time_ms NUMERIC(10, 3)
);
