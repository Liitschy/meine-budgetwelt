using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using Microsoft.Extensions.Options;

namespace MeineBudgetwelt.Server.Banking;

public sealed class EnableBankingClient
{
    public const string ProviderId = "enable-banking";
    public const string ProviderName = "Enable Banking";

    private const int MaximumTransactionPages = 50;
    private const int MaximumTransactions = 5_000;

    private readonly HttpClient _httpClient;
    private readonly EnableBankingOptions _options;

    private readonly bool _privateKeyValid;
    public EnableBankingClient(
        HttpClient httpClient,
        IOptions<EnableBankingOptions> options)
    {
        _options = options.Value;
        if (
            !Uri.TryCreate(_options.BaseUrl, UriKind.Absolute, out var baseUri)
            || baseUri.Scheme != Uri.UriSchemeHttps
        )
        {
            throw new InvalidOperationException(
                "EnableBanking:BaseUrl muss eine absolute HTTPS-Adresse sein.");
        }
        if (
            !Uri.TryCreate(
                _options.RedirectBaseUrl,
                UriKind.Absolute,
                out var redirectUri)
            || redirectUri.Scheme != Uri.UriSchemeHttps
            || !string.IsNullOrEmpty(redirectUri.Query)
            || !string.IsNullOrEmpty(redirectUri.Fragment)
        )
        {
            throw new InvalidOperationException(
                "EnableBanking:RedirectBaseUrl muss eine absolute HTTPS-Adresse ohne Query oder Fragment sein.");
        }

        _httpClient = httpClient;
        _httpClient.BaseAddress = baseUri;
        _httpClient.Timeout = TimeSpan.FromSeconds(
            Math.Clamp(_options.TimeoutSeconds, 10, 120));
        _privateKeyValid = ValidatePrivateKey();
    }

    public bool IsConfigured =>
        _options.Enabled
        && _privateKeyValid
        && Guid.TryParse(_options.ApplicationId, out _)
        && !string.IsNullOrWhiteSpace(_options.PrivateKeyPath)
        && File.Exists(_options.PrivateKeyPath);

    public string DefaultCountry => NormalizeCountry(_options.DefaultCountry);

    public string RedirectBaseUrl => _options.RedirectBaseUrl.TrimEnd('/');

    public async Task<IReadOnlyList<BankInstitution>> ListInstitutionsAsync(
        string country,
        CancellationToken cancellationToken)
    {
        var normalizedCountry = NormalizeCountry(country);
        using var document = await SendAsync(
            HttpMethod.Get,
            $"aspsps?country={Uri.EscapeDataString(normalizedCountry)}&psu_type=personal&service=AIS",
            null,
            cancellationToken);
        if (
            !document.RootElement.TryGetProperty("aspsps", out var values)
            || values.ValueKind != JsonValueKind.Array
        )
        {
            throw new BankingProviderException(
                "Enable Banking hat keine gültige Bankenliste geliefert.");
        }

        var result = new List<BankInstitution>();
        foreach (var item in values.EnumerateArray())
        {
            var name = GetString(item, "name").Trim();
            var itemCountry = GetString(item, "country").Trim().ToUpperInvariant();
            if (
                string.IsNullOrWhiteSpace(name)
                || !string.Equals(itemCountry, normalizedCountry, StringComparison.Ordinal)
            )
            {
                continue;
            }
            var maximumSeconds = GetInt(item, "maximum_consent_validity");
            result.Add(new BankInstitution(
                InstitutionId(itemCountry, name),
                name,
                GetString(item, "bic"),
                GetString(item, "logo"),
                maximumSeconds <= 0
                    ? 90 * 86_400
                    : maximumSeconds));
        }
        return result
            .GroupBy(item => item.Id, StringComparer.Ordinal)
            .Select(group => group.First())
            .OrderBy(item => item.Name, StringComparer.OrdinalIgnoreCase)
            .ToArray();
    }

