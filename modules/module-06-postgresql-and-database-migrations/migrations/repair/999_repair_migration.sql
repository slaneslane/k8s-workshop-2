-- Idempotent cleanup for the intentional workshop failure.
-- This affects only the isolated workshop_training schema.

DROP SCHEMA IF EXISTS workshop_training CASCADE;
