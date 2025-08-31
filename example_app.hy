;;; example_app.hy - Example application using the migration tool with SQLObject

(import models [User UserProfile init-db])
(import migrations [MigrationRunner])
(import config [init-config DATABASE])

(defn setup-database []
  "Initialize database with migrations"
  (print "Setting up database...")
  
  ;; Initialize configuration
  (init-config)
  
  ;; Run migrations
  (setv runner (MigrationRunner (get DATABASE :path) "migrations"))
  (runner.run-migrations)
  
  ;; Initialize SQLObject connection
  (init-db)
  
  (print "Database setup complete!"))

(defn create-sample-data []
  "Create some sample data"
  (print "\nCreating sample data...")
  
  ;; Create a user
  (setv user (User :username "johndoe"
                   :email "john@example.com"
                   :password-hash "hashed_password"
                   :is-active True))
  
  (print f"Created user: {user.username}")
  
  ;; Create user profile
  (setv profile (UserProfile :user user
                            :full-name "John Doe"
                            :bio "Software developer interested in Lisp"
                            :avatar-url "https://example.com/avatar.jpg"))
  
  (print f"Created profile for: {profile.full-name}")
  
  ;; Create another user
  (setv user2 (User :username "janedoe"
                    :email "jane@example.com"
                    :password-hash "hashed_password2"
                    :is-active True))
  
  (print f"Created user: {user2.username}"))

(defn query-examples []
  "Demonstrate various queries"
  (print "\n=== Query Examples ===")
  
  ;; Get all users
  (print "\nAll users:")
  (for [user (User.select)]
    (print f"  - {user.username} ({user.email})"))
  
  ;; Get active users
  (print "\nActive users:")
  (import models [get-active-users])
  (for [user (get-active-users)]
    (print f"  - {user.username}"))
  
  ;; Get users with profiles
  (print "\nUsers with profiles:")
  (import models [get-users-with-profiles])
  (for [user (get-users-with-profiles)]
    (print f"  - {user.username}"))
  
  ;; Find user by email
  (print "\nFind user by email (john@example.com):")
  (import models [get-user-by-email])
  (setv users (list (get-user-by-email "john@example.com")))
  (if users
    (print f"  Found: {(. (first users) username)}")
    (print "  Not found"))
  
  ;; Access related objects
  (print "\nUser profiles:")
  (setv user (first (User.selectBy :username "johndoe")))
  (when user
    (setv profiles (list user.profile))
    (when profiles
      (setv profile (first profiles))
      (print f"  {user.username} -> {profile.full-name}")
      (print f"    Bio: {profile.bio}"))))

(defn update-examples []
  "Demonstrate updates"
  (print "\n=== Update Examples ===")
  
  ;; Update user
  (setv user (first (User.selectBy :username "johndoe")))
  (when user
    (print f"\nUpdating user {user.username}...")
    (setv user.email "newemail@example.com")
    (user.update-timestamp)
    (print f"  Email changed to: {user.email}"))
  
  ;; Update profile
  (when user
    (setv profiles (list user.profile))
    (when profiles
      (setv profile (first profiles))
      (print f"\nUpdating profile for {user.username}...")
      (setv profile.bio "Updated bio - now a Hylang expert!")
      (profile.update-timestamp)
      (print f"  Bio updated: {profile.bio}"))))

(defn migration-status []
  "Show current migration status"
  (print "\n=== Migration Status ===")
  (setv runner (MigrationRunner (get DATABASE :path) "migrations"))
  (runner.status))

(defn rollback-example []
  "Demonstrate migration rollback"
  (print "\n=== Rollback Example ===")
  (print "WARNING: This will rollback the last migration!")
  (print "In a real application, be very careful with rollbacks.")
  
  ;; Normally you would:
  ;; (setv runner (MigrationRunner (get DATABASE :path) "migrations"))
  ;; (runner.rollback-migration last-migration)
  
  (print "(Rollback not executed in example)"))

(defn main []
  "Main entry point for example application"
  (print "=" (* 50))
  (print "Hylang Migration Tool - Example Application")
  (print "=" (* 50))
  
  (try
    ;; Setup database with migrations
    (setup-database)
    
    ;; Create sample data
    (create-sample-data)
    
    ;; Run query examples
    (query-examples)
    
    ;; Run update examples
    (update-examples)
    
    ;; Show migration status
    (migration-status)
    
    ;; Show rollback example (commented out for safety)
    ;; (rollback-example)
    
    (print "\n" "=" (* 50))
    (print "Example completed successfully!")
    (print "=" (* 50))
    
    (except [Exception :as e]
      (print f"\nError: {e}")
      (import traceback)
      (traceback.print-exc))))

;; Helper functions for REPL interaction
(defn repl-connect []
  "Connect to database for REPL experimentation"
  (init-config)
  (init-db)
  (print "Connected to database. Models available: User, UserProfile"))

(defn repl-query [model-class &optional [filter-dict {}]]
  "Quick query helper for REPL"
  (if filter-dict
    (list (model-class.selectBy #** filter-dict))
    (list (model-class.select))))

(when (= __name__ "__main__")
  (main))
