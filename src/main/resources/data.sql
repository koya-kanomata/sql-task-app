INSERT INTO tasks (title, description, status, priority, due_date) VALUES
    ('SQLアプリを作る',       'Spring Boot + PostgreSQLでタスク管理アプリを構築する',  'DOING',  'HIGH',   CURRENT_DATE),
    ('要件定義書を書く',      'ユーザーストーリーとER図を作成する',                      'TODO',   'HIGH',   CURRENT_DATE + INTERVAL '3 days'),
    ('UIデザインを決める',    'Figmaでワイヤーフレームを作成する',                        'TODO',   'MEDIUM', CURRENT_DATE + INTERVAL '7 days'),
    ('テストを書く',          'JUnitでコントローラーのユニットテストを実装する',           'TODO',   'MEDIUM', CURRENT_DATE + INTERVAL '14 days'),
    ('デプロイ手順を整備する','Dockerイメージのビルドとサーバへのデプロイ手順をまとめる', 'TODO',   'LOW',    CURRENT_DATE + INTERVAL '21 days'),
    ('コードレビュー',        'プルリクエストのレビューを実施する',                        'DONE',   'HIGH',   CURRENT_DATE - INTERVAL '2 days'),
    ('期限切れタスクのサンプル','このタスクは期限切れです',                                'TODO',   'LOW',    CURRENT_DATE - INTERVAL '5 days')
ON CONFLICT DO NOTHING;
