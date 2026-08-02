using System.Net;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using MeineBudgetwelt.Server.Banking;
using Microsoft.Extensions.Options;

var applicationId = Guid.NewGuid().ToString();
var keyPath = Path.Combine(
    Path.GetTempPath(),
    "mbw-enable-banking-" + Guid.NewGuid().ToString("N") + ".pem");
using var signingKey = RSA.Create(2048);
await File.WriteAllTextAsync(
    keyPath,
    PemEncoding.WriteString("PRIVATE KEY", signingKey.ExportPkcs8PrivateKey()),
    new UTF8Encoding(false));

try
{
    var handler = new FakeEnableBankingHandler(
        applicationId,
        signingKey.ExportSubjectPublicKeyInfo());
    var client = new EnableBankingClient(
        new HttpClient(handler),
        Options.Create(new EnableBankingOptions
        {
            Enabled = true,
            BaseUrl = "https://banking.test/",
            RedirectBaseUrl = "https://budget.leno.info",
            DefaultCountry = "DE",
            ApplicationId = applicationId,
            PrivateKeyPath = keyPath,
            TimeoutSeconds = 10,
        }));

    Ensure(client.IsConfigured, "Configured provider was not detected.");
    var institutions = await client.ListInstitutionsAsync(
        "de",
        CancellationToken.None);
    Ensure(institutions.Count == 1, "Bank list was not parsed.");
    Ensure(
        institutions[0].Id.StartsWith("eb_", StringComparison.Ordinal),
        "Stable Enable Banking institution id is missing.");
    Ensure(
        institutions[0].MaximumConsentValiditySeconds == 3_600,
        "Consent validity seconds were not preserved.");

    var created = await client.StartAuthorizationAsync(
        institutions[0],
        "DE",
        "https://budget.leno.info/api/banking/callback",
        "0123456789abcdef0123456789abcdef",
        CancellationToken.None);
    Ensure(
        created.Id == FakeEnableBankingHandler.AuthorizationId,
        "Authorization was not created.");
    Ensure(
        created.Link.StartsWith("https://", StringComparison.Ordinal),
        "Authorization URL is not HTTPS.");

    var authorized = await client.AuthorizeSessionAsync(
        "provider-code",
        CancellationToken.None);
    Ensure(
        authorized.Id == FakeEnableBankingHandler.SessionId,
        "Session was not authorized.");
    Ensure(
        authorized.Accounts.SequenceEqual([FakeEnableBankingHandler.AccountId]),
        "Authorized account list is invalid.");

    var session = await client.GetSessionAsync(
        authorized.Id,
        CancellationToken.None);
    Ensure(session.Status == "AUTHORIZED", "Session status was not read.");

    using var balances = await client.GetBalancesAsync(
        FakeEnableBankingHandler.AccountId,
        CancellationToken.None);
    Ensure(
        balances.RootElement.GetProperty("balances").GetArrayLength() == 1,
        "Balance response was not read.");

    using var transactions = await client.GetTransactionsAsync(
        FakeEnableBankingHandler.AccountId,
        CancellationToken.None);
    Ensure(
        transactions.RootElement
            .GetProperty("transactions")
            .GetArrayLength() == 2,
        "Paginated transactions were not merged.");

    await client.DeleteSessionAsync(authorized.Id, CancellationToken.None);
    Ensure(
        handler.Paths.All(path =>
            !path.Contains("payment", StringComparison.OrdinalIgnoreCase)),
        "Read-only client used a payment path.");
    Ensure(
        handler.AuthorizedRequests == 8,
        "Not every provider request used a signed JWT.");

    ExpectInvalidConfiguration(() => new EnableBankingClient(
        new HttpClient(new FakeEnableBankingHandler(
            applicationId,
            signingKey.ExportSubjectPublicKeyInfo())),
        Options.Create(new EnableBankingOptions
        {
            Enabled = true,
            BaseUrl = "https://banking.test/",
            RedirectBaseUrl = "http://budget.leno.info",
            ApplicationId = applicationId,
            PrivateKeyPath = keyPath,
        })));
    var foreignClient = new EnableBankingClient(
        new HttpClient(new FakeEnableBankingHandler(
            applicationId,
            signingKey.ExportSubjectPublicKeyInfo(),
            "https://example.invalid/authorize")),
        Options.Create(new EnableBankingOptions
        {
            Enabled = true,
            BaseUrl = "https://banking.test/",
            RedirectBaseUrl = "https://budget.leno.info",
            DefaultCountry = "DE",
            ApplicationId = applicationId,
            PrivateKeyPath = keyPath,
        }));
    await ExpectProviderFailureAsync(() => foreignClient.StartAuthorizationAsync(
        institutions[0],
        "DE",
        "https://budget.leno.info/api/banking/callback",
        "0123456789abcdef0123456789abcdef",
        CancellationToken.None));

    File.Delete(keyPath);
    Ensure(!client.IsConfigured, "Missing private key was not detected.");
    await ExpectUnavailableAsync(() => client.ListInstitutionsAsync(
        "DE",
        CancellationToken.None));

    Console.WriteLine(
        "Enable-Banking read-only contract: all checks passed.");
}
finally
{
    if (File.Exists(keyPath))
    {
        File.Delete(keyPath);
    }
}

