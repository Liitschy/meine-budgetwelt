using System.Globalization;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using MeineBudgetwelt.Server.Storage;
using Microsoft.Data.Sqlite;

namespace MeineBudgetwelt.Server.Sync;

public sealed class SyncService(SqliteStore store)
{
    private const int MaximumDocumentBytes = 2 * 1024 * 1024;
    private static readonly IReadOnlyDictionary<string, JsonValueKind>
        AllowedFiles = new Dictionary<string, JsonValueKind>(
            StringComparer.Ordinal)
        {
            ["budget_data.json"] = JsonValueKind.Object,
            ["fixed_costs.json"] = JsonValueKind.Array,
            ["month_history.json"] = JsonValueKind.Object,
            ["savings_goals.json"] = JsonValueKind.Array,
            ["transactions.json"] = JsonValueKind.Object,
            ["shopping.json"] = JsonValueKind.Object,
            ["meal_plans.json"] = JsonValueKind.Object,
            ["custom_recipes.json"] = JsonValueKind.Array,
        };

    public async Task<IReadOnlyList<SyncGroupSummary>> ListGroupsAsync(
        string userId,
        CancellationToken cancellationToken = default)
    {
        var groups = new List<SyncGroupSummary>();
        await using var connection = await store.OpenConnectionAsync(
            cancellationToken);
        await using var command = connection.CreateCommand();
        command.CommandText =
            """
            SELECT
                g.group_id,
                g.name,
                m.role,
                COALESCE(d.revision, 0),
                d.updated_utc
            FROM budget_group_members m
            INNER JOIN budget_groups g ON g.group_id = m.group_id
            LEFT JOIN sync_documents d ON d.group_id = g.group_id
            WHERE m.user_id = $user_id
            ORDER BY g.name COLLATE NOCASE;
            """;
        command.Parameters.AddWithValue("$user_id", userId);
        await using var reader = await command.ExecuteReaderAsync(
            cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            groups.Add(new SyncGroupSummary(
                reader.GetString(0),
                reader.GetString(1),
                reader.GetString(2),
                reader.GetInt64(3),
                reader.IsDBNull(4)
                    ? null
                    : DateTimeOffset.Parse(
                        reader.GetString(4),
                        CultureInfo.InvariantCulture)));
        }
        return groups;
    }

    public async Task<SyncSnapshot> GetSnapshotAsync(
        string groupId,
        string userId,
        CancellationToken cancellationToken = default)
    {
        await using var connection = await store.OpenConnectionAsync(
            cancellationToken);
        await EnsureMembershipAsync(
            connection,
            groupId,
            userId,
            cancellationToken);
        return await ReadSnapshotAsync(
            connection,
            groupId,
            cancellationToken);
    }

    public async Task<SyncSnapshot> PutSnapshotAsync(
        string groupId,
        string userId,
        PutSyncSnapshotRequest request,
        CancellationToken cancellationToken = default)
    {
        if (request.BaseRevision < 0)
        {
            throw new SyncValidationException(
                "Die Ausgangsrevision darf nicht negativ sein.");
        }
        var deviceId = ValidateDeviceId(request.DeviceId);
        var documentJson = ValidateAndSerializeDocument(request.Data);
        var sha256 = Convert.ToHexString(
            SHA256.HashData(Encoding.UTF8.GetBytes(documentJson)));
        var now = DateTimeOffset.UtcNow;
        var nowText = now.ToString("O", CultureInfo.InvariantCulture);

        await using var connection = await store.OpenConnectionAsync(
            cancellationToken);
        await using var transaction = await connection.BeginTransactionAsync(
            cancellationToken);
        await EnsureMembershipAsync(
            connection,
            groupId,
            userId,
            cancellationToken,
            (SqliteTransaction)transaction);

        var current = await ReadSnapshotAsync(
            connection,
            groupId,
            cancellationToken,
            (SqliteTransaction)transaction);
        if (current.Revision != request.BaseRevision)
        {
            throw new SyncConflictException(current);
        }

        var nextRevision = current.Revision + 1;
        await using var command = connection.CreateCommand();
        command.Transaction = (SqliteTransaction)transaction;
        command.CommandText =
            """
            INSERT INTO sync_revisions(
                group_id,
                revision,
                document_json,
                document_sha256,
                updated_by_user_id,
                updated_utc,
                device_id
            )
            VALUES (
                $group_id,
                $revision,
                $document_json,
                $sha256,
                $user_id,
                $updated_utc,
                $device_id
            );

            INSERT INTO sync_documents(
                group_id,
                revision,
                document_json,
                document_sha256,
                updated_by_user_id,
                updated_utc,
                device_id
            )
            VALUES (
                $group_id,
                $revision,
                $document_json,
                $sha256,
                $user_id,
                $updated_utc,
                $device_id
            )
            ON CONFLICT(group_id)
            DO UPDATE SET
                revision = excluded.revision,
                document_json = excluded.document_json,
                document_sha256 = excluded.document_sha256,
                updated_by_user_id = excluded.updated_by_user_id,
                updated_utc = excluded.updated_utc,
                device_id = excluded.device_id;
            """;
        command.Parameters.AddWithValue("$group_id", groupId);
        command.Parameters.AddWithValue("$revision", nextRevision);
        command.Parameters.AddWithValue("$document_json", documentJson);
        command.Parameters.AddWithValue("$sha256", sha256);
        command.Parameters.AddWithValue("$user_id", userId);
        command.Parameters.AddWithValue("$updated_utc", nowText);
        command.Parameters.AddWithValue("$device_id", deviceId);
        try
        {
            await command.ExecuteNonQueryAsync(cancellationToken);
            await transaction.CommitAsync(cancellationToken);
        }
        catch (SqliteException exception) when (
            exception.SqliteErrorCode is 5 or 19)
        {
            await transaction.RollbackAsync(cancellationToken);
            var latest = await ReadSnapshotAsync(
                connection,
                groupId,
                cancellationToken);
            throw new SyncConflictException(latest);
        }

        using var parsed = JsonDocument.Parse(documentJson);
        return new SyncSnapshot(
            groupId,
            nextRevision,
            parsed.RootElement.Clone(),
            sha256,
            userId,
            now,
            deviceId);
    }

