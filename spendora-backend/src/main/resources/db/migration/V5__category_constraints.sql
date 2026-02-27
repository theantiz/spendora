CREATE UNIQUE INDEX IF NOT EXISTS uq_categories_name_ci
    ON categories (lower(name));
