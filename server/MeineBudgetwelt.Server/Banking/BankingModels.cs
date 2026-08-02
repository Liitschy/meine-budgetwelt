namespace MeineBudgetwelt.Server.Banking;

public sealed record BankInstitution(
    string Id,
    string Name,
    string Bic,
    string Logo,
    int MaximumConsentValiditySeconds);

public sealed record CreateBankConnectionRequest(string InstitutionId);

public sealed record RefreshBankConnectionRequest(IReadOnlyList<string>? KnownImportIds);

public sealed record BankConnectionSummary(
    string Id,
    string InstitutionId,
    string InstitutionName,
    string Status,
    DateTimeOffset CreatedUtc,
    DateTimeOffset UpdatedUtc,
    DateTimeOffset? LastRefreshUtc,
    int AccountCount);

public sealed record CreatedBankConnection(
    BankConnectionSummary Connection,
    string AuthorizationUrl);

public sealed record BankBalancePreview(
    string AccountReference,
    string Currency,
    decimal Amount,
    string BalanceType);

public sealed record BankTransactionPreview(
    string ImportId,
    string AccountReference,
    string Status,
    string Kind,
    decimal Amount,
    string Currency,
    DateOnly BookingDate,
    string Description,
    bool AlreadyImported);

public sealed record BankRefreshPreview(
    string ConnectionId,
    string InstitutionName,
    DateTimeOffset RefreshedUtc,
    IReadOnlyList<BankBalancePreview> Balances,
    IReadOnlyList<BankTransactionPreview> Transactions,
    int DuplicateCount);

public sealed class BankingUnavailableException(string message)
    : Exception(message);

public sealed class BankingProviderException(string message)
    : Exception(message);

public sealed class BankingValidationException(string message)
    : Exception(message);

public sealed class BankingAccessDeniedException : Exception;