    private static async Task EnsureMembershipAsync(
        SqliteConnection connection,
        string groupId,
        string userId,
        CancellationToken cancellationToken,
        SqliteTransaction? transaction = null)
    {
        await using var command = connection.CreateCommand();
        command.Transaction = transaction;
        command.CommandText =
            """
            SELECT COUNT(*)
            FROM budget_group_members m
            INNER JOIN users u ON u.user_id = m.user_id
            WHERE m.group_id = $group_id
              AND m.user_id = $user_id
              AND u.is_active = 1;
            """;
        command.Parameters.AddWithValue("$group_id", groupId);
        command.Parameters.AddWithValue("$user_id", userId);
        if (Convert.ToInt64(
            await command.ExecuteScalarAsync(cancellationToken),
            CultureInfo.InvariantCulture) != 1)
        {
            throw new SyncAccessDeniedException();
        }
    }

    private static async Task<SyncSnapshot> ReadSnapshotAsync(
        SqliteConnection connection,
        string groupId,
        CancellationToken cancellationToken,
        SqliteTransaction? transaction = null)
    {
        await using var command = connection.CreateCommand();
        command.Transaction = transaction;
        command.CommandText =
            """
            SELECT
                revision,
                document_json,
                document_sha256,
                updated_by_user_id,
                updated_utc,
                device_id
            FROM sync_documents
            WHERE group_id = $group_id
            LIMIT 1;
            """;
        command.Parameters.AddWithValue("$group_id", groupId);
        await using var reader = await command.ExecuteReaderAsync(
            cancellationToken);
        if (!await reader.ReadAsync(cancellationToken))
        {
            return new SyncSnapshot(
                groupId,
                0,
                null,
                string.Empty,
                string.Empty,
                null,
                string.Empty);
        }

        using var document = JsonDocument.Parse(reader.GetString(1));
        return new SyncSnapshot(
            groupId,
            reader.GetInt64(0),
            document.RootElement.Clone(),
            reader.GetString(2),
            reader.GetString(3),
            DateTimeOffset.Parse(
                reader.GetString(4),
                CultureInfo.InvariantCulture),
            reader.GetString(5));
    }

    private static string ValidateAndSerializeDocument(JsonElement data)
    {
        if (data.ValueKind != JsonValueKind.Object)
        {
            throw new SyncValidationException(
                "Der Synchronisationsstand muss ein Objekt sein.");
        }
        if (
            !data.TryGetProperty("schemaVersion", out var schemaVersion)
            || schemaVersion.ValueKind != JsonValueKind.Number
            || !schemaVersion.TryGetInt32(out var version)
            || version != 1
        )
        {
            throw new SyncValidationException(
                "Die Synchronisationsversion wird nicht unterstützt.");
        }
        if (
            !data.TryGetProperty("files", out var files)
            || files.ValueKind != JsonValueKind.Object
        )
        {
            throw new SyncValidationException(
                "Der Synchronisationsstand enthält keine Dateien.");
        }

        foreach (var file in files.EnumerateObject())
        {
            if (
                !AllowedFiles.TryGetValue(file.Name, out var requiredKind)
                || file.Value.ValueKind != requiredKind
            )
            {
                throw new SyncValidationException(
                    "Der Synchronisationsstand enthält eine ungültige Datendatei.");
            }
        }

        foreach (var requiredFile in AllowedFiles.Keys)
        {
            if (!files.TryGetProperty(requiredFile, out _))
            {
                throw new SyncValidationException(
                    "Der Synchronisationsstand ist unvollständig.");
            }
        }

        var documentJson = data.GetRawText();
        if (Encoding.UTF8.GetByteCount(documentJson) > MaximumDocumentBytes)
        {
            throw new SyncValidationException(
                "Der Synchronisationsstand ist größer als 2 MB.");
        }
        return documentJson;
    }

    private static string ValidateDeviceId(string deviceId)
    {
        var trimmed = deviceId?.Trim() ?? string.Empty;
        if (trimmed.Length is < 8 or > 100)
        {
            throw new SyncValidationException(
                "Die Gerätekennung ist ungültig.");
        }
        foreach (var character in trimmed)
        {
            if (
                !char.IsAsciiLetterOrDigit(character)
                && character is not ('-' or '_')
            )
            {
                throw new SyncValidationException(
                    "Die Gerätekennung ist ungültig.");
            }
        }
        return trimmed;
    }
}
