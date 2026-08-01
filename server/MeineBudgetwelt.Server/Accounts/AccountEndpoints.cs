namespace MeineBudgetwelt.Server.Accounts;

public static class AccountEndpoints
{
    private const string SessionCookieName = "__Host-mbw_session";

    public static IEndpointRouteBuilder MapAccountEndpoints(
        this IEndpointRouteBuilder endpoints)
    {
        var auth = endpoints.MapGroup("/api/auth");
        auth.MapPost("/login", LoginForPwaAsync)
            .RequireRateLimiting("login");
        auth.MapPost("/desktop-login", LoginForDesktopAsync)
            .RequireRateLimiting("login");
        auth.MapPost("/register", RegisterAsync)
            .RequireRateLimiting("account-flow");
        auth.MapPost("/forgot-password", ForgotPasswordAsync)
            .RequireRateLimiting("account-flow");
        auth.MapPost("/reset-password", ResetPasswordAsync)
            .RequireRateLimiting("account-flow");
        auth.MapGet("/me", GetCurrentUserAsync);
        auth.MapPost("/logout", LogoutAsync);

        var admin = endpoints.MapGroup("/api/admin");
        admin.MapGet("/users", ListUsersAsync);
        admin.MapPost("/users", CreateUserAsync);
        admin.MapPatch("/users/{userId}/active", SetUserActiveAsync);
        admin.MapGet("/groups", ListGroupsAsync);
        admin.MapPost("/groups", CreateGroupAsync);
        admin.MapDelete("/groups/{groupId}", DeleteGroupAsync);
        admin.MapGet("/groups/{groupId}/members", ListGroupMembersAsync);
        admin.MapPut("/groups/{groupId}/members", SetGroupMemberAsync);
        admin.MapGet("/invitations", ListInvitationsAsync);
        admin.MapPost("/invitations", CreateInvitationAsync);

        return endpoints;
    }

    private static async Task<IResult> LoginForPwaAsync(
        LoginRequest request,
        HttpContext context,
        AccountService accounts,
        CancellationToken cancellationToken)
    {
        var session = await accounts.LoginAsync(
            request.Email,
            request.Password,
            request.RememberMe,
            "pwa",
            context.Request.Headers.UserAgent.ToString(),
            cancellationToken);
        if (session is null)
        {
            return Results.Unauthorized();
        }

        context.Response.Cookies.Append(
            SessionCookieName,
            session.Token,
            new CookieOptions
            {
                HttpOnly = true,
                Secure = true,
                SameSite = SameSiteMode.Strict,
                Path = "/",
                Expires = request.RememberMe ? session.ExpiresUtc : null,
                IsEssential = true,
            });
        return Results.Ok(new
        {
            user = session.User.ToSummary(),
            expiresUtc = session.ExpiresUtc,
        });
    }

    private static async Task<IResult> LoginForDesktopAsync(
        LoginRequest request,
        HttpContext context,
        AccountService accounts,
        CancellationToken cancellationToken)
    {
        var session = await accounts.LoginAsync(
            request.Email,
            request.Password,
            request.RememberMe,
            "desktop",
            context.Request.Headers.UserAgent.ToString(),
            cancellationToken);
        return session is null
            ? Results.Unauthorized()
            : Results.Ok(new
            {
                user = session.User.ToSummary(),
                token = session.Token,
                expiresUtc = session.ExpiresUtc,
            });
    }

    private static async Task<IResult> GetCurrentUserAsync(
        HttpContext context,
        AccountService accounts,
        CancellationToken cancellationToken)
    {
        var authenticated = await AuthenticateAsync(
            context,
            accounts,
            cancellationToken);
        return authenticated.User is null
            ? Results.Unauthorized()
            : Results.Ok(authenticated.User.ToSummary());
    }

    private static async Task<IResult> RegisterAsync(
        RegisterWithInvitationRequest request,
        AccountService accounts,
        CancellationToken cancellationToken)
    {
        try
        {
            var user = await accounts.RegisterWithInvitationAsync(
                request,
                cancellationToken);
            return Results.Created("/api/auth/me", user);
        }
        catch (AccountValidationException exception)
        {
            return ValidationProblem(exception.Message);
        }
    }

