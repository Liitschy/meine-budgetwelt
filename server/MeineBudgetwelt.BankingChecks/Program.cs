using System.Net;
using System.Text;
using MeineBudgetwelt.Server.Banking;
using Microsoft.Extensions.Options;

var previousSecretId = Environment.GetEnvironmentVariable(
    GoCardlessClient.SecretIdEnvironmentVariable);
var previousSecretKey = Environment.GetEnvironmentVariable(
    GoCardlessClient.SecretKeyEnvironmentVariable);

try
{
    Environment.SetEnvironmentVariable(
        GoCardlessClient.SecretIdEnvironmentVariable,
        "test-secret-id");
    Environment.SetEnvironmentVariable(
        GoCardlessClient.SecretKeyEnvironmentVariable,
        "test-secret-key");

    var handler = new FakeGoCardlessHandler();
    var client = new GoCardlessClient(
        new HttpClient(handler),
        Options.Create(new GoCardlessOptions
        {
            Enabled = true,
            BaseUrl = "https://banking.test/api/v2/",
            RedirectBaseUrl = "https://budget.leno.info",
            DefaultCountry = "DE",
            SandboxMode = true,
            TimeoutSeconds = 10,
        }));

    Ensure(client.IsConfigured, "Konfigurierter Anbieter wird nicht erkannt.");
    var institutions = await client.ListInstitutionsAsync("de", CancellationToken.None);
    Ensure(institutions.Count == 2, "Sandbox-Bank wurde nicht sicher ergaenzt.");
    Ensure(
        institutions[0].Id == "SANDBOXFINANCE_SFIN0000",
        "Sandbox-Bank-ID wurde verändert.");

    var created = await client.CreateRequisitionAsync(
        institutions[0].Id,
        "https://budget.leno.info/api/banking/callback?connectionId=abc",
        "mbw-reference",
        CancellationToken.None);
    Ensure(created.Id == "requisition-1", "Bankfreigabe wurde nicht angelegt.");
    Ensure(
        created.Link.StartsWith("https://", StringComparison.Ordinal),
        "Bankfreigabe ist nicht HTTPS.");

    var linked = await client.GetRequisitionAsync(
        created.Id,
        CancellationToken.None);
    Ensure(linked.Status == "LN", "Verbundener Anbieterstatus wurde nicht gelesen.");
    Ensure(linked.Accounts.SequenceEqual(["account-1"]), "Kontoliste ist ungültig.");

    using var balances = await client.GetBalancesAsync(
        "account-1",
        CancellationToken.None);
    Ensure(
        balances.RootElement.GetProperty("balances").GetArrayLength() == 1,
        "Kontostandantwort wurde nicht gelesen.");
    using var transactions = await client.GetTransactionsAsync(
        "account-1",
        CancellationToken.None);
    Ensure(
        transactions.RootElement
            .GetProperty("transactions")
            .GetProperty("booked")
            .GetArrayLength() == 1,
        "Buchungsantwort wurde nicht gelesen.");

    await client.DeleteRequisitionAsync(created.Id, CancellationToken.None);
    Ensure(handler.TokenRequests == 1, "Zugriffstoken wurde unnötig mehrfach angefordert.");
    Ensure(
        handler.Paths.All(path => !path.Contains("payment", StringComparison.OrdinalIgnoreCase)),
        "Der read-only-Client hat einen Zahlungspfad verwendet.");
    Ensure(
        handler.AuthorizedRequests == 6,
        "Nicht jede Anbieteranfrage war mit einem Zugriffstoken geschützt.");

    ExpectInvalidConfiguration(() => new GoCardlessClient(
        new HttpClient(new FakeGoCardlessHandler()),
        Options.Create(new GoCardlessOptions
        {
            Enabled = true,
            BaseUrl = "https://banking.test/api/v2/",
            RedirectBaseUrl = "http://budget.leno.info",
        })));

    Environment.SetEnvironmentVariable(
        GoCardlessClient.SecretKeyEnvironmentVariable,
        null);
    Ensure(!client.IsConfigured, "Fehlendes Servergeheimnis wurde nicht erkannt.");
    await ExpectUnavailableAsync(() => client.ListInstitutionsAsync(
        "DE",
        CancellationToken.None));

    Console.WriteLine("GoCardless-read-only-Vertrag: alle Prüfungen bestanden.");
}
finally
{
    Environment.SetEnvironmentVariable(
        GoCardlessClient.SecretIdEnvironmentVariable,
        previousSecretId);
    Environment.SetEnvironmentVariable(
        GoCardlessClient.SecretKeyEnvironmentVariable,
        previousSecretKey);
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
    throw new InvalidOperationException("Unsichere Redirect-Konfiguration wurde angenommen.");
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
    throw new InvalidOperationException("Nicht konfigurierter Bankabruf wurde ausgeführt.");
}

