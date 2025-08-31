#!/usr/bin/env hy
;;; Test what methods are available on MigrationRunner

(import hylang_migrations.migrations [MigrationRunner])

(print "Creating MigrationRunner instance...")
(setv runner (MigrationRunner "test.db" "migrations"))

(print "\nAvailable methods:")
(for [attr (dir runner)]
  (when (not (.startswith attr "_"))
    (print (.format "  - {}" attr))))

(print "\nHas status method?" (hasattr runner "status"))
(print "Has connect method?" (hasattr runner "connect"))
(print "Has ensure_migration_table method?" (hasattr runner "ensure_migration_table"))