    private static async Task<IResult> ForgotPasswordAsync(
        ForgotPasswordRequest request,
        AccountService accounts,
        CancellationToken cancellationToken)
    {
        try
        {
            await accounts.RequestPasswordResetAsync(
                request.Email,
                cancellationToken);
            return Results.Accepted();
        }
        catch (AccountEmailException exception)
        {
            return Results.Problem(
                exception.Message,
                statusCode: StatusCodes.Status503ServiceUnavailable);
        }
    }

    private static async Task<IResult> ResetPasswordAsync(
        ResetPasswordRequest request,
        AccountService accounts,
        CancellationToken cancellationToken)
    {
        try
        {
            await accounts.ResetPasswordAsync(request, cancellationToken);
            return Results.NoContent();
        }
        catch (AccountValidationException exception)
        {
            return ValidationProblem(exception.Message);
        }
    }

    private static async Task<IResult> LogoutAsync(
        HttpContext context,
        AccountService accounts,
        CancellationToken cancellationToken)
    {
        var token = ReadToken(context);
        if (!string.IsNullOrWhiteSpace(token))
        {
            await accounts.RevokeSessionAsync(token, cancellationToken);
        }
        context.Response.Cookies.Delete(
            SessionCookieName,
            new CookieOptions
            {
                Secure = true,
                SameSite = SameSiteMode.Strict,
                Path = "/",
            });
        return Results.NoContent();
    }

    private static async Task<IResult> ListUsersAsync(
        HttpContext context,
        AccountService accounts,
        CancellationToken cancellationToken)
    {
        var admin = await RequireAdminAsync(context, accounts, cancellationToken);
        return admin is null
            ? Results.Unauthorized()
            : Results.Ok(await accounts.ListUsersAsync(cancellationToken));
    }

    private static async Task<IResult> CreateUserAsync(
        CreateUserRequest request,
        HttpContext context,
        AccountService accounts,
        CancellationToken cancellationToken)
    {
        var admin = await RequireAdminAsync(context, accounts, cancellationToken);
        if (admin is null)
        {
            return Results.Unauthorized();
        }

        try
        {
            var user = await accounts.CreateUserAsync(
                request.Name,
                request.Email,
                request.Password,
                request.IsSystemAdmin,
                cancellationToken);
            return Results.Created("/api/admin/users/" + user.Id, user);
        }
        catch (AccountValidationException exception)
        {
            return ValidationProblem(exception.Message);
        }
    }

    private static async Task<IResult> SetUserActiveAsync(
        string userId,
        SetUserActiveRequest request,
        HttpContext context,
        AccountService accounts,
        CancellationToken cancellationToken)
    {
        var admin = await RequireAdminAsync(context, accounts, cancellationToken);
        if (admin is null)
        {
            return Results.Unauthorized();
        }
        if (
            string.Equals(admin.Id, userId, StringComparison.OrdinalIgnoreCase)
            && !request.IsActive
        )
        {
            return ValidationProblem(
                "Das aktuell angemeldete Administratorkonto kann sich nicht selbst sperren.");
        }

        return await accounts.SetUserActiveAsync(
            userId,
            request.IsActive,
            cancellationToken)
            ? Results.NoContent()
            : Results.NotFound();
    }

    private static async Task<IResult> ListGroupsAsync(
        HttpContext context,
        AccountService accounts,
        CancellationToken cancellationToken)
    {
        var admin = await RequireAdminAsync(context, accounts, cancellationToken);
        return admin is null
            ? Results.Unauthorized()
            : Results.Ok(await accounts.ListBudgetGroupsAsync(cancellationToken));
    }

    private static async Task<IResult> CreateGroupAsync(
        CreateBudgetGroupRequest request,
        HttpContext context,
        AccountService accounts,
        CancellationToken cancellationToken)
    {
        var admin = await RequireAdminAsync(context, accounts, cancellationToken);
        if (admin is null)
        {
            return Results.Unauthorized();
        }
        try
        {
            var group = await accounts.CreateBudgetGroupAsync(
                request.Name,
                admin.Id,
                cancellationToken);
            return Results.Created("/api/admin/groups/" + group.Id, group);
        }
        catch (AccountValidationException exception)
        {
            return ValidationProblem(exception.Message);
        }
    }

