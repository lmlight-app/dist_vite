-- Enable pgvector extension in the digitalbase database.
-- Executed once on first Postgres container startup
-- (subsequent starts are no-ops because the data volume already exists).
CREATE EXTENSION IF NOT EXISTS vector;
