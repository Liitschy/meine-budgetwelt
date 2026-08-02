using System.Reflection;
using System.Net;
using System.Threading.RateLimiting;
using MeineBudgetwelt.Server.Accounts;
using MeineBudgetwelt.Server.Banking;
using MeineBudgetwelt.Server.Planning;
using MeineBudgetwelt.Server.Storage;
using MeineBudgetwelt.Server.Sync;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.HttpOverrides;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.AspNetCore.StaticFiles;
using Microsoft.Extensions.FileProviders;

const string serviceName = "MeineBudgetweltServer";
const string defaultListenUrl = "http://127.0.0.1:48732";

var commandName = args.Length > 0 ? args[0] : string.Empty;
var bootstrapAdmin = string.Equals(
    commandName,
    "bootstrap-admin",
    StringComparison.OrdinalIgnoreCase);
var checkPort = string.Equals(
    commandName,
    "check-port",
    StringComparison.OrdinalIgnoreCase);
var createBackup = string.Equals(
    commandName,
    "backup",
    StringComparison.OrdinalIgnoreCase);
var initializeConfiguration = string.Equals(
    commandName,
    "initialize-config",
    StringComparison.OrdinalIgnoreCase);
var commandMode = bootstrapAdmin
    || checkPort
    || createBackup
    || initializeConfiguration;

if (checkPort)
{
    var commandOptions = ParseCommandOptions(args.Skip(1));
    var port = ParsePortOption(commandOptions, "Portprüfung");

    try
    {
        var listener = new System.Net.Sockets.TcpListener(IPAddress.Loopback, port);
        listener.Start();
        listener.Stop();
        Console.WriteLine("Port {0} ist auf 127.0.0.1 verfügbar.", port);
        return;
    }
    catch (System.Net.Sockets.SocketException)
    {
        Console.Error.WriteLine("Port {0} ist auf 127.0.0.1 bereits belegt.", port);
        Environment.ExitCode = 2;
        return;
    }
}

var paths = ServerPaths.Create();
if (initializeConfiguration)
{
    var commandOptions = ParseCommandOptions(args.Skip(1));
    var port = ParsePortOption(commandOptions, "Konfigurationsanlage");
    var configurationPath = InstalledConfiguration.Create(paths, port);
    Console.WriteLine("Serverkonfiguration bereit: {0}", configurationPath);
    return;
}
if (createBackup)
{
    var backupPath = ServerBackup.Create(paths);
    Console.WriteLine("Serversicherung erstellt: {0}", backupPath);
    return;
}

var builder = WebApplication.CreateBuilder(commandMode ? [] : args);
builder.Configuration.AddJsonFile(
    Path.Combine(paths.RootDirectory, "appsettings.json"),
    optional: true,
    reloadOnChange: !commandMode);
builder.Host.UseWindowsService(options => options.ServiceName = serviceName);
builder.WebHost.ConfigureKestrel(options => options.AddServerHeader = false);
builder.WebHost.ConfigureKestrel(options =>
    options.Limits.MaxRequestBodySize = 3 * 1024 * 1024);

var configuredListenUrl = builder.Configuration["Server:ListenUrl"];
var listenUrl = string.IsNullOrWhiteSpace(configuredListenUrl)
    ? defaultListenUrl
    : configuredListenUrl.Trim();
ValidateLoopbackListenUrl(listenUrl);
builder.WebHost.UseUrls(listenUrl);

builder.Services.AddSingleton(paths);
builder.Services.AddSingleton<SqliteStore>();
builder.Services.AddSingleton<IPasswordHasher<UserAccount>, PasswordHasher<UserAccount>>();
builder.Services.Configure<AccountEmailOptions>(
    builder.Configuration.GetSection("Email"));
builder.Services.AddSingleton<IAccountEmailSender, AccountEmailSender>();
builder.Services.AddSingleton<AccountService>();
builder.Services.AddSingleton<SyncService>();
builder.Services.Configure<LocalAiPlanningOptions>(
    builder.Configuration.GetSection("LocalAi"));
