using MeineBudgetwelt.Server.Accounts;
using MeineBudgetwelt.Server.Sync;

namespace MeineBudgetwelt.Server.Banking;

public static class BankingEndpoints
{
    private const string SessionCookieName = "__Host-mbw_session";

    public static IEndpointRouteBuilder MapBankingEndpoints(
        this IEndpointRouteBuilder endpoints)
    {
        var banking = endpoints.MapGroup("/api/banking")
            .RequireRateLimiting("banking");
        banking.MapGet("/status", GetStatusAsync);
        banking.MapGet("/institutions", ListInstitutionsAsync);
        banking.MapGet("/groups/{groupId}/connections", ListConnectionsAsync);
        banking.MapPost("/groups/{groupId}/connections", CreateConnectionAsync);
        banking.MapPost(
            "/groups/{groupId}/connections/{connectionId}/refresh",
            RefreshConnectionAsync);
        banking.MapDelete(
            "/groups/{groupId}/connections/{connectionId}",
            DisconnectAsync);
        endpoints.MapGet("/api/banking/callback", CompleteCallbackAsync)
            .RequireRateLimiting("banking");
        return endpoints;
    }

    private static async Task<IResult> GetStatusAsync(
        HttpContext context,
        AccountService accounts,
        BankingService banking,
        CancellationToken cancellationToken)
    {
        var user = await AuthenticateAsync(context, accounts, cancellationToken);
        return user is null
            ? Results.Unauthorized()
            : Results.Ok(new
            {
                enabled = banking.IsConfigured,
                provider = "GoCardless Bank Account Data",
                mode = "read-only",
                automaticRefresh = false,
                payments = false,
            });
    }

    private static async Task<IResult> ListInstitutionsAsync(
        string? country,
        HttpContext context,
        AccountService accounts,
        BankingService banking,
        CancellationToken cancellationToken)
    {
        var user = await AuthenticateAsync(context, accounts, cancellationToken);
        if (user is null)
        {
            return Results.Unauthorized();
        }
        return await ExecuteAsync(async () => Results.Ok(
            await banking.ListInstitutionsAsync(country, cancellationToken)));
    }

    private static async Task<IResult> ListConnectionsAsync(
        string groupId,
        HttpContext context,
        AccountService accounts,
        BankingService banking,
        CancellationToken cancellationToken)
    {
        var user = await AuthenticateAsync(context, accounts, cancellationToken);
        if (user is null)
        {
            return Results.Unauthorized();
        }
        return await ExecuteAsync(async () => Results.Ok(
            await banking.ListConnectionsAsync(
                groupId,
                user.Id,
                cancellationToken)));
    }

    private static async Task<IResult> CreateConnectionAsync(
        string groupId,
        CreateBankConnectionRequest request,
        HttpContext context,
        AccountService accounts,
        BankingService banking,
        CancellationToken cancellationToken)
    {
        var user = await AuthenticateAsync(context, accounts, cancellationToken);
        if (user is null)
        {
            return Results.Unauthorized();
        }
        return await ExecuteAsync(async () => Results.Ok(
            await banking.CreateConnectionAsync(
                groupId,
                user.Id,
                request,
                cancellationToken)));
    }

    private static async Task<IResult> RefreshConnectionAsync(
        string groupId,
        string connectionId,
        RefreshBankConnectionRequest request,
        HttpContext context,
        AccountService accounts,
        BankingService banking,
        CancellationToken cancellationToken)
    {
        var user = await AuthenticateAsync(context, accounts, cancellationToken);
        if (user is null)
        {
            return Results.Unauthorized();
        }
        return await ExecuteAsync(async () => Results.Ok(
            await banking.RefreshAsync(
                groupId,
                user.Id,
                connectionId,
                request,
                cancellationToken)));
    }

    private static async Task<IResult> DisconnectAsync(
        string groupId,
        string connectionId,
        HttpContext context,
        AccountService accounts,
        BankingService banking,
        CancellationToken cancellationToken)
    {
        var user = await AuthenticateAsync(context, accounts, cancellationToken);
        if (user is null)
        {
            return Results.Unauthorized();
        }
        return await ExecuteAsync(async () =>
        {
            await banking.DisconnectAsync(
                groupId,
                user.Id,
                connectionId,
                cancellationToken);
            return Results.NoContent();
        });
    }

    private static async Task<IResult> CompleteCallbackAsync(
        string? connectionId,
        BankingService banking,
        CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(connectionId))
        {
            return Results.Redirect("/?banking=invalid", false, false);
        }
        try
        {
            var linked = await banking.CompleteCallbackAsync(
                connectionId,
                cancellationToken);
            return Results.Redirect(
                linked ? "/?banking=connected" : "/?banking=pending",
                false,
                false);
        }
        catch
        {
            return Results.Redirect("/?banking=error", false, false);
        }
    }

    private static async Task<IResult> ExecuteAsync(
        Func<Task<IResult>> action)
    {
        try
        {
            return await action();
        }
        catch (SyncAccessDeniedException)
        {
            return Results.Forbid();
        }
        catch (BankingAccessDeniedException)
        {
            return Results.Forbid();
        }
        catch (BankingValidationException exception)
        {
            return Results.ValidationProblem(new Dictionary<string, string[]>
            {
                ["banking"] = [exception.Message],
            });
        }
        catch (BankingUnavailableException exception)
        {
            return Results.Problem(
                exception.Message,
                statusCode: StatusCodes.Status503ServiceUnavailable);
        }
        catch (BankingProviderException exception)
        {
            return Results.Problem(
                exception.Message,
                statusCode: StatusCodes.Status502BadGateway);
        }
    }

    private static async Task<UserAccount?> AuthenticateAsync(
        HttpContext context,
        AccountService accounts,
        CancellationToken cancellationToken)
    {
        var authorization = context.Request.Headers.Authorization.ToString();
        const string bearerPrefix = "Bearer ";
        var token = authorization.StartsWith(
            bearerPrefix,
            StringComparison.OrdinalIgnoreCase)
            ? authorization[bearerPrefix.Length..].Trim()
            : context.Request.Cookies.TryGetValue(
                SessionCookieName,
                out var cookieToken)
                ? cookieToken
                : string.Empty;
        return string.IsNullOrWhiteSpace(token)
            ? null
            : await accounts.AuthenticateAsync(token, cancellationToken);
    }
}
