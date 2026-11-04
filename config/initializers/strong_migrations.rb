# Mark existing migrations as safe.
StrongMigrations.start_after = 20261029105653

# Match the CI PostgreSQL version.
StrongMigrations.target_version = 16

StrongMigrations.lock_timeout = 10.seconds
StrongMigrations.statement_timeout = 1.hour

StrongMigrations.auto_analyze = true
