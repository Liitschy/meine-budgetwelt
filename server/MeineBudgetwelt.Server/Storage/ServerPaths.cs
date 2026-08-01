namespace MeineBudgetwelt.Server.Storage;

public sealed record ServerPaths(
    string RootDirectory,
    string DataDirectory,
    string BackupDirectory,
    string LogDirectory,
    string DatabasePath)
{
    private const string DataDirectoryEnvironmentVariable = "BUDGETWELT_DATA_DIR";

    public static ServerPaths Create()
    {
        var configuredRoot = Environment.GetEnvironmentVariable(
            DataDirectoryEnvironmentVariable);
        var rootDirectory = string.IsNullOrWhiteSpace(configuredRoot)
            ? Path.Combine(
                Environment.GetFolderPath(
                    Environment.SpecialFolder.CommonApplicationData),
                "Meine Budgetwelt Server")
            : configuredRoot;

        rootDirectory = Path.GetFullPath(rootDirectory);
        EnsureDedicatedRoot(rootDirectory);

        var dataDirectory = Path.Combine(rootDirectory, "data");
        var backupDirectory = Path.Combine(rootDirectory, "backups");
        var logDirectory = Path.Combine(rootDirectory, "logs");

        Directory.CreateDirectory(dataDirectory);
        Directory.CreateDirectory(backupDirectory);
        Directory.CreateDirectory(logDirectory);

        return new ServerPaths(
            rootDirectory,
            dataDirectory,
            backupDirectory,
            logDirectory,
            Path.Combine(dataDirectory, "budgetwelt.sqlite3"));
    }

    private static void EnsureDedicatedRoot(string rootDirectory)
    {
        var volumeRoot = Path.GetPathRoot(rootDirectory);
        if (string.IsNullOrWhiteSpace(volumeRoot))
        {
            throw new InvalidOperationException(
                "Das Server-Datenverzeichnis muss ein absoluter Pfad sein.");
        }

        var normalizedRoot = rootDirectory.TrimEnd(
            Path.DirectorySeparatorChar,
            Path.AltDirectorySeparatorChar);
        var normalizedVolume = volumeRoot.TrimEnd(
            Path.DirectorySeparatorChar,
            Path.AltDirectorySeparatorChar);
        if (string.Equals(
            normalizedRoot,
            normalizedVolume,
            StringComparison.OrdinalIgnoreCase))
        {
            throw new InvalidOperationException(
                "Ein Laufwerksstamm darf nicht als Server-Datenverzeichnis verwendet werden.");
        }
    }
}
