using System.Text;
using System.Text.Json;

namespace MeineBudgetwelt.Server.Storage;

public static class InstalledConfiguration
{
    public static string Create(ServerPaths paths, int port)
    {
        var configurationPath = Path.Combine(
            paths.RootDirectory,
            "appsettings.json");
        if (File.Exists(configurationPath))
        {
            return configurationPath;
        }

        var configuration = new
        {
            Server = new
            {
                ListenUrl = $"http://127.0.0.1:{port}",
                PwaRoot = "pwa",
            },
            Email = new
            {
                Host = string.Empty,
                Port = 587,
                Username = string.Empty,
                FromAddress = string.Empty,
                FromName = "Meine Budgetwelt",
                Security = "StartTls",
                PublicBaseUrl = "https://budget.leno.info",
            },
            Updates = new
            {
                Enabled = true,
                ManifestUrl = "https://github.com/unique1986/meine-budgetwelt/releases/download/server-updates/server-update-manifest.json",
            },
            Logging = new
            {
                LogLevel = new Dictionary<string, string>
                {
                    ["Default"] = "Information",
                    ["Microsoft.AspNetCore"] = "Warning",
                },
            },
            AllowedHosts = "budget.leno.info;127.0.0.1;localhost",
        };
        var json = JsonSerializer.Serialize(
            configuration,
            new JsonSerializerOptions { WriteIndented = true });

        using var stream = new FileStream(
            configurationPath,
            FileMode.CreateNew,
            FileAccess.Write,
            FileShare.None);
        using var writer = new StreamWriter(
            stream,
            new UTF8Encoding(encoderShouldEmitUTF8Identifier: false));
        writer.WriteLine(json);
        return configurationPath;
    }
}