builder.Services.AddSingleton<WeeklyPlanningValidator>();
builder.Services.AddHttpClient<LocalAiWeeklyPlanningService>();
builder.Services.Configure<EnableBankingOptions>(
    builder.Configuration.GetSection("EnableBanking"));
builder.Services.AddHttpClient<EnableBankingClient>();
builder.Services.AddSingleton<BankingService>();
builder.Services.Configure<ForwardedHeadersOptions>(options =>
{
    options.ForwardedHeaders =
        ForwardedHeaders.XForwardedFor | ForwardedHeaders.XForwardedProto;
    options.ForwardLimit = 1;
    options.KnownProxies.Add(IPAddress.Loopback);
    options.KnownProxies.Add(IPAddress.IPv6Loopback);
});
builder.Services.AddRateLimiter(options =>
{
    options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
    options.AddPolicy(
        "login",
        context => RateLimitPartition.GetFixedWindowLimiter(
            context.Connection.RemoteIpAddress?.ToString() ?? "unknown",
            _ => new FixedWindowRateLimiterOptions
            {
                PermitLimit = 5,
                Window = TimeSpan.FromMinutes(1),
                QueueLimit = 0,
                AutoReplenishment = true,
            }));
    options.AddPolicy(
        "account-flow",
        context => RateLimitPartition.GetFixedWindowLimiter(
            context.Connection.RemoteIpAddress?.ToString() ?? "unknown",
            _ => new FixedWindowRateLimiterOptions
            {
                PermitLimit = 5,
                Window = TimeSpan.FromMinutes(1),
                QueueLimit = 0,
                AutoReplenishment = true,
            }));
    options.AddPolicy(
        "ai-planning",
        context => RateLimitPartition.GetFixedWindowLimiter(
            context.Connection.RemoteIpAddress?.ToString() ?? "unknown",
            _ => new FixedWindowRateLimiterOptions
            {
                PermitLimit = 4,
                Window = TimeSpan.FromMinutes(10),
                QueueLimit = 0,
                AutoReplenishment = true,
            }));
    options.AddPolicy(
        "banking",
        context => RateLimitPartition.GetFixedWindowLimiter(
            context.Connection.RemoteIpAddress?.ToString() ?? "unknown",
            _ => new FixedWindowRateLimiterOptions
            {
                PermitLimit = 20,
                Window = TimeSpan.FromMinutes(10),
                QueueLimit = 0,
                AutoReplenishment = true,
            }));
});

var app = builder.Build();
var store = app.Services.GetRequiredService<SqliteStore>();
var bankProvider = app.Services.GetRequiredService<EnableBankingClient>();
await store.InitializeAsync();

if (bootstrapAdmin)
{
    var commandOptions = ParseCommandOptions(args.Skip(1));
    var password = Environment.GetEnvironmentVariable(
        "BUDGETWELT_BOOTSTRAP_PASSWORD");
    Environment.SetEnvironmentVariable("BUDGETWELT_BOOTSTRAP_PASSWORD", null);

    if (
        !commandOptions.TryGetValue("name", out var name)
        || !commandOptions.TryGetValue("email", out var email)
        || string.IsNullOrWhiteSpace(password)
    )
    {
        throw new InvalidOperationException(
            "Bootstrap benötigt --name, --email und BUDGETWELT_BOOTSTRAP_PASSWORD.");
    }

    var accountService = app.Services.GetRequiredService<AccountService>();
    var admin = await accountService.CreateBootstrapAdminAsync(
        name,
        email,
        password);
    Console.WriteLine(
        "Erstes Administratorkonto wurde erstellt: {0} ({1})",
        admin.DisplayName,
        admin.Email);
    return;
}

