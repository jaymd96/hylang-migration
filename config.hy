;;; config.hy - Configuration for migration tool

(import os)
(import pathlib [Path])

;; Database configuration
(setv DATABASE {
  :path (os.getenv "DB_PATH" "database.db")
  :type "sqlite"
  :connection-string None  ; Will be built from path
})

;; Migration settings
(setv MIGRATIONS {
  :directory (Path "migrations")
  :table-name "migration_history"
  :auto-transaction True
  :verify-checksums True
})

;; SQLObject configuration
(setv SQLOBJECT {
  :debug False
  :cache True
  :lazy-update True
})

(defn get-connection-string []
  "Build SQLObject connection string"
  (if (= (get DATABASE :type) "sqlite")
    f"sqlite:{(get DATABASE :path)}"
    (get DATABASE :connection-string)))

(defn init-config [&optional [config-file None]]
  "Initialize configuration from file or environment"
  (when config-file
    ;; Stub - load from config file
    (print f"Loading config from: {config-file}"))
  
  ;; Set up SQLObject connection
  (setv (get DATABASE :connection-string) (get-connection-string))
  
  ;; Ensure migrations directory exists
  (when (not (.exists (get MIGRATIONS :directory)))
    (.mkdir (get MIGRATIONS :directory) :parents True)))

;; Logging configuration
(setv LOGGING {
  :level "INFO"
  :format "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
  :file None  ; Set to path for file logging
})