    private static async Task<IResult> ListGroupMembersAsync(
        string groupId,
        HttpContext context,
        AccountService accounts,
        CancellationToken cancellationToken)
    {
        var admin = await RequireAdminAsync(context, accounts, cancellationToken);
        return admin is null
            ? Results.Unauthorized()
            : Results.Ok(
                await accounts.ListGroupMembersAsync(groupId, cancellationToken));
    }

    private static async Task<IResult> DeleteGroupAsync(
        string groupId,
        string confirmationName,
        HttpContext context,
        AccountService accounts,
        CancellationToken cancellationToken)
    {
        var admin = await RequireAdminAsync(context, accounts, cancellationToken);
        if (admin is null)
        {
            return Results.Unauthorized();
        }
        try
        {
            var deleted = await accounts.DeleteBudgetGroupAsync(
                groupId,
                confirmationName,
                cancellationToken);
            return deleted ? Results.NoContent() : Results.NotFound();
        }
        catch (AccountValidationException exception)
        {
            return ValidationProblem(exception.Message);
        }
    }

    private static async Task<IResult> SetGroupMemberAsync(
        string groupId,
        SetBudgetGroupMemberRequest request,
        HttpContext context,
        AccountService accounts,
        CancellationToken cancellationToken)
    {
        var admin = await RequireAdminAsync(context, accounts, cancellationToken);
        if (admin is null)
        {
            return Results.Unauthorized();
        }
        try
        {
            await accounts.SetBudgetGroupMemberAsync(
                groupId,
                request.UserId,
                request.Role,
                cancellationToken);
            return Results.NoContent();
        }
        catch (AccountValidationException exception)
        {
            return ValidationProblem(exception.Message);
        }
    }

    private static async Task<IResult> ListInvitationsAsync(
        HttpContext context,
        AccountService accounts,
        CancellationToken cancellationToken)
    {
        var admin = await RequireAdminAsync(context, accounts, cancellationToken);
        return admin is null
            ? Results.Unauthorized()
            : Results.Ok(await accounts.ListInvitationsAsync(cancellationToken));
    }

    private static async Task<IResult> CreateInvitationAsync(
        CreateInvitationRequest request,
        HttpContext context,
        AccountService accounts,
        CancellationToken cancellationToken)
    {
        var admin = await RequireAdminAsync(context, accounts, cancellationToken);
        if (admin is null)
        {
            return Results.Unauthorized();
        }
        try
        {
            var invitation = await accounts.CreateInvitationAsync(
                request,
                admin.Id,
                cancellationToken);
            return Results.Created(
                "/api/admin/invitations/" + invitation.Id,
                invitation);
        }
        catch (AccountValidationException exception)
        {
            return ValidationProblem(exception.Message);
        }
        catch (AccountEmailException exception)
        {
            return Results.Problem(
                exception.Message,
                statusCode: StatusCodes.Status503ServiceUnavailable);
        }
    }

    private static async Task<UserAccount?> RequireAdminAsync(
        HttpContext context,
        AccountService accounts,
        CancellationToken cancellationToken)
    {
        var authenticated = await AuthenticateAsync(
            context,
            accounts,
            cancellationToken);
        return authenticated.User is { IsSystemAdmin: true }
            ? authenticated.User
            : null;
    }

    private static async Task<(UserAccount? User, string Token)> AuthenticateAsync(
        HttpContext context,
        AccountService accounts,
        CancellationToken cancellationToken)
    {
        var token = ReadToken(context);
        return string.IsNullOrWhiteSpace(token)
            ? (null, string.Empty)
            : (await accounts.AuthenticateAsync(token, cancellationToken), token);
    }

    private static string ReadToken(HttpContext context)
    {
        var authorization = context.Request.Headers.Authorization.ToString();
        const string bearerPrefix = "Bearer ";
        if (authorization.StartsWith(
            bearerPrefix,
            StringComparison.OrdinalIgnoreCase))
        {
            return authorization[bearerPrefix.Length..].Trim();
        }
        return context.Request.Cookies.TryGetValue(
            SessionCookieName,
            out var cookieToken)
            ? cookieToken
            : string.Empty;
    }

    private static IResult ValidationProblem(string message) =>
        Results.ValidationProblem(new Dictionary<string, string[]>
        {
            ["account"] = [message],
        });
}
