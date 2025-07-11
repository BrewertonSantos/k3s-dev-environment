#!/bin/bash
# PostgreSQL initialization script for pgvector

set -e

# Create the vector extension
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    -- Create pgvector extension
    CREATE EXTENSION IF NOT EXISTS vector;
    
    -- Create the vector table for dev-indexer if it doesn't exist
    CREATE TABLE IF NOT EXISTS dev_directory_vectors (
        id TEXT PRIMARY KEY,
        content TEXT,
        metadata JSONB,
        embedding VECTOR(1536)
    );
    
    -- Create index for faster similarity search
    CREATE INDEX IF NOT EXISTS dev_directory_vectors_embedding_idx 
    ON dev_directory_vectors 
    USING ivfflat (embedding vector_cosine_ops);
    
    -- Grant permissions
    GRANT ALL PRIVILEGES ON TABLE dev_directory_vectors TO $POSTGRES_USER;
EOSQL
