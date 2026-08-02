namespace MeineBudgetwelt.Server.Banking;

public sealed class EnableBankingOptions
{
    public bool Enabled { get; init; }

    public string BaseUrl { get; init; } = "https://api.enablebanking.com/";

    public string RedirectBaseUrl { get; init; } = "https://budget.leno.info";

    public string DefaultCountry { get; init; } = "DE";

    public string ApplicationId { get; init; } = string.Empty;

    public string PrivateKeyPath { get; init; } = string.Empty;

    public int TimeoutSeconds { get; init; } = 45;
}
