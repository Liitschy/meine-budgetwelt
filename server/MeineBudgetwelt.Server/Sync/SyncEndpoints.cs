using MeineBudgetwelt.Server.Accounts;

namespace MeineBudgetwelt.Server.Sync;

public static class SyncEndpoints
{
    private const string SessionCookieName = "__Host-mbw_session";

    public static IEndpointRouteBuilder MapSyncEndpoints(
        this IEndpointRouteBuilder endpoints)
    {
        var sync = endpoints.MapGroup("/api/sync");
        sync.MapGet("/groups", ListGroupsAsync);
        sync.MapGet("/groups/{groupId}/snapshot", GetSnapshotAsync);
        sync.MapPut("/groups/{groupId}/snapshot", PutSnapshotAsync);
        return endpoints;
    }

    private static async Task<IResult> ListGroupsAsync(
        HttpContext context,
        AccountService accounts,
        SyncService sync,
        CancellationToken cancellationToken)
    {
        var user = await AuthenticateAsync(context, accounts, cancellationToken);
        return user is null
            ? Results.Unauthorized()
            : Results.Ok(await sync.ListGroupsAsync(user.Id, cancellationToken));
    }

    private static async Task<IResult> GetSnapshotAsync(
        string groupId,
        HttpContext context,
        AccountService accounts,
        SyncService sync,
        CancellationToken cancellationToken)
    {
        var user = await AuthenticateAsync(context, accounts, cancellationToken);
        if (user is null)
        {
            return Results.Unauthorized();
        }
        try
        {
            return Results.Ok(await sync.GetSnapshotAsync(
                groupId,
                user.Id,
                cancellationToken));
        }
        catch (SyncAccessDeniedException)
        {
            return Results.Forbid();
        }
    }

    private static async Task<IResult> PutSnapshotAsync(
        string groupId,
        PutSyncSnapshotRequest request,
        HttpContext context,
        AccountService accounts,
        SyncService sync,
        CancellationToken cancellationToken)
    {
        var user = await AuthenticateAsync(context, accounts, cancellationToken);
        if (user is null)
        {
            return Results.Unauthorized();
        }
        try
        {
            return Results.Ok(await sync.PutSnapshotAsync(
                groupId,
                user.Id,
                request,
                cancellationToken));
        }
        catch (SyncAccessDeniedException)
        {
            return Results.Forbid();
        }
        catch (SyncValidationException exception)
        {
            return Results.ValidationProblem(
                new Dictionary<string, string[]>
                {
                    ["sync"] = [exception.Message],
                });
        }
        catch (SyncConflictException exception)
        {
            return Results.Conflict(new
            {
                message = exception.Message,
                current = exception.Current,
            });
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
