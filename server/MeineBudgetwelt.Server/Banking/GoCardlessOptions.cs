namespace MeineBudgetwelt.Server.Banking;

public sealed class GoCardlessOptions
{
    public bool Enabled { get; init; }

    public string BaseUrl { get; init; } =
        "https://bankaccountdata.gocardless.com/api/v2/";

    public string RedirectBaseUrl { get; init; } = "https://budget.leno.info";

    public string DefaultCountry { get; init; } = "DE";

    public bool SandboxMode { get; init; }

    public int TimeoutSeconds { get; init; } = 45;
}
