using System.Text.Json;

namespace MeineBudgetwelt.Server.Sync;

public sealed record SyncGroupSummary(
    string Id,
    string Name,
    string Role,
    long Revision,
    DateTimeOffset? UpdatedUtc);

public sealed record SyncSnapshot(
    string GroupId,
    long Revision,
    JsonElement? Data,
    string Sha256,
    string UpdatedByUserId,
    DateTimeOffset? UpdatedUtc,
    string DeviceId);

public sealed record PutSyncSnapshotRequest(
    long BaseRevision,
    JsonElement Data,
    string DeviceId);

public sealed class SyncValidationException(string message)
    : Exception(message);

public sealed class SyncAccessDeniedException()
    : Exception("Kein Zugriff auf diese Budgetgruppe.");

public sealed class SyncConflictException(SyncSnapshot current)
    : Exception("Der Server enthält bereits einen neueren Datenstand.")
{
    public SyncSnapshot Current { get; } = current;
}
