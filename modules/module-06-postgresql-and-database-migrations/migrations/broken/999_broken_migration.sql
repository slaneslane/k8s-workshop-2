-- Intentional workshop failure.
-- The schema is isolated from the application's normal tables.

CREATE SCHEMA IF NOT EXISTS workshop_training;

CREATE TABLE IF NOT EXISTS workshop_training.partial_migration (
    id integer PRIMARY KEY,
    note text NOT NULL
);

-- First execution succeeds and persists.
ALTER TABLE workshop_training.partial_migration
    ADD COLUMN migration_marker text;

-- Intentional failure: the column has already been created above.
ALTER TABLE workshop_training.partial_migration
    ADD COLUMN migration_marker text;