app.UseForwardedHeaders();
app.UseRateLimiter();
app.Use(async (context, next) =>
{
    context.Response.Headers["X-Content-Type-Options"] = "nosniff";
    context.Response.Headers["X-Frame-Options"] = "DENY";
    context.Response.Headers["Referrer-Policy"] = "no-referrer";
    context.Response.Headers["Permissions-Policy"] =
        "camera=(), microphone=(), geolocation=(), payment=()";
    context.Response.Headers["Content-Security-Policy"] =
        "default-src 'self'; base-uri 'none'; frame-ancestors 'none'; "
        + "object-src 'none'; script-src 'self' 'unsafe-inline' 'wasm-unsafe-eval'; "
        + "style-src 'self' 'unsafe-inline'; img-src 'self' data: blob:; "
        + "connect-src 'self'; worker-src 'self' blob:; manifest-src 'self'";
    if (
        context.Request.Path.StartsWithSegments("/admin")
        || context.Request.Path.StartsWithSegments("/legal")
        || context.Request.Path == "/datenschutz"
        || context.Request.Path == "/nutzungsbedingungen"
    )
    {
        context.Response.Headers["Cache-Control"] =
            "no-cache, no-store, must-revalidate";
    }
    await next();
});

var adminUiRoot = Path.Combine(AppContext.BaseDirectory, "AdminUi");
var adminIndexPath = Path.Combine(adminUiRoot, "index.html");
if (!Directory.Exists(adminUiRoot) || !File.Exists(adminIndexPath))
{
    throw new InvalidOperationException(
        "Die Admin-Oberfläche fehlt im Serverpaket.");
}
var adminFiles = new PhysicalFileProvider(adminUiRoot);
app.UseStaticFiles(new StaticFileOptions
{
    FileProvider = adminFiles,
    RequestPath = "/admin",
    OnPrepareResponse = context =>
    {
        context.Context.Response.Headers["Cache-Control"] =
            "no-cache, no-store, must-revalidate";
    },
});

var legalUiRoot = Path.Combine(AppContext.BaseDirectory, "LegalUi");
var privacyPagePath = Path.Combine(legalUiRoot, "datenschutz.html");
var termsPagePath = Path.Combine(legalUiRoot, "nutzungsbedingungen.html");
if (
    !Directory.Exists(legalUiRoot)
    || !File.Exists(privacyPagePath)
    || !File.Exists(termsPagePath)
)
{
    throw new InvalidOperationException(
        "Die öffentlichen Datenschutz- und Nutzungsbedingungen fehlen im Serverpaket.");
}
var legalFiles = new PhysicalFileProvider(legalUiRoot);
app.UseStaticFiles(new StaticFileOptions
{
    FileProvider = legalFiles,
    RequestPath = "/legal",
    OnPrepareResponse = context =>
    {
        context.Context.Response.Headers["Cache-Control"] =
            "no-cache, no-store, must-revalidate";
    },
});

var configuredPwaRoot = builder.Configuration["Server:PwaRoot"]?.Trim();
string? pwaIndexPath = null;
if (!string.IsNullOrWhiteSpace(configuredPwaRoot))
{
    var pwaRoot = Path.GetFullPath(
        configuredPwaRoot,
        AppContext.BaseDirectory);
    if (!Directory.Exists(pwaRoot) || !File.Exists(Path.Combine(pwaRoot, "index.html")))
    {
        throw new InvalidOperationException(
            "Der konfigurierte PWA-Ordner fehlt oder enthält keine index.html.");
    }
    pwaIndexPath = Path.Combine(pwaRoot, "index.html");
    var pwaFiles = new PhysicalFileProvider(pwaRoot);
    var contentTypes = new FileExtensionContentTypeProvider();
    contentTypes.Mappings[".pck"] = "application/octet-stream";
    contentTypes.Mappings[".wasm"] = "application/wasm";
    contentTypes.Mappings[".webmanifest"] = "application/manifest+json";
    app.Use(async (context, next) =>
    {
        if (
            context.Request.Path == "/"
            || context.Request.Path == "/index.html"
            || context.Request.Path == "/index.service.worker.js"
        )
        {
            context.Response.Headers["Cache-Control"] =
                "no-cache, no-store, must-revalidate";
        }
        await next();
    });
    app.UseDefaultFiles(new DefaultFilesOptions
    {
        FileProvider = pwaFiles,
    });
    app.UseStaticFiles(new StaticFileOptions
    {
        FileProvider = pwaFiles,
        ContentTypeProvider = contentTypes,
        OnPrepareResponse = context =>
        {
            var fileName = context.File.Name;
            context.Context.Response.Headers["Cache-Control"] =
                fileName is "index.html" or "index.service.worker.js"
                    ? "no-cache, no-store, must-revalidate"
                    : "public, max-age=86400";
        },
    });
}