sealed class FakeGoCardlessHandler : HttpMessageHandler
{
    public int TokenRequests { get; private set; }
    public int AuthorizedRequests { get; private set; }
    public List<string> Paths { get; } = [];

    protected override async Task<HttpResponseMessage> SendAsync(
        HttpRequestMessage request,
        CancellationToken cancellationToken)
    {
        var path = request.RequestUri?.AbsolutePath ?? string.Empty;
        Paths.Add(path);
        if (path.EndsWith("/token/new/", StringComparison.Ordinal))
        {
            TokenRequests++;
            var tokenBody = await request.Content!.ReadAsStringAsync(cancellationToken);
            Ensure(
                tokenBody.Contains("test-secret-id", StringComparison.Ordinal)
                && tokenBody.Contains("test-secret-key", StringComparison.Ordinal),
                "Tokenanfrage enthält nicht die erwarteten Servergeheimnisse.");
            return Json(HttpStatusCode.OK, """
                {
                  "access": "access-token",
                  "access_expires": 3600,
                  "refresh": "refresh-token",
                  "refresh_expires": 86400
                }
                """);
        }

        Ensure(
            request.Headers.Authorization?.Scheme == "Bearer"
            && request.Headers.Authorization.Parameter == "access-token",
            "Anbieteranfrage enthält kein gültiges Bearer-Token.");
        AuthorizedRequests++;

        if (path.EndsWith("/institutions/", StringComparison.Ordinal))
        {
            Ensure(
                request.RequestUri!.Query == "?country=DE",
                "Bankland wurde nicht normalisiert.");
            return Json(HttpStatusCode.OK, """
                [{
                  "id": "MUSTERBANK_DETEST0001",
                  "name": "Musterbank Deutschland",
                  "bic": "DETEST0001",
                  "logo": "https://banking.test/logo.png",
                  "max_access_valid_for_days": 90
                }]
                """);
        }
        if (path.EndsWith("/requisitions/", StringComparison.Ordinal)
            && request.Method == HttpMethod.Post)
        {
            return Json(HttpStatusCode.Created, """
                {
                  "id": "requisition-1",
                  "status": "CR",
                  "link": "https://banking.test/authorize/requisition-1",
                  "accounts": []
                }
                """);
        }
        if (path.EndsWith("/requisitions/requisition-1/", StringComparison.Ordinal)
            && request.Method == HttpMethod.Get)
        {
            return Json(HttpStatusCode.OK, """
                {
                  "id": "requisition-1",
                  "status": "LN",
                  "link": "https://banking.test/authorize/requisition-1",
                  "accounts": ["account-1"]
                }
                """);
        }
        if (path.EndsWith("/accounts/account-1/balances/", StringComparison.Ordinal))
        {
            return Json(HttpStatusCode.OK, """
                {"balances":[{"balanceAmount":{"amount":"1428.48","currency":"EUR"},"balanceType":"interimAvailable"}]}
                """);
        }
        if (path.EndsWith("/accounts/account-1/transactions/", StringComparison.Ordinal))
        {
            return Json(HttpStatusCode.OK, """
                {"transactions":{"booked":[{"transactionId":"tx-1","bookingDate":"2026-08-01","transactionAmount":{"amount":"-64.95","currency":"EUR"},"creditorName":"EDEKA"}],"pending":[]}}
                """);
        }
        if (path.EndsWith("/requisitions/requisition-1/", StringComparison.Ordinal)
            && request.Method == HttpMethod.Delete)
        {
            return new HttpResponseMessage(HttpStatusCode.NoContent);
        }
        return Json(HttpStatusCode.NotFound, "{\"detail\":\"unexpected test path\"}");
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
