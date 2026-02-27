CREATE TABLE IF NOT EXISTS ai_suggestions (
    id BIGSERIAL PRIMARY KEY,
    input_text TEXT NOT NULL,
    suggested_category VARCHAR(100) NOT NULL,
    confidence NUMERIC(5,4) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