    public async Task<ProviderAuthorization> StartAuthorizationAsync(
        BankInstitution institution,
        string country,
        string redirectUrl,
        string state,
        CancellationToken cancellationToken)
    {
        var validUntil = DateTimeOffset.UtcNow.AddSeconds(Math.Clamp(
            institution.MaximumConsentValiditySeconds,
            1,
            180 * 86_400));
        using var document = await SendAsync(
            HttpMethod.Post,
            "auth",
            new
            {
                access = new
                {
                    balances = true,
                    transactions = true,
                    valid_until = validUntil.ToString("O"),
                },
                aspsp = new
                {
                    name = institution.Name,
                    country = NormalizeCountry(country),
                },
                state,
                redirect_url = redirectUrl,
                psu_type = "personal",
                language = "de",
            },
            cancellationToken);
        var id = GetString(document.RootElement, "authorization_id");
        var link = GetString(document.RootElement, "url");
        if (
            !Guid.TryParse(id, out _)
            || !Uri.TryCreate(link, UriKind.Absolute, out var linkUri)
            || linkUri.Scheme != Uri.UriSchemeHttps
            || !(
                linkUri.Host.Equals("enablebanking.com", StringComparison.OrdinalIgnoreCase)
                || linkUri.Host.EndsWith(".enablebanking.com", StringComparison.OrdinalIgnoreCase)
            )
        )
        {
            throw new BankingProviderException(
                "Enable Banking hat keinen vollständigen Autorisierungslink geliefert.");
        }
        return new ProviderAuthorization(id, "PENDING_AUTHORIZATION", link);
    }

