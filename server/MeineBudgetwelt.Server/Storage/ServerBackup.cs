using System.Text.Json;

namespace MeineBudgetwelt.Server.Storage;

public static class ServerBackup
{
    public static string Create(ServerPaths paths)
    {
        var backupName = DateTimeOffset.UtcNow.ToString("yyyyMMdd-HHmmss-fff")
            + "-"
            + Guid.NewGuid().ToString("N")[..8];
        var destination = Path.Combine(paths.BackupDirectory, backupName);
        Directory.CreateDirectory(destination);

        CopyIfPresent(paths.DatabasePath, destination);
        CopyIfPresent(paths.DatabasePath + "-wal", destination);
        CopyIfPresent(paths.DatabasePath + "-shm", destination);
        CopyIfPresent(
            Path.Combine(paths.RootDirectory, "appsettings.json"),
            destination);

        var manifest = new
        {
            createdUtc = DateTimeOffset.UtcNow,
            database = Path.GetFileName(paths.DatabasePath),
            purpose = "server-update-safety-backup",
        };
        File.WriteAllText(
            Path.Combine(destination, "backup-manifest.json"),
            JsonSerializer.Serialize(
                manifest,
                new JsonSerializerOptions { WriteIndented = true }));

        return destination;
    }

    private static void CopyIfPresent(string sourcePath, string destination)
    {
        if (!File.Exists(sourcePath))
        {
            return;
        }

        File.Copy(
            sourcePath,
            Path.Combine(destination, Path.GetFileName(sourcePath)),
            overwrite: false);
    }
}
