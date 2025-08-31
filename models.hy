;;; models.hy - SQLObject model definitions

(import sqlobject [SQLObject StringCol IntCol DateTimeCol BoolCol 
                   ForeignKey SQLMultipleJoin])
(import sqlobject.sqlbuilder [AND OR NOT])
(import datetime [datetime])
(import config [get-connection-string])

;; Initialize SQLObject connection
(defn init-db []
  "Initialize database connection for SQLObject"
  (import sqlobject)
  (sqlobject.connectionForURI (get-connection-string)))

;;; User model - corresponds to migration 001
(defclass User [SQLObject]
  "User model with SQLObject"
  
  ;; Table name
  (setv _table "users")
  
  ;; Columns
  (setv username (StringCol :length 255 :unique True :notNone True))
  (setv email (StringCol :length 255 :unique True :notNone True))
  (setv password-hash (StringCol :length 255 :notNone True 
                                  :dbName "password_hash"))
  (setv is-active (BoolCol :default True :dbName "is_active"))
  (setv created-at (DateTimeCol :default datetime.now :dbName "created_at"))
  (setv updated-at (DateTimeCol :default datetime.now :dbName "updated_at"))
  
  ;; Relationships
  (setv profile (SQLMultipleJoin "UserProfile" :joinColumn "user_id"))
  
  ;; Methods
  (defn set-password [self password]
    "Hash and set password"
    ;; Stub - implement password hashing
    (setv self.password-hash (+ "hashed_" password)))
  
  (defn check-password [self password]
    "Verify password"
    ;; Stub - implement password verification
    (= self.password-hash (+ "hashed_" password)))
  
  (defn update-timestamp [self]
    "Update the updated_at timestamp"
    (setv self.updated-at (datetime.now))))

;;; UserProfile model - corresponds to migration 002
(defclass UserProfile [SQLObject]
  "User profile model with SQLObject"
  
  ;; Table name
  (setv _table "user_profiles")
  
  ;; Columns
  (setv user (ForeignKey "User" :dbName "user_id" :unique True :notNone True))
  (setv full-name (StringCol :length 255 :dbName "full_name"))
  (setv bio (StringCol))
  (setv avatar-url (StringCol :length 500 :dbName "avatar_url"))
  (setv date-of-birth (DateTimeCol :dbName "date_of_birth"))
  (setv created-at (DateTimeCol :default datetime.now :dbName "created_at"))
  (setv updated-at (DateTimeCol :default datetime.now :dbName "updated_at"))
  
  ;; Methods
  (defn get-age [self]
    "Calculate age from date of birth"
    (when self.date-of-birth
      ;; Stub - calculate age
      None))
  
  (defn update-timestamp [self]
    "Update the updated_at timestamp"
    (setv self.updated-at (datetime.now))))

;;; Query helpers
(defn get-active-users []
  "Get all active users"
  (User.select (= User.q.is-active True)))

(defn get-user-by-email [email]
  "Find user by email"
  (User.selectBy :email email :limit 1))

(defn get-users-with-profiles []
  "Get users that have profiles"
  (User.select (User.q.profile != None)))

;;; Model validation
(defn validate-models []
  "Validate that models match database schema"
  ;; Stub - compare SQLObject models with actual database schema
  (print "Validating models against database schema...")
  True)

;;; Schema introspection
(defn get-table-info [table-name]
  "Get information about a database table"
  ;; Stub - use SQLite PRAGMA or information_schema
  {})

(defn sync-models []
  "Ensure models are synchronized with database"
  ;; Stub - check and optionally create tables
  (print "Synchronizing models with database...")
  (for [model [User UserProfile]]
    (print f"  Checking {model._table}...")))
