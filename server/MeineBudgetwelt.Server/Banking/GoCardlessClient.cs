using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.Extensions.Options;

namespace MeineBudgetwelt.Server.Banking;

public sealed class GoCardlessClient
{
    public const string SandboxInstitutionId = "SANDBOXFINANCE_SFIN0000";

    public const string SecretIdEnvironmentVariable =
        "BUDGETWELT_GOCARDLESS_SECRET_ID";
    public const string SecretKeyEnvironmentVariable =
        "BUDGETWELT_GOCARDLESS_SECRET_KEY";

    private static readonly JsonSerializerOptions SerializerOptions = new()
    {
        PropertyNameCaseInsensitive = true,
    };

    private readonly HttpClient _httpClient;
    private readonly GoCardlessOptions _options;
    private readonly SemaphoreSlim _tokenLock = new(1, 1);
    private string _accessToken = string.Empty;
    private DateTimeOffset _accessExpiresUtc = DateTimeOffset.MinValue;
    private string _refreshToken = string.Empty;
    private DateTimeOffset _refreshExpiresUtc = DateTimeOffset.MinValue;

    public GoCardlessClient(
        HttpClient httpClient,
        IOptions<GoCardlessOptions> options)
    {
        _options = options.Value;
        if (
            !Uri.TryCreate(_options.BaseUrl, UriKind.Absolute, out var baseUri)
            || baseUri.Scheme != Uri.UriSchemeHttps
        )
        {
            throw new InvalidOperationException(
                "GoCardless:BaseUrl muss eine absolute HTTPS-Adresse sein.");
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
                "GoCardless:RedirectBaseUrl muss eine absolute HTTPS-Adresse ohne Query oder Fragment sein.");
        }

