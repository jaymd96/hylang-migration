;;; setup.hy - Pure Hylang setup script for pip installation
;;; This replaces setup.py with pure Hylang code

(import setuptools [setup find-packages])
(import pathlib [Path])

(defn read-file [filename]
  "Read file contents for long description"
  (-> (Path filename)
      (.read-text :encoding "utf-8")))

(defn main []
  "Main setup function"
  (setup
    :name "hylang-migrations"
    :version "0.1.0"
    :author "Your Name"
    :author-email "your.email@example.com"
    :description "Pure Hylang schema migration tool for SQLite with SQLObject"
    :long-description (read-file "README.md")
    :long-description-content-type "text/markdown"
    :url "https://github.com/yourusername/hylang-migrations"
    :packages (find-packages :where "src")
    :package-dir {"" "src"}
    :package-data {"hylang_migrations" ["*.hy" "templates/*.hy"]}
    :include-package-data True
    :python-requires ">=3.8"
    :install-requires [
      "hy>=1.0.0"
      "hyrule>=0.6.0"
      "sqlobject>=3.10.1"
      "colorama>=0.4.6"
      "python-dotenv>=1.0.0"
      "tabulate>=0.9.0"
    ]
    :extras-require {
      "dev" [
        "pytest>=7.4.0"
        "pytest-cov>=4.1.0"
      ]
    }
    :entry-points {
      "console_scripts" [
        "hylang-migrate=hylang_migrations.cli:main"
        "hy-migrate=hylang_migrations.cli:main"
      ]
    }
    :classifiers [
      "Development Status :: 4 - Beta"
      "Intended Audience :: Developers"
      "Topic :: Database"
      "License :: OSI Approved :: MIT License"
      "Programming Language :: Lisp"
      "Programming Language :: Python :: 3"
      "Programming Language :: Python :: 3.8"
      "Programming Language :: Python :: 3.9"
      "Programming Language :: Python :: 3.10"
      "Programming Language :: Python :: 3.11"
    ]
    :keywords "hylang lisp migrations database sqlite sqlobject schema"))

(when (= __name__ "__main__")
  (main))
