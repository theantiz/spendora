ALTER TABLE ai_suggestions
    ADD COLUMN IF NOT EXISTS normalized_input TEXT,
    ADD COLUMN IF NOT EXISTS user_id BIGINT DEFAULT 0 NOT NULL,
    ADD COLUMN IF NOT EXISTS final_category VARCHAR(100),
    ADD COLUMN IF NOT EXISTS source VARCHAR(30) DEFAULT 'RULE_ENGINE' NOT NULL,
    ADD COLUMN IF NOT EXISTS validated BOOLEAN DEFAULT FALSE NOT NULL,
    ADD COLUMN IF NOT EXISTS overridden BOOLEAN DEFAULT FALSE NOT NULL;

UPDATE ai_suggestions
SET normalized_input = lower(regexp_replace(input_text, '[^a-zA-Z0-9 ]', '', 'g'))
WHERE normalized_input IS NULL;

ALTER TABLE ai_suggestions
    ALTER COLUMN normalized_input SET NOT NULL;

CREATE INDEX IF NOT EXISTS idx_ai_suggestions_user_normalized
    ON ai_suggestions(user_id, normalized_input);

CREATE INDEX IF NOT EXISTS idx_ai_suggestions_validated
    ON ai_suggestions(validated, overridden);
