INSERT INTO categories(name, color)
VALUES
    ('Food', '#FF6B6B'),
    ('Transport', '#4D96FF'),
    ('Shopping', '#6BCB77')
ON CONFLICT DO NOTHING;
