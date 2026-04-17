package db

const schema = `
CREATE TABLE IF NOT EXISTS devices (
    device_id TEXT PRIMARY KEY,
    kair_number TEXT UNIQUE NOT NULL,
    public_key BLOB NOT NULL,
    status TEXT NOT NULL CHECK(status IN ('pending','active','revoked')),
    activated_by_node TEXT,
    activation_timestamp INTEGER,
    last_seen INTEGER
);

CREATE TABLE IF NOT EXISTS contacts (
    knumber TEXT PRIMARY KEY,
    display_name TEXT NOT NULL,
    real_phone TEXT,
    notes TEXT,
    trust_status TEXT NOT NULL CHECK(trust_status IN ('unknown','pending','trusted','blocked')),
    last_interaction INTEGER,
    avatar_ascii TEXT
);

CREATE TABLE IF NOT EXISTS message_queue (
    id TEXT PRIMARY KEY,
    receiver_kair TEXT NOT NULL,
    payload BLOB NOT NULL,
    retry_count INTEGER NOT NULL DEFAULT 0,
    next_retry INTEGER NOT NULL,
    created_at INTEGER NOT NULL,
    expires_at INTEGER NOT NULL,
    status TEXT NOT NULL DEFAULT 'queued' CHECK(status IN ('queued','delivered','failed'))
);

CREATE TABLE IF NOT EXISTS trust_scores (
    kair_number TEXT PRIMARY KEY,
    score REAL NOT NULL,
    interaction_count INTEGER NOT NULL DEFAULT 0,
    last_updated INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS ai_memory (
    id TEXT PRIMARY KEY,
    memory_type TEXT NOT NULL,
    target_id TEXT,
    content TEXT NOT NULL,
    importance REAL DEFAULT 0.5,
    created_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS file_transfers (
    transfer_id TEXT PRIMARY KEY,
    sender_kair TEXT NOT NULL,
    receiver_kair TEXT NOT NULL,
    total_chunks INTEGER NOT NULL,
    received_chunks INTEGER NOT NULL DEFAULT 0,
    checksum TEXT,
    status TEXT NOT NULL DEFAULT 'queued'
);

CREATE TABLE IF NOT EXISTS admin_codes (
    code TEXT PRIMARY KEY,
    issued_at INTEGER NOT NULL,
    expires_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS delivery_attempts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    queue_id TEXT NOT NULL,
    attempted_at INTEGER NOT NULL,
    outcome TEXT NOT NULL,
    detail TEXT
);
`
