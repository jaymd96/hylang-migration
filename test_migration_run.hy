#!/usr/bin/env hy
;;; Test running a migration directly

(import sqlite3)
(import pathlib [Path])

;; Create a test database
(setv db-path "test_migration.db")
(setv conn (sqlite3.connect db-path))
(setv cursor (.cursor conn))

(print "🔄 Running test migration...")

;; Create migration history table
(cursor.execute "
CREATE TABLE IF NOT EXISTS migration_history (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    version VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    checksum VARCHAR(255),
    applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
)")

;; Create users table (from migration 001)
(cursor.execute "
CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username VARCHAR(255) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    is_active BOOLEAN DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
)")

(cursor.execute "CREATE INDEX IF NOT EXISTS idx_users_email ON users(email)")
(cursor.execute "CREATE INDEX IF NOT EXISTS idx_users_username ON users(username)")

;; Record migration
(cursor.execute "
INSERT OR IGNORE INTO migration_history (version, name, checksum)
VALUES ('001', 'create_users_table', 'test_checksum')
")

;; Insert test data
(cursor.execute "
INSERT INTO users (username, email, password_hash)
VALUES ('testuser', 'test@example.com', 'hashed_password')
")

(conn.commit)
(print "✅ Migration executed successfully!")

;; Verify the migration worked
(cursor.execute "SELECT * FROM users")
(setv users (cursor.fetchall))
(print (.format "\n📊 Users in database: {}" (len users)))
(for [user users]
  (print (.format "  - User: {} ({})" (get user 1) (get user 2))))

;; Check migration history
(cursor.execute "SELECT * FROM migration_history")
(setv migrations (cursor.fetchall))
(print (.format "\n📋 Applied migrations: {}" (len migrations)))
(for [migration migrations]
  (print (.format "  - Version {} : {}" (get migration 1) (get migration 2))))

(conn.close)
(print (.format "\n✨ Test database created at: {}" db-path))