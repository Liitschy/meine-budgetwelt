using Microsoft.Data.Sqlite;

namespace MeineBudgetwelt.Server.Storage;

public sealed class SqliteStore(
    ServerPaths paths,
    ILogger<SqliteStore> logger)
{
    private readonly string _connectionString = new SqliteConnectionStringBuilder
    {
        DataSource = paths.DatabasePath,
        Mode = SqliteOpenMode.ReadWriteCreate,
        Cache = SqliteCacheMode.Shared,
        Pooling = true,
    }.ToString();

    public async Task InitializeAsync(CancellationToken cancellationToken = default)
    {
        await using var connection = await OpenConnectionAsync(cancellationToken);

        await ExecuteAsync(
            connection,
            """
            PRAGMA journal_mode = WAL;
            """,
            cancellationToken);

        await ExecuteAsync(
            connection,
            """
            CREATE TABLE IF NOT EXISTS schema_versions (
                version INTEGER PRIMARY KEY,
                applied_utc TEXT NOT NULL
            );

            INSERT OR IGNORE INTO schema_versions(version, applied_utc)
            VALUES (1, strftime('%Y-%m-%dT%H:%M:%fZ', 'now'));

            CREATE TABLE IF NOT EXISTS server_instance (
                singleton_id INTEGER PRIMARY KEY CHECK (singleton_id = 1),
                instance_id TEXT NOT NULL UNIQUE,
                created_utc TEXT NOT NULL
            );

            INSERT OR IGNORE INTO server_instance(
                singleton_id,
                instance_id,
                created_utc
            )
            VALUES (
                1,
                lower(hex(randomblob(16))),
                strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
            );
            """,
            cancellationToken);

        await ExecuteAsync(
            connection,
            """
            CREATE TABLE IF NOT EXISTS users (
                user_id TEXT PRIMARY KEY,
                display_name TEXT NOT NULL,
                email TEXT NOT NULL,
                email_normalized TEXT NOT NULL UNIQUE,
                password_hash TEXT NOT NULL,
                is_system_admin INTEGER NOT NULL DEFAULT 0,
                is_active INTEGER NOT NULL DEFAULT 1,
                created_utc TEXT NOT NULL,
                updated_utc TEXT NOT NULL
            );

            CREATE TABLE IF NOT EXISTS budget_groups (
                group_id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                created_by_user_id TEXT NOT NULL,
                created_utc TEXT NOT NULL,
                updated_utc TEXT NOT NULL,
                FOREIGN KEY(created_by_user_id) REFERENCES users(user_id)
            );

            CREATE TABLE IF NOT EXISTS budget_group_members (
                group_id TEXT NOT NULL,
                user_id TEXT NOT NULL,
                role TEXT NOT NULL CHECK(role IN ('owner', 'manager', 'member')),
                created_utc TEXT NOT NULL,
                PRIMARY KEY(group_id, user_id),
                FOREIGN KEY(group_id) REFERENCES budget_groups(group_id)
                    ON DELETE CASCADE,
                FOREIGN KEY(user_id) REFERENCES users(user_id)
                    ON DELETE CASCADE
            );

            CREATE TABLE IF NOT EXISTS sessions (
                session_id TEXT PRIMARY KEY,
                user_id TEXT NOT NULL,
                token_hash TEXT NOT NULL UNIQUE,
                created_utc TEXT NOT NULL,
                expires_utc TEXT NOT NULL,
                last_seen_utc TEXT NOT NULL,
                revoked_utc TEXT NULL,
                client_kind TEXT NOT NULL,
                user_agent TEXT NOT NULL,
                FOREIGN KEY(user_id) REFERENCES users(user_id)
                    ON DELETE CASCADE
            );

            CREATE INDEX IF NOT EXISTS idx_sessions_user
                ON sessions(user_id);
            CREATE INDEX IF NOT EXISTS idx_sessions_expiry
                ON sessions(expires_utc);

            INSERT OR IGNORE INTO schema_versions(version, applied_utc)
            VALUES (2, strftime('%Y-%m-%dT%H:%M:%fZ', 'now'));
            """,
            cancellationToken);

        await ExecuteAsync(
            connection,
            """
            CREATE TABLE IF NOT EXISTS invitations (
                invitation_id TEXT PRIMARY KEY,
                email TEXT NOT NULL,
                email_normalized TEXT NOT NULL,
                suggested_name TEXT NOT NULL,
                token_hash TEXT NOT NULL UNIQUE,
                group_id TEXT NULL,
                group_role TEXT NULL
                    CHECK(group_role IS NULL OR group_role IN ('owner', 'manager', 'member')),
                created_by_user_id TEXT NOT NULL,
                created_utc TEXT NOT NULL,
                expires_utc TEXT NOT NULL,
                accepted_utc TEXT NULL,
                revoked_utc TEXT NULL,
                FOREIGN KEY(group_id) REFERENCES budget_groups(group_id),
                FOREIGN KEY(created_by_user_id) REFERENCES users(user_id)
            );

            CREATE INDEX IF NOT EXISTS idx_invitations_email
                ON invitations(email_normalized);
            CREATE INDEX IF NOT EXISTS idx_invitations_expiry
                ON invitations(expires_utc);

            CREATE TABLE IF NOT EXISTS password_reset_tokens (
                reset_id TEXT PRIMARY KEY,
                user_id TEXT NOT NULL,
                token_hash TEXT NOT NULL UNIQUE,
                created_utc TEXT NOT NULL,
                expires_utc TEXT NOT NULL,
                used_utc TEXT NULL,
                revoked_utc TEXT NULL,
                FOREIGN KEY(user_id) REFERENCES users(user_id)
                    ON DELETE CASCADE
            );

            CREATE INDEX IF NOT EXISTS idx_password_reset_user
                ON password_reset_tokens(user_id);
            CREATE INDEX IF NOT EXISTS idx_password_reset_expiry
                ON password_reset_tokens(expires_utc);

            INSERT OR IGNORE INTO schema_versions(version, applied_utc)
            VALUES (3, strftime('%Y-%m-%dT%H:%M:%fZ', 'now'));
            """,
            cancellationToken);

        await ExecuteAsync(
            connection,
            """
            CREATE TABLE IF NOT EXISTS sync_documents (
                group_id TEXT PRIMARY KEY,
                revision INTEGER NOT NULL,
                document_json TEXT NOT NULL,
                document_sha256 TEXT NOT NULL,
                updated_by_user_id TEXT NOT NULL,
                updated_utc TEXT NOT NULL,
                device_id TEXT NOT NULL,
                FOREIGN KEY(group_id) REFERENCES budget_groups(group_id)
                    ON DELETE CASCADE,
                FOREIGN KEY(updated_by_user_id) REFERENCES users(user_id)
            );

            CREATE TABLE IF NOT EXISTS sync_revisions (
                group_id TEXT NOT NULL,
                revision INTEGER NOT NULL,
                document_json TEXT NOT NULL,
                document_sha256 TEXT NOT NULL,
                updated_by_user_id TEXT NOT NULL,
                updated_utc TEXT NOT NULL,
                device_id TEXT NOT NULL,
                PRIMARY KEY(group_id, revision),
                FOREIGN KEY(group_id) REFERENCES budget_groups(group_id)
                    ON DELETE CASCADE,
                FOREIGN KEY(updated_by_user_id) REFERENCES users(user_id)
            );

            CREATE INDEX IF NOT EXISTS idx_sync_revisions_updated
                ON sync_revisions(group_id, updated_utc DESC);

            INSERT OR IGNORE INTO schema_versions(version, applied_utc)
            VALUES (4, strftime('%Y-%m-%dT%H:%M:%fZ', 'now'));
            """,
            cancellationToken);

        await ExecuteAsync(
            connection,
            """
            CREATE TABLE IF NOT EXISTS bank_connections (
                connection_id TEXT PRIMARY KEY,
                group_id TEXT NOT NULL,
                created_by_user_id TEXT NOT NULL,
                provider TEXT NOT NULL CHECK(provider = 'gocardless-bad'),
                requisition_id TEXT NOT NULL UNIQUE,
                institution_id TEXT NOT NULL,
                institution_name TEXT NOT NULL,
                status TEXT NOT NULL,
                account_ids_json TEXT NOT NULL DEFAULT '[]',
                created_utc TEXT NOT NULL,
                updated_utc TEXT NOT NULL,
                last_refresh_utc TEXT NULL,
                FOREIGN KEY(group_id) REFERENCES budget_groups(group_id)
                    ON DELETE CASCADE,
                FOREIGN KEY(created_by_user_id) REFERENCES users(user_id)
                    ON DELETE CASCADE
            );

            CREATE INDEX IF NOT EXISTS idx_bank_connections_group
                ON bank_connections(group_id, created_utc DESC);

            INSERT OR IGNORE INTO schema_versions(version, applied_utc)
            VALUES (5, strftime('%Y-%m-%dT%H:%M:%fZ', 'now'));
            """,
            cancellationToken);

        logger.LogInformation(
            "Isolierte Budgetwelt-Datenbank initialisiert: {DatabasePath}",
            paths.DatabasePath);
    }

    public async Task<SqliteConnection> OpenConnectionAsync(
        CancellationToken cancellationToken = default)
    {
        var connection = new SqliteConnection(_connectionString);
        try
        {
            await connection.OpenAsync(cancellationToken);
            await ExecuteAsync(
                connection,
                """
                PRAGMA foreign_keys = ON;
                PRAGMA busy_timeout = 5000;
                """,
                cancellationToken);
            return connection;
        }
        catch
        {
            await connection.DisposeAsync();
            throw;
        }
    }

    public async Task<DatabaseHealth> CheckHealthAsync(
        CancellationToken cancellationToken = default)
    {
        try
        {
            await using var connection = await OpenConnectionAsync(
                cancellationToken);

            await using var command = connection.CreateCommand();
            command.CommandText =
                "SELECT COUNT(*) FROM schema_versions WHERE version IN (1, 2, 3, 4, 5);";
            var result = await command.ExecuteScalarAsync(cancellationToken);
            return Convert.ToInt64(result) == 5
                ? DatabaseHealth.Healthy()
                : DatabaseHealth.Unhealthy("Schema-Version fehlt.");
        }
        catch (Exception exception)
        {
            logger.LogError(exception, "Datenbank-Gesundheitsprüfung fehlgeschlagen.");
            return DatabaseHealth.Unhealthy("Datenbank nicht erreichbar.");
        }
    }

    private static async Task ExecuteAsync(
        SqliteConnection connection,
        string sql,
        CancellationToken cancellationToken)
    {
        await using var command = connection.CreateCommand();
        command.CommandText = sql;
        await command.ExecuteNonQueryAsync(cancellationToken);
    }
}

public sealed record DatabaseHealth(bool IsHealthy, string Error)
{
    public static DatabaseHealth Healthy() => new(true, string.Empty);

    public static DatabaseHealth Unhealthy(string error) => new(false, error);
}
