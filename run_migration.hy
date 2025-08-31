;;; run_migration.hy - Example of running the posts migration
;;; Shows the complete flow of executing a migration

(import sqlite3)
(import sys)
(import os)
(import datetime [datetime])
(import pathlib [Path])

;; Import our migration
(import migrations.003-create-posts-table [CreatePostsTable])

(defclass MigrationExecutor []
  "Simplified migration executor for demonstration"
  
  (defn __init__ [self db-path]
    (setv self.db-path db-path)
    (setv self.connection None))
  
  (defn connect [self]
    "Establish database connection"
    (print f"📁 Connecting to database: {self.db-path}")
    (setv self.connection (sqlite3.connect self.db-path))
    ;; Enable foreign keys
    (.execute self.connection "PRAGMA foreign_keys = ON")
    (print "   ✓ Connected successfully"))
  
  (defn disconnect [self]
    "Close database connection"
    (when self.connection
      (.close self.connection)
      (setv self.connection None)
      (print "   ✓ Disconnected")))
  
  (defn ensure-migration-table [self]
    "Create migration history table if not exists"
    (print "\n📋 Checking migration history table...")
    (.execute self.connection
      "CREATE TABLE IF NOT EXISTS migration_history (
         id INTEGER PRIMARY KEY AUTOINCREMENT,
         version TEXT UNIQUE NOT NULL,
         name TEXT NOT NULL,
         applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
         checksum TEXT,
         success BOOLEAN DEFAULT 1,
         execution_time_ms INTEGER,
         error_message TEXT
       )")
    (.commit self.connection)
    (print "   ✓ Migration history table ready"))
  
  (defn is-migration-applied [self version]
    "Check if a migration has already been applied"
    (setv cursor (.execute self.connection
      "SELECT version, applied_at FROM migration_history 
       WHERE version = ? AND success = 1"
      [version]))
    (setv result (.fetchone cursor))
    (if result
      {:applied True :date (get result 1)}
      {:applied False}))
  
  (defn record-migration [self migration success execution-time &optional [error None]]
    "Record migration execution in history"
    (.execute self.connection
      "INSERT INTO migration_history 
       (version, name, checksum, success, execution_time_ms, error_message)
       VALUES (?, ?, ?, ?, ?, ?)"
      [migration.version 
       migration.name 
       (migration.get-checksum)
       (int success)
       execution-time
       (if error (str error) None)])
    (.commit self.connection))
  
  (defn run-migration [self migration &optional [dry-run False]]
    "Execute a single migration with proper error handling"
    (import time)
    
    (print f"\n{'=' (* 60)}")
    (print f"Migration {migration.version}: {migration.name}")
    (print f"{'=' (* 60)}")
    
    ;; Check if already applied
    (setv status (self.is-migration-applied migration.version))
    (when (get status :applied)
      (print f"⏭️  Already applied on: {(get status :date)}")
      (return True))
    
    (if dry-run
      (do
        (print "\n🔍 DRY RUN MODE - No changes will be made")
        (print "\nSQL statements that would be executed:")
        (print "-" (* 40))
        (for [i sql] (enumerate migration.up-sql 1)
          (setv [index statement] i)
          (print f"\n[{index}] {(.split statement \newline) [0][:80]}...")
          (when (> (len statement) 80)
            (print "    [... statement truncated ...]")))
        (print "\n✓ Dry run complete")
        True)
      
      (do
        ;; Actual execution
        (print "\n🚀 Executing migration...")
        (setv start-time (time.time))
        
        (try
          ;; Begin transaction
          (.execute self.connection "BEGIN TRANSACTION")
          (print "   ✓ Transaction started")
          
          ;; Run the migration
          (migration.up self.connection)
          
          ;; Validate if the migration provides validation
          (when (hasattr migration "validate")
            (print "\n🔍 Validating migration...")
            (setv is-valid (migration.validate self.connection))
            (when (not is-valid)
              (raise Exception "Migration validation failed")))
          
          ;; Calculate execution time
          (setv execution-time (int (* (- (time.time) start-time) 1000)))
          
          ;; Record success
          (self.record-migration migration True execution-time)
          
          ;; Commit transaction
          (.commit self.connection)
          (print f"\n✅ Migration completed successfully in {execution-time}ms")
          
          ;; Show summary
          (self.show-migration-summary migration)
          
          True
          
          (except [Exception :as e]
            ;; Rollback on error
            (print f"\n❌ Migration failed: {e}")
            (.rollback self.connection)
            (print "   ✓ Transaction rolled back")
            
            ;; Record failure
            (setv execution-time (int (* (- (time.time) start-time) 1000)))
            (self.record-migration migration False execution-time e)
            
            False)))))
  
  (defn rollback-migration [self migration &optional [dry-run False]]
    "Rollback a migration"
    (print f"\n{'=' (* 60)}")
    (print f"Rolling back {migration.version}: {migration.name}")
    (print f"{'=' (* 60)}")
    
    (if dry-run
      (do
        (print "\n🔍 DRY RUN MODE - No changes will be made")
        (print "\nSQL statements that would be executed:")
        (print "-" (* 40))
        (for [i sql] (enumerate migration.down-sql 1)
          (setv [index statement] i)
          (print f"\n[{index}] {statement[:80]}...")
          (when (> (len statement) 80)
            (print "    [... statement truncated ...]")))
        (print "\n✓ Dry run complete")
        True)
      
      (do
        (print "\n🔄 Executing rollback...")
        
        (try
          ;; Begin transaction
          (.execute self.connection "BEGIN TRANSACTION")
          
          ;; Run the rollback
          (migration.down self.connection)
          
          ;; Remove from history
          (.execute self.connection
            "DELETE FROM migration_history WHERE version = ?"
            [migration.version])
          
          ;; Commit
          (.commit self.connection)
          (print "\n✅ Rollback completed successfully")
          True
          
          (except [Exception :as e]
            (print f"\n❌ Rollback failed: {e}")
            (.rollback self.connection)
            False)))))
  
  (defn show-migration-summary [self migration]
    "Show summary of what was created"
    (print "\n📊 Migration Summary:")
    (print "   Created tables:")
    (print "     • posts (blog posts)")
    (print "     • tags (categorization)")  
    (print "     • post_tags (many-to-many)")
    (print "     • comments (discussions)")
    (print "   Created indexes: 9")
    (print "   Foreign keys: 5"))
  
  (defn show-status [self]
    "Show current migration status"
    (print "\n📊 Migration Status")
    (print "=" (* 60))
    
    (setv cursor (.execute self.connection
      "SELECT version, name, applied_at, success, execution_time_ms
       FROM migration_history
       ORDER BY applied_at DESC"))
    
    (setv migrations (.fetchall cursor))
    
    (if migrations
      (do
        (print f"{'Version':<10} {'Name':<30} {'Applied':<20} {'Status':<10} {'Time'}")
        (print "-" (* 80))
        (for [m migrations]
          (setv [version name applied success time-ms] m)
          (setv status (if success "✅ OK" "❌ FAILED"))
          (print f"{version:<10} {name:<30} {applied:<20} {status:<10} {time-ms}ms")))
      (print "No migrations have been applied yet."))
    
    (print "\n" "=" (* 60))))

(defn main [&optional [args None]]
  "Main entry point"
  (print "\n" "╔" "═" (* 58) "╗")
  (print   "║" " " (* 16) "MIGRATION RUNNER EXAMPLE" " " (* 16) "║")
  (print   "╚" "═" (* 58) "╝")
  
  ;; Parse arguments
  (setv dry-run (and args (in "--dry-run" args)))
  (setv rollback-mode (and args (in "--rollback" args)))
  (setv show-status (and args (in "--status" args)))
  
  ;; Database path
  (setv db-path "example.db")
  
  ;; Create executor
  (setv executor (MigrationExecutor db-path))
  
  (try
    ;; Connect to database
    (executor.connect)
    
    ;; Ensure prerequisites
    (executor.ensure-migration-table)
    
    ;; Create prerequisite tables if needed (for demo)
    (when (not (.fetchone (.execute executor.connection
                                   "SELECT 1 FROM sqlite_master 
                                    WHERE type='table' AND name='users'")))
      (print "\n📦 Creating prerequisite users table...")
      (.execute executor.connection
        "CREATE TABLE users (
           id INTEGER PRIMARY KEY AUTOINCREMENT,
           username VARCHAR(255) UNIQUE NOT NULL,
           email VARCHAR(255) UNIQUE NOT NULL,
           password_hash VARCHAR(255) NOT NULL,
           is_active BOOLEAN DEFAULT 1,
           created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
           updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
         )")
      (.execute executor.connection
        "INSERT INTO users (username, email, password_hash) 
         VALUES ('admin', 'admin@example.com', 'hashed_password')")
      (.commit executor.connection)
      (print "   ✓ Users table created"))
    
    ;; Show status if requested
    (when show-status
      (executor.show-status)
      (return))
    
    ;; Create the migration
    (setv migration (CreatePostsTable))
    
    ;; Execute based on mode
    (if rollback-mode
      (executor.rollback-migration migration dry-run)
      (executor.run-migration migration dry-run))
    
    ;; Show final status
    (executor.show-status)
    
    (except [KeyboardInterrupt]
      (print "\n\n⚠️  Migration interrupted by user"))
    
    (except [Exception :as e]
      (print f"\n\n❌ Fatal error: {e}")
      (import traceback)
      (traceback.print-exc))
    
    (finally
      ;; Always disconnect
      (executor.disconnect))))

;; Command-line interface
(when (= __name__ "__main__")
  (print "\nUsage:")
  (print "  hy run_migration.hy              # Run the migration")
  (print "  hy run_migration.hy --dry-run    # Preview without executing")
  (print "  hy run_migration.hy --rollback   # Rollback the migration")
  (print "  hy run_migration.hy --status     # Show migration status")
  
  (main sys.argv))
