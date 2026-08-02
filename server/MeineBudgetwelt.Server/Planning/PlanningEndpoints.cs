using MeineBudgetwelt.Server.Accounts;
using MeineBudgetwelt.Server.Sync;

namespace MeineBudgetwelt.Server.Planning;

public static class PlanningEndpoints
{
    private const string SessionCookieName = "__Host-mbw_session";

    public static IEndpointRouteBuilder MapPlanningEndpoints(
        this IEndpointRouteBuilder endpoints)
    {
        endpoints.MapPost(
                "/api/planning/groups/{groupId}/weekly-plan",
                CreateWeeklyPlanAsync)
            .RequireRateLimiting("ai-planning");
        return endpoints;
    }

    private static async Task<IResult> CreateWeeklyPlanAsync(
        string groupId,
        WeeklyPlanningRequest request,
        HttpContext context,
        AccountService accounts,
        SyncService sync,
        WeeklyPlanningValidator validator,
        LocalAiWeeklyPlanningService planning,
        CancellationToken cancellationToken)
    {
        var user = await AuthenticateAsync(context, accounts, cancellationToken);
        if (user is null)
        {
            return Results.Unauthorized();
        }

        try
        {
            validator.ValidateRequest(request);
            await sync.EnsureMembershipAsync(
                groupId,
                user.Id,
                cancellationToken);
            var draft = await planning.CreateDraftAsync(
                request,
                user.Id,
                cancellationToken);
            validator.ValidateDraft(request, draft);
            return Results.Ok(draft);
        }
        catch (SyncAccessDeniedException)
        {
            return Results.Forbid();
        }
        catch (PlanningInputException exception)
        {
            return ValidationProblem(exception.Message);
        }
        catch (PlanningUnavailableException exception)
        {
            return Results.Problem(
                exception.Message,
                statusCode: StatusCodes.Status503ServiceUnavailable);
        }
        catch (PlanningOutputException exception)
        {
            return Results.Problem(
                exception.Message,
                statusCode: StatusCodes.Status502BadGateway);
        }
        catch (PlanningProviderException exception)
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

    private static IResult ValidationProblem(string message) =>
        Results.ValidationProblem(new Dictionary<string, string[]>
        {
            ["planning"] = [message],
        });
}