app.MapAccountEndpoints();
app.MapSyncEndpoints();
app.MapPlanningEndpoints();
app.MapBankingEndpoints();
app.MapGet("/admin", () => Results.File(adminIndexPath, "text/html"));
app.MapGet(
    "/datenschutz",
    () => Results.File(privacyPagePath, "text/html; charset=utf-8"));
app.MapGet(
    "/nutzungsbedingungen",
    () => Results.File(termsPagePath, "text/html; charset=utf-8"));

app.MapGet("/health", async (CancellationToken cancellationToken) =>
{
    var database = await store.CheckHealthAsync(cancellationToken);
    var automaticUpdates = builder.Configuration.GetValue<bool>("Updates:Enabled");
    var aiPlanningEnabled =
        builder.Configuration.GetValue<bool>("LocalAi:Enabled");
    var aiPlanningProvider = aiPlanningEnabled
        ? "local-ollama"
        : "disabled";
    var bankDataEnabled = bankProvider.IsConfigured;
    var version = Assembly.GetExecutingAssembly()
        .GetName()
        .Version?
        .ToString(3) ?? "0.0.0";

    return database.IsHealthy
        ? Results.Ok(new
        {
            status = "ok",
            service = serviceName,
            version,
            database = "ok",
            automaticUpdates,
            aiPlanningEnabled,
            aiPlanningProvider,
            bankDataEnabled,
            utc = DateTimeOffset.UtcNow,
        })
        : Results.Json(
            new
            {
                status = "unhealthy",
                service = serviceName,
                version,
                database = database.Error,
                automaticUpdates,
                aiPlanningEnabled,
                bankDataEnabled,
                utc = DateTimeOffset.UtcNow,
            },
            statusCode: StatusCodes.Status503ServiceUnavailable);
});

if (pwaIndexPath is not null)
{
    app.MapGet("/", () => Results.File(pwaIndexPath, "text/html"));
}
else
{
    app.MapGet("/", () => Results.NotFound(new
    {
        message = "Meine Budgetwelt Server",
        admin = "Die geschützte Admin-Oberfläche wird im nächsten Ausbauschritt aktiviert.",
    }));
}

await app.RunAsync();

static Dictionary<string, string> ParseCommandOptions(IEnumerable<string> arguments)
{
    var values = arguments.ToArray();
    var options = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
    for (var index = 0; index < values.Length; index += 2)
    {
        if (
            !values[index].StartsWith("--", StringComparison.Ordinal)
            || index + 1 >= values.Length
        )
        {
            throw new InvalidOperationException(
                "Ungültige Bootstrap-Optionen.");
        }

        options[values[index][2..]] = values[index + 1];
    }

    return options;
}

static void ValidateLoopbackListenUrl(string listenUrl)
{
    if (
        listenUrl.Contains(';', StringComparison.Ordinal)
        || !Uri.TryCreate(listenUrl, UriKind.Absolute, out var uri)
        || !string.Equals(uri.Scheme, Uri.UriSchemeHttp, StringComparison.OrdinalIgnoreCase)
        || uri.Port is < 1024 or > 65535
        || !(
            string.Equals(uri.Host, "localhost", StringComparison.OrdinalIgnoreCase)
            || (IPAddress.TryParse(uri.Host, out var address) && IPAddress.IsLoopback(address))
        )
    )
    {
        throw new InvalidOperationException(
            "Server:ListenUrl muss eine einzelne lokale HTTP-Adresse mit Port ab 1024 sein.");
    }
}

static int ParsePortOption(
    IReadOnlyDictionary<string, string> options,
    string commandLabel)
{
    if (
        !options.TryGetValue("port", out var portText)
        || !int.TryParse(portText, out var port)
        || port is < 1024 or > 65535
    )
    {
        throw new InvalidOperationException(
            $"{commandLabel} benötigt --port mit einem Wert von 1024 bis 65535.");
    }

    return port;
}
