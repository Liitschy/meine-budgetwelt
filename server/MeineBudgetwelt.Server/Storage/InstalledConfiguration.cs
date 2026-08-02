using System.Text;
using System.Text.Json;
using System.Text.Json.Nodes;

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
            UpgradeExistingConfiguration(configurationPath);
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
            LocalAi = new
            {
                Enabled = true,
                Endpoint = "http://127.0.0.1:11434/api/chat",
                Model = "qwen3.5:4b",
                ContextTokens = 16_384,
                TimeoutSeconds = 300,
                KeepAlive = "30m",
            },
            GoCardless = new
            {
                Enabled = false,
                BaseUrl = "https://bankaccountdata.gocardless.com/api/v2/",
                RedirectBaseUrl = "https://budget.leno.info",
                DefaultCountry = "DE",
                SandboxMode = false,
                TimeoutSeconds = 45,
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

    private static void UpgradeExistingConfiguration(string configurationPath)
    {
        var configuration = JsonNode.Parse(
            File.ReadAllText(configurationPath, Encoding.UTF8)) as JsonObject
            ?? throw new InvalidOperationException(
                "Die bestehende Serverkonfiguration ist kein gültiges JSON-Objekt.");
        var changed = false;

        if (!configuration.ContainsKey("LocalAi"))
        {
            configuration["LocalAi"] = new JsonObject
            {
                ["Enabled"] = true,
                ["Endpoint"] = "http://127.0.0.1:11434/api/chat",
                ["Model"] = "qwen3.5:4b",
                ["ContextTokens"] = 16_384,
                ["TimeoutSeconds"] = 300,
                ["KeepAlive"] = "30m",
            };
            changed = true;
        }

        if (!configuration.ContainsKey("GoCardless"))
        {
            configuration["GoCardless"] = new JsonObject
            {
                ["Enabled"] = false,
                ["BaseUrl"] = "https://bankaccountdata.gocardless.com/api/v2/",
                ["RedirectBaseUrl"] = "https://budget.leno.info",
                ["DefaultCountry"] = "DE",
                ["SandboxMode"] = false,
                ["TimeoutSeconds"] = 45,
            };
            changed = true;
        }

        if (!changed)
        {
            return;
        }

        var temporaryPath = configurationPath + ".new";
        var backupPath = configurationPath
            + ".before-integration-migration-"
            + DateTimeOffset.UtcNow.ToString("yyyyMMdd-HHmmssfff");
        var json = configuration.ToJsonString(
            new JsonSerializerOptions { WriteIndented = true });
        File.WriteAllText(
            temporaryPath,
            json + Environment.NewLine,
            new UTF8Encoding(encoderShouldEmitUTF8Identifier: false));
        File.Replace(temporaryPath, configurationPath, backupPath);
    }
}
