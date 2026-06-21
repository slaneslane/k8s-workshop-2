import glob
import os
import time

import psycopg


DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql://workshop:workshop@postgres:5432/workshop",
)
MIGRATIONS_DIR = os.getenv("MIGRATIONS_DIR", "/migrations/sql")

MAX_RETRIES = int(os.getenv("DB_CONNECT_RETRIES", "30"))
RETRY_DELAY_SECONDS = int(os.getenv("DB_CONNECT_RETRY_DELAY_SECONDS", "2"))


def connect_to_database() -> psycopg.Connection:
    """Connect to PostgreSQL, retrying while the database becomes ready."""

    for attempt in range(1, MAX_RETRIES + 1):
        try:
            connection = psycopg.connect(
                DATABASE_URL,
                connect_timeout=5,
            )
            print(f"Database connection established on attempt {attempt}.")
            return connection
        except psycopg.OperationalError as exc:
            if attempt == MAX_RETRIES:
                raise RuntimeError(
                    f"Database did not become ready after {MAX_RETRIES} attempts."
                ) from exc

            print(
                "Database is not ready yet "
                f"(attempt {attempt}/{MAX_RETRIES}): {exc}"
            )
            time.sleep(RETRY_DELAY_SECONDS)

    raise RuntimeError("Unexpected database connection retry failure.")


def apply_migrations(connection: psycopg.Connection) -> None:
    """Apply each migration once and record it in schema_migrations."""

    with connection:
        with connection.cursor() as cursor:
            cursor.execute(
                """
                CREATE TABLE IF NOT EXISTS schema_migrations (
                    version TEXT PRIMARY KEY,
                    applied_at TIMESTAMPTZ DEFAULT NOW()
                )
                """
            )

            for path in sorted(glob.glob(f"{MIGRATIONS_DIR}/*.sql")):
                version = os.path.basename(path)

                cursor.execute(
                    "SELECT 1 FROM schema_migrations WHERE version = %s",
                    (version,),
                )

                if cursor.fetchone():
                    print(f"Skip {version}: already applied.")
                    continue

                print(f"Apply {version}")

                with open(path, encoding="utf-8") as migration_file:
                    cursor.execute(migration_file.read())

                cursor.execute(
                    "INSERT INTO schema_migrations(version) VALUES (%s)",
                    (version,),
                )

                connection.commit()


def main() -> None:
    connection = connect_to_database()

    try:
        apply_migrations(connection)
    finally:
        connection.close()

    print("Migrations completed.")


if __name__ == "__main__":
    main()