static void Ensure(bool condition, string message)
{
    if (!condition)
    {
        throw new InvalidOperationException(message);
    }
}

static void ExpectInvalidConfiguration(Action action)
{
    try
    {
        action();
    }
    catch (InvalidOperationException)
    {
        return;
    }
    throw new InvalidOperationException(
        "Unsafe redirect configuration was accepted.");
}

static async Task ExpectUnavailableAsync(Func<Task> action)
{
    try
    {
        await action();
    }
    catch (BankingUnavailableException)
    {
        return;
    }
    throw new InvalidOperationException(
        "Unconfigured bank access was executed.");
}
static async Task ExpectProviderFailureAsync(Func<Task> action)
{
    try
    {
        await action();
    }
    catch (BankingProviderException)
    {
        return;
    }
    throw new InvalidOperationException(
        "Foreign authorization URL was accepted.");
}

sealed class FakeEnableBankingHandler(
    string applicationId,
    byte[] publicKey,
    string authorizationUrl = "https://auth.enablebanking.com/start") : HttpMessageHandler
{
    public const string AuthorizationId =
        "11111111-1111-4111-8111-111111111111";
    public const string SessionId =
        "22222222-2222-4222-8222-222222222222";
    public const string AccountId =
        "33333333-3333-4333-8333-333333333333";

    public int AuthorizedRequests { get; private set; }
    public List<string> Paths { get; } = [];

    protected override async Task<HttpResponseMessage> SendAsync(
        HttpRequestMessage request,
        CancellationToken cancellationToken)
    {
        var path = request.RequestUri?.AbsolutePath ?? string.Empty;
        Paths.Add(path);
        VerifyJwt(request);
        AuthorizedRequests++;

        if (path == "/aspsps")
        {
            Ensure(
                request.RequestUri!.Query.Contains("country=DE", StringComparison.Ordinal),
                "Bank country was not normalized.");
            return Json(HttpStatusCode.OK, """
                {"aspsps":[{"name":"Musterbank","country":"DE","bic":"TESTDEFF","logo":"https://banking.test/logo.png","maximum_consent_validity":3600,"auth_methods":[]}]}
                """);
        }
        if (path == "/auth" && request.Method == HttpMethod.Post)
        {
            var body = await request.Content!.ReadAsStringAsync(cancellationToken);
            Ensure(
                body.Contains("https://budget.leno.info/api/banking/callback", StringComparison.Ordinal)
                && body.Contains("0123456789abcdef0123456789abcdef", StringComparison.Ordinal)
                && body.Contains("\"transactions\":true", StringComparison.Ordinal),
                "Authorization request is incomplete.");
            using var requestDocument = JsonDocument.Parse(body);
            var validUntil = DateTimeOffset.Parse(
                requestDocument.RootElement
                    .GetProperty("access")
                    .GetProperty("valid_until")
                    .GetString()!);
            Ensure(
                validUntil > DateTimeOffset.UtcNow.AddMinutes(50)
                && validUntil <= DateTimeOffset.UtcNow.AddMinutes(61),
                "Sub-day consent validity was not preserved.");
            return Json(HttpStatusCode.OK, $$$"""
                {"authorization_id":"{{{AuthorizationId}}}","url":"{{{authorizationUrl}}}"}
                """);
        }
        if (path == "/sessions" && request.Method == HttpMethod.Post)
        {
            return Json(HttpStatusCode.OK, $$$"""
                {"session_id":"{{{SessionId}}}","accounts":[{"uid":"{{{AccountId}}}"}],"aspsp":{"name":"Musterbank","country":"DE"},"psu_type":"personal","access":{}}
                """);
        }
        if (path == $"/sessions/{SessionId}" && request.Method == HttpMethod.Get)
        {
            return Json(HttpStatusCode.OK, $$$"""
                {"status":"AUTHORIZED","accounts":["{{{AccountId}}}"],"accounts_data":[],"aspsp":{"name":"Musterbank","country":"DE"},"psu_type":"personal"}
                """);
        }
        if (path == $"/accounts/{AccountId}/balances")
        {
            return Json(HttpStatusCode.OK, """
                {"balances":[{"balance_amount":{"amount":"1428.48","currency":"EUR"},"balance_type":"ITAV"}]}
                """);
        }
        if (path == $"/accounts/{AccountId}/transactions")
        {
            return string.IsNullOrWhiteSpace(request.RequestUri!.Query)
                ? Json(HttpStatusCode.OK, """
                    {"transactions":[{"entry_reference":"tx-1","booking_date":"2026-08-01","transaction_amount":{"amount":"64.95","currency":"EUR"},"credit_debit_indicator":"DBIT","status":"BOOK","creditor":{"name":"EDEKA"}}],"continuation_key":"next-page"}
                    """)
                : Json(HttpStatusCode.OK, """
                    {"transactions":[{"entry_reference":"tx-2","booking_date":"2026-08-02","transaction_amount":{"amount":"100.00","currency":"EUR"},"credit_debit_indicator":"CRDT","status":"BOOK","debtor":{"name":"Arbeitgeber"}}]}
                    """);
        }
        if (path == $"/sessions/{SessionId}" && request.Method == HttpMethod.Delete)
        {
            return Json(HttpStatusCode.OK, """{"message":"OK"}""");
        }
        return Json(
            HttpStatusCode.NotFound,
            """{"detail":"unexpected test path"}""");
    }

    private void VerifyJwt(HttpRequestMessage request)
    {
        Ensure(
            request.Headers.Authorization?.Scheme == "Bearer",
            "Provider request contains no bearer JWT.");
        var token = request.Headers.Authorization!.Parameter ?? string.Empty;
        var parts = token.Split('.');
        Ensure(parts.Length == 3, "JWT structure is invalid.");
        var header = JsonDocument.Parse(Decode(parts[0]));
        Ensure(
            header.RootElement.GetProperty("kid").GetString() == applicationId
            && header.RootElement.GetProperty("alg").GetString() == "RS256",
            "JWT header is invalid.");
        using var rsa = RSA.Create();
        rsa.ImportSubjectPublicKeyInfo(publicKey, out _);
        Ensure(
            rsa.VerifyData(
                Encoding.ASCII.GetBytes(parts[0] + "." + parts[1]),
                Decode(parts[2]),
                HashAlgorithmName.SHA256,
                RSASignaturePadding.Pkcs1),
            "JWT signature is invalid.");
    }

    private static byte[] Decode(string value)
    {
        var padded = value.Replace('-', '+').Replace('_', '/');
        padded += new string('=', (4 - padded.Length % 4) % 4);
        return Convert.FromBase64String(padded);
    }

    private static HttpResponseMessage Json(HttpStatusCode status, string json) =>
        new(status)
        {
            Content = new StringContent(json, Encoding.UTF8, "application/json"),
        };

    private static void Ensure(bool condition, string message)
    {
        if (!condition)
        {
            throw new InvalidOperationException(message);
        }
    }
}
