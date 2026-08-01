namespace MeineBudgetwelt.Server.Accounts;

public sealed record UserAccount(
    string Id,
    string DisplayName,
    string Email,
    string EmailNormalized,
    string PasswordHash,
    bool IsSystemAdmin,
    bool IsActive,
    DateTimeOffset CreatedUtc,
    DateTimeOffset UpdatedUtc)
{
    public UserSummary ToSummary() => new(
        Id,
        DisplayName,
        Email,
        IsSystemAdmin,
        IsActive,
        CreatedUtc,
        UpdatedUtc);
}

public sealed record UserSummary(
    string Id,
    string DisplayName,
    string Email,
    bool IsSystemAdmin,
    bool IsActive,
    DateTimeOffset CreatedUtc,
    DateTimeOffset UpdatedUtc);

public sealed record AuthenticatedSession(
    UserAccount User,
    string Token,
    DateTimeOffset ExpiresUtc);

public sealed record BudgetGroupSummary(
    string Id,
    string Name,
    int MemberCount,
    DateTimeOffset CreatedUtc);

public sealed record BudgetGroupMemberSummary(
    string UserId,
    string DisplayName,
    string Email,
    string Role,
    bool IsActive);

public sealed record LoginRequest(
    string Email,
    string Password,
    bool RememberMe);

public sealed record CreateUserRequest(
    string Name,
    string Email,
    string Password,
    bool IsSystemAdmin);

public sealed record SetUserActiveRequest(bool IsActive);

public sealed record CreateBudgetGroupRequest(string Name);

public sealed record SetBudgetGroupMemberRequest(
    string UserId,
    string Role);

public sealed record CreateInvitationRequest(
    string Name,
    string Email,
    string? GroupId,
    string? Role);

public sealed record InvitationSummary(
    string Id,
    string Name,
    string Email,
    string? GroupId,
    string? Role,
    DateTimeOffset ExpiresUtc,
    bool IsAccepted,
    bool IsRevoked);

public sealed record RegisterWithInvitationRequest(
    string Token,
    string Name,
    string Password);

public sealed record ForgotPasswordRequest(string Email);

public sealed record ResetPasswordRequest(
    string Token,
    string Password);

public sealed class AccountValidationException(string message)
    : Exception(message);

public sealed class AccountEmailException(string message, Exception? inner = null)
    : Exception(message, inner);