        _httpClient = httpClient;
        _httpClient.BaseAddress = baseUri;
        _httpClient.Timeout = TimeSpan.FromSeconds(
            Math.Clamp(_options.TimeoutSeconds, 10, 120));
    }

    public bool IsConfigured =>
        _options.Enabled
        && !string.IsNullOrWhiteSpace(Environment.GetEnvironmentVariable(
            SecretIdEnvironmentVariable))
        && !string.IsNullOrWhiteSpace(Environment.GetEnvironmentVariable(
            SecretKeyEnvironmentVariable));

    public string DefaultCountry => NormalizeCountry(_options.DefaultCountry);

    public string RedirectBaseUrl => _options.RedirectBaseUrl.TrimEnd('/');

    public async Task<IReadOnlyList<BankInstitution>> ListInstitutionsAsync(
        string country,
        CancellationToken cancellationToken)
    {
        var normalizedCountry = NormalizeCountry(country);
        using var document = await SendAuthorizedAsync(
            HttpMethod.Get,
            $"institutions/?country={Uri.EscapeDataString(normalizedCountry)}",
            null,
            cancellationToken);
        if (document.RootElement.ValueKind != JsonValueKind.Array)
        {
            throw new BankingProviderException(
                "GoCardless hat keine gültige Bankenliste geliefert.");
        }

        var result = new List<BankInstitution>();
        foreach (var item in document.RootElement.EnumerateArray())
        {
            var id = GetString(item, "id");
            var name = GetString(item, "name");
            if (string.IsNullOrWhiteSpace(id) || string.IsNullOrWhiteSpace(name))
            {
                continue;
            }
            result.Add(new BankInstitution(
                id,
                name,
                GetString(item, "bic"),
                GetString(item, "logo"),
                GetInt(item, "max_access_valid_for_days")));
        }
        if (
            _options.SandboxMode
            && result.All(item => !string.Equals(
                item.Id,
                SandboxInstitutionId,
                StringComparison.Ordinal))
        )
        {
            result.Insert(0, new BankInstitution(
                SandboxInstitutionId,
                "Sandbox Finance (Testbank)",
                "SFIN0000",
                string.Empty,
                90));
        }
        return result;
    }

    public async Task<ProviderRequisition> CreateRequisitionAsync(
        string institutionId,
        string redirectUrl,
        string reference,
        CancellationToken cancellationToken)
    {
        using var document = await SendAuthorizedAsync(
            HttpMethod.Post,
            "requisitions/",
            new
            {
                redirect = redirectUrl,
                institution_id = institutionId,
                reference,
                user_language = "DE",
            },
            cancellationToken);
        var id = GetString(document.RootElement, "id");
        var link = GetString(document.RootElement, "link");
        if (string.IsNullOrWhiteSpace(id) || string.IsNullOrWhiteSpace(link))
        {
            throw new BankingProviderException(
                "GoCardless hat keinen vollständigen Autorisierungslink geliefert.");
        }
        return new ProviderRequisition(
            id,
            GetString(document.RootElement, "status"),
            link,
            ReadStringArray(document.RootElement, "accounts"));
    }

    public async Task<ProviderRequisition> GetRequisitionAsync(
        string requisitionId,
        CancellationToken cancellationToken)
    {
        using var document = await SendAuthorizedAsync(
            HttpMethod.Get,
            $"requisitions/{Uri.EscapeDataString(requisitionId)}/",
            null,
            cancellationToken);
        return new ProviderRequisition(
            GetString(document.RootElement, "id"),
            GetString(document.RootElement, "status"),
            GetString(document.RootElement, "link"),
            ReadStringArray(document.RootElement, "accounts"));
    }

    public Task<JsonDocument> GetAccountDetailsAsync(
        string accountId,
        CancellationToken cancellationToken) =>
        SendAuthorizedAsync(
            HttpMethod.Get,
            $"accounts/{Uri.EscapeDataString(accountId)}/details/",
            null,
            cancellationToken);

    public Task<JsonDocument> GetBalancesAsync(
        string accountId,
        CancellationToken cancellationToken) =>
        SendAuthorizedAsync(
            HttpMethod.Get,
            $"accounts/{Uri.EscapeDataString(accountId)}/balances/",
            null,
            cancellationToken);

    public Task<JsonDocument> GetTransactionsAsync(
        string accountId,
        CancellationToken cancellationToken) =>
        SendAuthorizedAsync(
            HttpMethod.Get,
            $"accounts/{Uri.EscapeDataString(accountId)}/transactions/",
            null,
            cancellationToken);

    public async Task DeleteRequisitionAsync(
        string requisitionId,
        CancellationToken cancellationToken)
    {
        using var ignored = await SendAuthorizedAsync(
            HttpMethod.Delete,
            $"requisitions/{Uri.EscapeDataString(requisitionId)}/",
            null,
            cancellationToken,
            allowEmptyResponse: true);
    }

    private async Task<JsonDocument> SendAuthorizedAsync(
        HttpMethod method,
        string path,
        object? body,
        CancellationToken cancellationToken,
        bool allowEmptyResponse = false)
    {
        var accessToken = await GetAccessTokenAsync(cancellationToken);
        using var request = new HttpRequestMessage(method, path);
        request.Headers.Authorization = new AuthenticationHeaderValue(
            "Bearer",
            accessToken);
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
                "GoCardless hat eine ungültige Antwort geliefert.");
        }
    }

    private async Task<string> GetAccessTokenAsync(
        CancellationToken cancellationToken)
    {
        EnsureConfigured();
        if (
            !string.IsNullOrWhiteSpace(_accessToken)
            && _accessExpiresUtc > DateTimeOffset.UtcNow.AddMinutes(1)
        )
        {
            return _accessToken;
        }

        await _tokenLock.WaitAsync(cancellationToken);
        try
        {
            if (
                !string.IsNullOrWhiteSpace(_accessToken)
                && _accessExpiresUtc > DateTimeOffset.UtcNow.AddMinutes(1)
            )
            {
                return _accessToken;
            }

            if (
                !string.IsNullOrWhiteSpace(_refreshToken)
                && _refreshExpiresUtc > DateTimeOffset.UtcNow.AddMinutes(5)
            )
            {
                await RefreshAccessTokenAsync(cancellationToken);
            }
            else
            {
                await CreateTokenPairAsync(cancellationToken);
            }
            return _accessToken;
        }
        finally
        {
            _tokenLock.Release();
        }
    }

    private async Task CreateTokenPairAsync(CancellationToken cancellationToken)
    {
        var secretId = Environment.GetEnvironmentVariable(
            SecretIdEnvironmentVariable)?.Trim();
        var secretKey = Environment.GetEnvironmentVariable(
            SecretKeyEnvironmentVariable)?.Trim();
        using var document = await SendTokenRequestAsync(
            "token/new/",
            new { secret_id = secretId, secret_key = secretKey },
            cancellationToken);
        _refreshToken = GetString(document.RootElement, "refresh");
        _accessToken = GetString(document.RootElement, "access");
        var now = DateTimeOffset.UtcNow;
        _refreshExpiresUtc = now.AddSeconds(Math.Max(
            GetInt(document.RootElement, "refresh_expires"),
            60));
        _accessExpiresUtc = now.AddSeconds(Math.Max(
            GetInt(document.RootElement, "access_expires"),
            60));
        EnsureTokenResponse();
    }

    private async Task RefreshAccessTokenAsync(CancellationToken cancellationToken)
    {
        using var document = await SendTokenRequestAsync(
            "token/refresh/",
            new { refresh = _refreshToken },
            cancellationToken);
        _accessToken = GetString(document.RootElement, "access");
        _accessExpiresUtc = DateTimeOffset.UtcNow.AddSeconds(Math.Max(
            GetInt(document.RootElement, "access_expires"),
            60));
        EnsureTokenResponse();
    }

    private async Task<JsonDocument> SendTokenRequestAsync(
        string path,
        object body,
        CancellationToken cancellationToken)
    {
        using var response = await _httpClient.PostAsJsonAsync(
            path,
            body,
            SerializerOptions,
            cancellationToken);
        var responseText = await response.Content.ReadAsStringAsync(
            cancellationToken);
        if (!response.IsSuccessStatusCode)
        {
            throw new BankingProviderException(
                ProviderError(responseText, (int)response.StatusCode));
        }
        try
        {
            return JsonDocument.Parse(responseText);
        }
        catch (JsonException)
        {
            throw new BankingProviderException(
                "GoCardless hat eine ungültige Tokenantwort geliefert.");
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

    private void EnsureTokenResponse()
    {
        if (string.IsNullOrWhiteSpace(_accessToken))
        {
            throw new BankingProviderException(
                "GoCardless hat kein gültiges Zugriffstoken geliefert.");
        }
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

    private static string ProviderError(string responseText, int statusCode)
    {
        try
        {
            using var document = JsonDocument.Parse(responseText);
            var detail = GetString(document.RootElement, "detail");
            var summary = GetString(document.RootElement, "summary");
            if (!string.IsNullOrWhiteSpace(detail))
            {
                return $"GoCardless: {detail}";
            }
            if (!string.IsNullOrWhiteSpace(summary))
            {
                return $"GoCardless: {summary}";
            }
        }
        catch (JsonException)
        {
            // Deliberately do not return raw provider bodies.
        }
        return $"GoCardless-Anfrage fehlgeschlagen (HTTP {statusCode}).";
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
}

public sealed record ProviderRequisition(
    string Id,
    string Status,
    string Link,
    IReadOnlyList<string> Accounts);