    public async Task<ProviderSession> AuthorizeSessionAsync(
        string code,
        CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(code) || code.Length > 2_048)
        {
            throw new BankingValidationException(
                "Der Rückgabecode der Bank ist ungültig.");
        }
        using var document = await SendAsync(
            HttpMethod.Post,
            "sessions",
            new { code },
            cancellationToken);
        var sessionId = GetString(document.RootElement, "session_id");
        var accounts = ReadAccountUids(document.RootElement, "accounts");
        if (!Guid.TryParse(sessionId, out _))
        {
            throw new BankingProviderException(
                "Enable Banking hat keine gültige Sitzung geliefert.");
        }
        return new ProviderSession(
            sessionId,
            "AUTHORIZED",
            accounts);
    }

    public async Task<ProviderSession> GetSessionAsync(
        string sessionId,
        CancellationToken cancellationToken)
    {
        using var document = await SendAsync(
            HttpMethod.Get,
            $"sessions/{Uri.EscapeDataString(sessionId)}",
            null,
            cancellationToken);
        return new ProviderSession(
            sessionId,
            GetString(document.RootElement, "status"),
            ReadStringArray(document.RootElement, "accounts"));
    }

    public Task<JsonDocument> GetBalancesAsync(
        string accountId,
        CancellationToken cancellationToken) =>
        SendAsync(
            HttpMethod.Get,
            $"accounts/{Uri.EscapeDataString(accountId)}/balances",
            null,
            cancellationToken);

    public async Task<JsonDocument> GetTransactionsAsync(
        string accountId,
        CancellationToken cancellationToken)
    {
        var transactions = new List<JsonElement>();
        string? continuationKey = null;
        for (var page = 0; page < MaximumTransactionPages; page++)
        {
            var path = $"accounts/{Uri.EscapeDataString(accountId)}/transactions";
            if (!string.IsNullOrWhiteSpace(continuationKey))
            {
                path += "?continuation_key="
                    + Uri.EscapeDataString(continuationKey);
            }
            using var document = await SendAsync(
                HttpMethod.Get,
                path,
                null,
                cancellationToken);
            if (
                document.RootElement.TryGetProperty("transactions", out var values)
                && values.ValueKind == JsonValueKind.Array
            )
            {
                foreach (var transaction in values.EnumerateArray())
                {
                    transactions.Add(transaction.Clone());
                    if (transactions.Count > MaximumTransactions)
                    {
                        throw new BankingProviderException(
                            "Enable Banking hat für eine Aktualisierung zu viele Buchungen geliefert.");
                    }
                }
            }
            continuationKey = GetString(document.RootElement, "continuation_key");
            if (string.IsNullOrWhiteSpace(continuationKey))
            {
                return JsonDocument.Parse(JsonSerializer.Serialize(new
                {
                    transactions,
                }));
            }
        }
        throw new BankingProviderException(
            "Enable Banking hat die Seitennavigation der Buchungen nicht beendet.");
    }

    public async Task DeleteSessionAsync(
        string sessionId,
        CancellationToken cancellationToken)
    {
        using var ignored = await SendAsync(
            HttpMethod.Delete,
            $"sessions/{Uri.EscapeDataString(sessionId)}",
            null,
            cancellationToken,
            allowEmptyResponse: true);
    }

    private async Task<JsonDocument> SendAsync(
        HttpMethod method,
        string path,
        object? body,
        CancellationToken cancellationToken,
        bool allowEmptyResponse = false)
    {
        EnsureConfigured();
        using var request = new HttpRequestMessage(method, path);
        request.Headers.Authorization = new AuthenticationHeaderValue(
            "Bearer",
            CreateJwt());
        request.Headers.Accept.Add(new MediaTypeWithQualityHeaderValue(
            "application/json"));
        if (body is not null)
        {
            request.Content = JsonContent.Create(body);
        }

        using var response = await _httpClient.SendAsync(
            request,
            HttpCompletionOption.ResponseHeadersRead,
            cancellationToken);
        var responseText = await response.Content.ReadAsStringAsync(
            cancellationToken);
        if (!response.IsSuccessStatusCode)
        {
            throw new BankingProviderException(
                ProviderError(responseText, (int)response.StatusCode));
        }
        if (string.IsNullOrWhiteSpace(responseText) && allowEmptyResponse)
        {
            return JsonDocument.Parse("{}");
        }
        try
        {
            return JsonDocument.Parse(responseText);
        }
        catch (JsonException)
        {
            throw new BankingProviderException(
                "Enable Banking hat eine ungültige Antwort geliefert.");
        }
    }

    private string CreateJwt()
    {
        try
        {
            var now = DateTimeOffset.UtcNow.ToUnixTimeSeconds();
            var header = Base64Url(JsonSerializer.SerializeToUtf8Bytes(new
            {
                typ = "JWT",
                alg = "RS256",
                kid = _options.ApplicationId.Trim(),
            }));
            var payload = Base64Url(JsonSerializer.SerializeToUtf8Bytes(new
            {
                iss = "enablebanking.com",
                aud = "api.enablebanking.com",
                iat = now,
                exp = now + 300,
            }));
            var unsignedToken = header + "." + payload;
            using var rsa = RSA.Create();
            rsa.ImportFromPem(File.ReadAllText(
                _options.PrivateKeyPath,
                Encoding.UTF8));
            var signature = rsa.SignData(
                Encoding.ASCII.GetBytes(unsignedToken),
                HashAlgorithmName.SHA256,
                RSASignaturePadding.Pkcs1);
            return unsignedToken + "." + Base64Url(signature);
        }
        catch (Exception exception) when (
            exception is IOException
            or UnauthorizedAccessException
            or CryptographicException
            or ArgumentException)
        {
            throw new BankingUnavailableException(
                "Der private Enable-Banking-Schlüssel auf dem Server ist nicht lesbar oder ungültig.");
        }
    }
    private bool ValidatePrivateKey()
    {
        if (
            !_options.Enabled
            || !Guid.TryParse(_options.ApplicationId, out _)
            || string.IsNullOrWhiteSpace(_options.PrivateKeyPath)
            || !File.Exists(_options.PrivateKeyPath)
        )
        {
            return false;
        }
        try
        {
            using var rsa = RSA.Create();
            rsa.ImportFromPem(File.ReadAllText(
                _options.PrivateKeyPath,
                Encoding.UTF8));
            return rsa.KeySize >= 2_048;
        }
        catch (Exception exception) when (
            exception is IOException
            or UnauthorizedAccessException
            or CryptographicException
            or ArgumentException)
        {
            return false;
        }
    }

    private void EnsureConfigured()
    {
        if (!IsConfigured)
        {
            throw new BankingUnavailableException(
                "Der read-only-Bankabruf ist auf dem Server noch nicht freigeschaltet.");
        }
    }

    private static string InstitutionId(string country, string name)
    {
        var source = country + "|" + name.Trim().ToLowerInvariant();
        return "eb_" + Convert.ToHexString(
            SHA256.HashData(Encoding.UTF8.GetBytes(source)))[..32]
            .ToLowerInvariant();
    }

    private static string NormalizeCountry(string country)
    {
        var normalized = country.Trim().ToUpperInvariant();
        if (
            normalized.Length != 2
            || !normalized.All(character => character is >= 'A' and <= 'Z')
        )
        {
            throw new BankingValidationException(
                "Das Bankland muss als zweistelliger ISO-Code angegeben werden.");
        }
        return normalized;
    }

    private static string Base64Url(byte[] value) =>
        Convert.ToBase64String(value)
            .TrimEnd('=')
            .Replace('+', '-')
            .Replace('/', '_');

    private static string ProviderError(string responseText, int statusCode)
    {
        try
        {
            using var document = JsonDocument.Parse(responseText);
            foreach (var property in new[]
            {
                "detail",
                "message",
                "error_description",
                "error",
            })
            {
                var value = GetString(document.RootElement, property).Trim();
                if (!string.IsNullOrWhiteSpace(value))
                {
                    return $"Enable Banking: {value}";
                }
            }
        }
        catch (JsonException)
        {
            // Deliberately do not return raw provider bodies.
        }
        return $"Enable-Banking-Anfrage fehlgeschlagen (HTTP {statusCode}).";
    }

    internal static string GetString(JsonElement element, string property) =>
        element.TryGetProperty(property, out var value)
            && value.ValueKind == JsonValueKind.String
                ? value.GetString() ?? string.Empty
                : string.Empty;

    internal static int GetInt(JsonElement element, string property)
    {
        if (!element.TryGetProperty(property, out var value))
        {
            return 0;
        }
        if (value.ValueKind == JsonValueKind.Number && value.TryGetInt32(out var number))
        {
            return number;
        }
        return value.ValueKind == JsonValueKind.String
            && int.TryParse(value.GetString(), out number)
                ? number
                : 0;
    }

    internal static IReadOnlyList<string> ReadStringArray(
        JsonElement element,
        string property)
    {
        if (
            !element.TryGetProperty(property, out var values)
            || values.ValueKind != JsonValueKind.Array
        )
        {
            return [];
        }
        return values.EnumerateArray()
            .Where(value => value.ValueKind == JsonValueKind.String)
            .Select(value => value.GetString() ?? string.Empty)
            .Where(value => !string.IsNullOrWhiteSpace(value))
            .ToArray();
    }

    private static IReadOnlyList<string> ReadAccountUids(
        JsonElement element,
        string property)
    {
        if (
            !element.TryGetProperty(property, out var values)
            || values.ValueKind != JsonValueKind.Array
        )
        {
            return [];
        }
        return values.EnumerateArray()
            .Where(value => value.ValueKind == JsonValueKind.Object)
            .Select(value => GetString(value, "uid"))
            .Where(value => !string.IsNullOrWhiteSpace(value))
            .ToArray();
    }
}

public sealed record ProviderAuthorization(
    string Id,
    string Status,
    string Link);

public sealed record ProviderSession(
    string Id,
    string Status,
    IReadOnlyList<string> Accounts);
