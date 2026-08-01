using System.Globalization;
using System.Net.Mail;
using System.Security.Cryptography;
using System.Text;
using MeineBudgetwelt.Server.Storage;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.WebUtilities;
using Microsoft.Data.Sqlite;

namespace MeineBudgetwelt.Server.Accounts;

public sealed class AccountService(
    SqliteStore store,
    IPasswordHasher<UserAccount> passwordHasher,
    IAccountEmailSender emailSender)
{
    public async Task<UserSummary> CreateBootstrapAdminAsync(
        string name,
        string email,
        string password,
        CancellationToken cancellationToken = default)
    {
        await using var connection = await store.OpenConnectionAsync(
            cancellationToken);
        await using var countCommand = connection.CreateCommand();
        countCommand.CommandText = "SELECT COUNT(*) FROM users;";
        var userCount = Convert.ToInt64(
            await countCommand.ExecuteScalarAsync(cancellationToken),
            CultureInfo.InvariantCulture);
        if (userCount != 0)
        {
            throw new AccountValidationException(
                "Das erste Administratorkonto wurde bereits eingerichtet.");
        }

        var account = CreateAccount(name, email, password, true);
        var groupId = Guid.NewGuid().ToString("N");
        var now = DateTimeOffset.UtcNow.ToString("O", CultureInfo.InvariantCulture);

        await using var transaction = await connection.BeginTransactionAsync(
            cancellationToken);
        await InsertUserAsync(connection, transaction, account, cancellationToken);

        await using (var groupCommand = connection.CreateCommand())
        {
            groupCommand.Transaction = (SqliteTransaction)transaction;
            groupCommand.CommandText =
                """
                INSERT INTO budget_groups(
                    group_id,
                    name,
                    created_by_user_id,
                    created_utc,
                    updated_utc
                )
                VALUES ($group_id, $name, $user_id, $now, $now);

                INSERT INTO budget_group_members(
                    group_id,
                    user_id,
                    role,
                    created_utc
                )
                VALUES ($group_id, $user_id, 'owner', $now);
                """;
            groupCommand.Parameters.AddWithValue("$group_id", groupId);
            groupCommand.Parameters.AddWithValue(
                "$name",
                account.DisplayName + "s Budgetwelt");
            groupCommand.Parameters.AddWithValue("$user_id", account.Id);
            groupCommand.Parameters.AddWithValue("$now", now);
            await groupCommand.ExecuteNonQueryAsync(cancellationToken);
        }

        await transaction.CommitAsync(cancellationToken);
        return account.ToSummary();
    }

    public async Task<UserSummary> CreateUserAsync(
        string name,
        string email,
        string password,
        bool isSystemAdmin,
        CancellationToken cancellationToken = default)
    {
        var account = CreateAccount(name, email, password, isSystemAdmin);
        await using var connection = await store.OpenConnectionAsync(
            cancellationToken);
        try
        {
            await InsertUserAsync(connection, null, account, cancellationToken);
        }
        catch (SqliteException exception) when (exception.SqliteErrorCode == 19)
        {
            throw new AccountValidationException(
                "Für diese E-Mail-Adresse besteht bereits ein Konto.");
        }
        return account.ToSummary();
    }

    public async Task<AuthenticatedSession?> LoginAsync(
        string email,
        string password,
        bool rememberMe,
        string clientKind,
        string userAgent,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrEmpty(password))
        {
            return null;
        }

        string normalizedEmail;
        try
        {
            normalizedEmail = NormalizeEmail(email);
        }
        catch (AccountValidationException)
        {
            return null;
        }

        await using var connection = await store.OpenConnectionAsync(
            cancellationToken);
        var account = await FindUserByEmailAsync(
            connection,
            normalizedEmail,
            cancellationToken);
        if (account is null || !account.IsActive)
        {
            return null;
        }

        var verification = passwordHasher.VerifyHashedPassword(
            account,
            account.PasswordHash,
            password);
        if (verification == PasswordVerificationResult.Failed)
        {
            return null;
        }

        if (verification == PasswordVerificationResult.SuccessRehashNeeded)
        {
            var newHash = passwordHasher.HashPassword(account, password);
            await using var update = connection.CreateCommand();
            update.CommandText =
                """
                UPDATE users
                SET password_hash = $password_hash,
                    updated_utc = $updated_utc
                WHERE user_id = $user_id;
                """;
            update.Parameters.AddWithValue("$password_hash", newHash);
            update.Parameters.AddWithValue(
                "$updated_utc",
                DateTimeOffset.UtcNow.ToString("O", CultureInfo.InvariantCulture));
            update.Parameters.AddWithValue("$user_id", account.Id);
            await update.ExecuteNonQueryAsync(cancellationToken);
        }

        var token = WebEncoders.Base64UrlEncode(RandomNumberGenerator.GetBytes(32));
        var tokenHash = HashToken(token);
        var now = DateTimeOffset.UtcNow;
        var expires = now.Add(rememberMe ? TimeSpan.FromDays(30) : TimeSpan.FromHours(12));

        await using var sessionCommand = connection.CreateCommand();
        sessionCommand.CommandText =
            """
            INSERT INTO sessions(
                session_id,
                user_id,
                token_hash,
                created_utc,
                expires_utc,
                last_seen_utc,
                client_kind,
                user_agent
            )
            VALUES (
                $session_id,
                $user_id,
                $token_hash,
                $created_utc,
                $expires_utc,
                $last_seen_utc,
                $client_kind,
                $user_agent
            );
            """;
        sessionCommand.Parameters.AddWithValue(
            "$session_id",
            Guid.NewGuid().ToString("N"));
        sessionCommand.Parameters.AddWithValue("$user_id", account.Id);
        sessionCommand.Parameters.AddWithValue("$token_hash", tokenHash);
        sessionCommand.Parameters.AddWithValue(
            "$created_utc",
            now.ToString("O", CultureInfo.InvariantCulture));
        sessionCommand.Parameters.AddWithValue(
            "$expires_utc",
            expires.ToString("O", CultureInfo.InvariantCulture));
        sessionCommand.Parameters.AddWithValue(
            "$last_seen_utc",
            now.ToString("O", CultureInfo.InvariantCulture));
        sessionCommand.Parameters.AddWithValue("$client_kind", clientKind);
        sessionCommand.Parameters.AddWithValue(
            "$user_agent",
            Limit(userAgent, 300));
        await sessionCommand.ExecuteNonQueryAsync(cancellationToken);

        return new AuthenticatedSession(account, token, expires);
    }

    public async Task<UserAccount?> AuthenticateAsync(
        string token,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(token) || token.Length > 256)
        {
            return null;
        }

        await using var connection = await store.OpenConnectionAsync(
            cancellationToken);
        await using var command = connection.CreateCommand();
        command.CommandText =
            """
            SELECT
                u.user_id,
                u.display_name,
                u.email,
                u.email_normalized,
                u.password_hash,
                u.is_system_admin,
                u.is_active,
                u.created_utc,
                u.updated_utc
            FROM sessions s
            INNER JOIN users u ON u.user_id = s.user_id
            WHERE s.token_hash = $token_hash
              AND s.revoked_utc IS NULL
              AND s.expires_utc > $now
              AND u.is_active = 1
            LIMIT 1;
            """;
        command.Parameters.AddWithValue("$token_hash", HashToken(token));
        command.Parameters.AddWithValue(
            "$now",
            DateTimeOffset.UtcNow.ToString("O", CultureInfo.InvariantCulture));

        await using var reader = await command.ExecuteReaderAsync(
            cancellationToken);
        return await reader.ReadAsync(cancellationToken)
            ? ReadUser(reader)
            : null;
    }

    public async Task RevokeSessionAsync(
        string token,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(token) || token.Length > 256)
        {
            return;
        }

        await using var connection = await store.OpenConnectionAsync(
            cancellationToken);
        await using var command = connection.CreateCommand();
        command.CommandText =
            """
            UPDATE sessions
            SET revoked_utc = $revoked_utc
            WHERE token_hash = $token_hash
              AND revoked_utc IS NULL;
            """;
        command.Parameters.AddWithValue(
            "$revoked_utc",
            DateTimeOffset.UtcNow.ToString("O", CultureInfo.InvariantCulture));
        command.Parameters.AddWithValue("$token_hash", HashToken(token));
        await command.ExecuteNonQueryAsync(cancellationToken);
    }

    public async Task<IReadOnlyList<UserSummary>> ListUsersAsync(
        CancellationToken cancellationToken = default)
    {
        var users = new List<UserSummary>();
        await using var connection = await store.OpenConnectionAsync(
            cancellationToken);
        await using var command = connection.CreateCommand();
        command.CommandText =
            """
            SELECT
                user_id,
                display_name,
                email,
                email_normalized,
                password_hash,
                is_system_admin,
                is_active,
                created_utc,
                updated_utc
            FROM users
            ORDER BY display_name COLLATE NOCASE, email_normalized;
            """;
        await using var reader = await command.ExecuteReaderAsync(
            cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            users.Add(ReadUser(reader).ToSummary());
        }
        return users;
    }

    public async Task<bool> SetUserActiveAsync(
        string userId,
        bool isActive,
        CancellationToken cancellationToken = default)
    {
        await using var connection = await store.OpenConnectionAsync(
            cancellationToken);
        await using var transaction = await connection.BeginTransactionAsync(
            cancellationToken);

        await using var command = connection.CreateCommand();
        command.Transaction = (SqliteTransaction)transaction;
        command.CommandText =
            """
            UPDATE users
            SET is_active = $is_active,
                updated_utc = $updated_utc
            WHERE user_id = $user_id;
            """;
        command.Parameters.AddWithValue("$is_active", isActive ? 1 : 0);
        command.Parameters.AddWithValue(
            "$updated_utc",
            DateTimeOffset.UtcNow.ToString("O", CultureInfo.InvariantCulture));
        command.Parameters.AddWithValue("$user_id", userId);
        var changed = await command.ExecuteNonQueryAsync(cancellationToken);

        if (!isActive && changed == 1)
        {
            await using var revoke = connection.CreateCommand();
            revoke.Transaction = (SqliteTransaction)transaction;
            revoke.CommandText =
                """
                UPDATE sessions
                SET revoked_utc = $revoked_utc
                WHERE user_id = $user_id
                  AND revoked_utc IS NULL;
                """;
            revoke.Parameters.AddWithValue(
                "$revoked_utc",
                DateTimeOffset.UtcNow.ToString("O", CultureInfo.InvariantCulture));
            revoke.Parameters.AddWithValue("$user_id", userId);
            await revoke.ExecuteNonQueryAsync(cancellationToken);
        }

        await transaction.CommitAsync(cancellationToken);
        return changed == 1;
    }

    public async Task<BudgetGroupSummary> CreateBudgetGroupAsync(
        string name,
        string creatorUserId,
        CancellationToken cancellationToken = default)
    {
        var normalizedName = ValidateName(name, "Gruppenname");
        var groupId = Guid.NewGuid().ToString("N");
        var now = DateTimeOffset.UtcNow;
        var nowText = now.ToString("O", CultureInfo.InvariantCulture);

        await using var connection = await store.OpenConnectionAsync(
            cancellationToken);
        await using var transaction = await connection.BeginTransactionAsync(
            cancellationToken);
        await using var command = connection.CreateCommand();
        command.Transaction = (SqliteTransaction)transaction;
        command.CommandText =
            """
            INSERT INTO budget_groups(
                group_id,
                name,
                created_by_user_id,
                created_utc,
                updated_utc
            )
            VALUES ($group_id, $name, $user_id, $now, $now);

            INSERT INTO budget_group_members(
                group_id,
                user_id,
                role,
                created_utc
            )
            VALUES ($group_id, $user_id, 'owner', $now);
            """;
        command.Parameters.AddWithValue("$group_id", groupId);
        command.Parameters.AddWithValue("$name", normalizedName);
        command.Parameters.AddWithValue("$user_id", creatorUserId);
        command.Parameters.AddWithValue("$now", nowText);
        await command.ExecuteNonQueryAsync(cancellationToken);
        await transaction.CommitAsync(cancellationToken);
        return new BudgetGroupSummary(groupId, normalizedName, 1, now);
    }

    public async Task<IReadOnlyList<BudgetGroupSummary>> ListBudgetGroupsAsync(
        CancellationToken cancellationToken = default)
    {
        var groups = new List<BudgetGroupSummary>();
        await using var connection = await store.OpenConnectionAsync(
            cancellationToken);
        await using var command = connection.CreateCommand();
        command.CommandText =
            """
            SELECT
                g.group_id,
                g.name,
                COUNT(m.user_id),
                g.created_utc
            FROM budget_groups g
            LEFT JOIN budget_group_members m ON m.group_id = g.group_id
            GROUP BY g.group_id, g.name, g.created_utc
            ORDER BY g.name COLLATE NOCASE;
            """;
        await using var reader = await command.ExecuteReaderAsync(
            cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            groups.Add(new BudgetGroupSummary(
                reader.GetString(0),
                reader.GetString(1),
                reader.GetInt32(2),
                DateTimeOffset.Parse(
                    reader.GetString(3),
                    CultureInfo.InvariantCulture)));
        }
        return groups;
    }

    public async Task<bool> DeleteBudgetGroupAsync(
        string groupId,
        string confirmationName,
        CancellationToken cancellationToken = default)
    {
        await using var connection = await store.OpenConnectionAsync(
            cancellationToken);
        await using var transaction = await connection.BeginTransactionAsync(
            cancellationToken);

        await using var find = connection.CreateCommand();
        find.Transaction = (SqliteTransaction)transaction;
        find.CommandText =
            "SELECT name FROM budget_groups WHERE group_id = $group_id;";
        find.Parameters.AddWithValue("$group_id", groupId);
        var storedName = await find.ExecuteScalarAsync(cancellationToken) as string;
        if (storedName is null)
        {
            await transaction.RollbackAsync(cancellationToken);
            return false;
        }
        if (!string.Equals(
                storedName,
                confirmationName?.Trim(),
                StringComparison.Ordinal))
        {
            throw new AccountValidationException(
                "Der Gruppenname zur Bestätigung stimmt nicht überein.");
        }

        await using var releaseInvitations = connection.CreateCommand();
        releaseInvitations.Transaction = (SqliteTransaction)transaction;
        releaseInvitations.CommandText =
            """
            UPDATE invitations
            SET group_id = NULL,
                group_role = NULL
            WHERE group_id = $group_id;
            """;
        releaseInvitations.Parameters.AddWithValue("$group_id", groupId);
        await releaseInvitations.ExecuteNonQueryAsync(cancellationToken);

        await using var delete = connection.CreateCommand();
        delete.Transaction = (SqliteTransaction)transaction;
        delete.CommandText =
            "DELETE FROM budget_groups WHERE group_id = $group_id;";
        delete.Parameters.AddWithValue("$group_id", groupId);
        var changed = await delete.ExecuteNonQueryAsync(cancellationToken);
        await transaction.CommitAsync(cancellationToken);
        return changed == 1;
    }

    public async Task SetBudgetGroupMemberAsync(
        string groupId,
        string userId,
        string role,
        CancellationToken cancellationToken = default)
    {
        var normalizedRole = role.Trim().ToLowerInvariant();
        if (normalizedRole is not ("owner" or "manager" or "member"))
        {
            throw new AccountValidationException(
                "Die Gruppenrolle ist ungültig.");
        }

        await using var connection = await store.OpenConnectionAsync(
            cancellationToken);
        try
        {
            await using var command = connection.CreateCommand();
            command.CommandText =
                """
                INSERT INTO budget_group_members(
                    group_id,
                    user_id,
                    role,
                    created_utc
                )
                VALUES ($group_id, $user_id, $role, $now)
                ON CONFLICT(group_id, user_id)
                DO UPDATE SET role = excluded.role;
                """;
            command.Parameters.AddWithValue("$group_id", groupId);
            command.Parameters.AddWithValue("$user_id", userId);
            command.Parameters.AddWithValue("$role", normalizedRole);
            command.Parameters.AddWithValue(
                "$now",
                DateTimeOffset.UtcNow.ToString("O", CultureInfo.InvariantCulture));
            await command.ExecuteNonQueryAsync(cancellationToken);
        }
        catch (SqliteException exception) when (exception.SqliteErrorCode == 19)
        {
            throw new AccountValidationException(
                "Benutzer oder Budgetgruppe wurde nicht gefunden.");
        }
    }

    public async Task<IReadOnlyList<BudgetGroupMemberSummary>> ListGroupMembersAsync(
        string groupId,
        CancellationToken cancellationToken = default)
    {
        var members = new List<BudgetGroupMemberSummary>();
        await using var connection = await store.OpenConnectionAsync(
            cancellationToken);
        await using var command = connection.CreateCommand();
        command.CommandText =
            """
            SELECT
                u.user_id,
                u.display_name,
                u.email,
                m.role,
                u.is_active
            FROM budget_group_members m
            INNER JOIN users u ON u.user_id = m.user_id
            WHERE m.group_id = $group_id
            ORDER BY u.display_name COLLATE NOCASE;
            """;
        command.Parameters.AddWithValue("$group_id", groupId);
        await using var reader = await command.ExecuteReaderAsync(
            cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            members.Add(new BudgetGroupMemberSummary(
                reader.GetString(0),
                reader.GetString(1),
                reader.GetString(2),
                reader.GetString(3),
                reader.GetInt32(4) == 1));
        }
        return members;
    }

    public async Task<InvitationSummary> CreateInvitationAsync(
        CreateInvitationRequest request,
        string adminUserId,
        CancellationToken cancellationToken = default)
    {
        var name = ValidateName(request.Name, "Name");
        var normalizedEmail = NormalizeEmail(request.Email);
        var groupId = string.IsNullOrWhiteSpace(request.GroupId)
            ? null
            : request.GroupId.Trim();
        var role = groupId is null
            ? null
            : NormalizeGroupRole(request.Role ?? "member");
        var token = WebEncoders.Base64UrlEncode(
            RandomNumberGenerator.GetBytes(32));
        var tokenHash = HashToken(token);
        var now = DateTimeOffset.UtcNow;
        var expires = now.AddHours(48);
        var invitationId = Guid.NewGuid().ToString("N");

        await using var connection = await store.OpenConnectionAsync(
            cancellationToken);
        await using (var existing = connection.CreateCommand())
        {
            existing.CommandText =
                "SELECT COUNT(*) FROM users WHERE email_normalized = $email;";
            existing.Parameters.AddWithValue("$email", normalizedEmail);
            if (Convert.ToInt64(
                await existing.ExecuteScalarAsync(cancellationToken),
                CultureInfo.InvariantCulture) != 0)
            {
                throw new AccountValidationException(
                    "Für diese E-Mail-Adresse besteht bereits ein Konto.");
            }
        }

        await using (var transaction = await connection.BeginTransactionAsync(
            cancellationToken))
        {
            await using var command = connection.CreateCommand();
            command.Transaction = (SqliteTransaction)transaction;
            command.CommandText =
                """
                UPDATE invitations
                SET revoked_utc = $now
                WHERE email_normalized = $email
                  AND accepted_utc IS NULL
                  AND revoked_utc IS NULL;

                INSERT INTO invitations(
                    invitation_id,
                    email,
                    email_normalized,
                    suggested_name,
                    token_hash,
                    group_id,
                    group_role,
                    created_by_user_id,
                    created_utc,
                    expires_utc
                )
                VALUES (
                    $invitation_id,
                    $display_email,
                    $email,
                    $name,
                    $token_hash,
                    $group_id,
                    $group_role,
                    $admin_user_id,
                    $now,
                    $expires
                );
                """;
            command.Parameters.AddWithValue("$invitation_id", invitationId);
            command.Parameters.AddWithValue("$display_email", request.Email.Trim());
            command.Parameters.AddWithValue("$email", normalizedEmail);
            command.Parameters.AddWithValue("$name", name);
            command.Parameters.AddWithValue("$token_hash", tokenHash);
            command.Parameters.AddWithValue(
                "$group_id",
                (object?)groupId ?? DBNull.Value);
            command.Parameters.AddWithValue(
                "$group_role",
                (object?)role ?? DBNull.Value);
            command.Parameters.AddWithValue("$admin_user_id", adminUserId);
            command.Parameters.AddWithValue(
                "$now",
                now.ToString("O", CultureInfo.InvariantCulture));
            command.Parameters.AddWithValue(
                "$expires",
                expires.ToString("O", CultureInfo.InvariantCulture));
            try
            {
                await command.ExecuteNonQueryAsync(cancellationToken);
                await transaction.CommitAsync(cancellationToken);
            }
            catch (SqliteException exception) when (exception.SqliteErrorCode == 19)
            {
                throw new AccountValidationException(
                    "Die ausgewählte Budgetgruppe wurde nicht gefunden.");
            }
        }

        try
        {
            await emailSender.SendInvitationAsync(
                request.Email.Trim(),
                name,
                token,
                cancellationToken);
        }
        catch
        {
            await RevokeInvitationAsync(invitationId, cancellationToken);
            throw;
        }

        return new InvitationSummary(
            invitationId,
            name,
            request.Email.Trim(),
            groupId,
            role,
            expires,
            false,
            false);
    }

    public async Task<IReadOnlyList<InvitationSummary>> ListInvitationsAsync(
        CancellationToken cancellationToken = default)
    {
        var invitations = new List<InvitationSummary>();
        await using var connection = await store.OpenConnectionAsync(
            cancellationToken);
        await using var command = connection.CreateCommand();
        command.CommandText =
            """
            SELECT
                invitation_id,
                suggested_name,
                email,
                group_id,
                group_role,
                expires_utc,
                accepted_utc IS NOT NULL,
                revoked_utc IS NOT NULL
            FROM invitations
            ORDER BY created_utc DESC;
            """;
        await using var reader = await command.ExecuteReaderAsync(
            cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            invitations.Add(new InvitationSummary(
                reader.GetString(0),
                reader.GetString(1),
                reader.GetString(2),
                reader.IsDBNull(3) ? null : reader.GetString(3),
                reader.IsDBNull(4) ? null : reader.GetString(4),
                DateTimeOffset.Parse(
                    reader.GetString(5),
                    CultureInfo.InvariantCulture),
                reader.GetInt32(6) == 1,
                reader.GetInt32(7) == 1));
        }
        return invitations;
    }

    public async Task<UserSummary> RegisterWithInvitationAsync(
        RegisterWithInvitationRequest request,
        CancellationToken cancellationToken = default)
    {
        ValidateToken(request.Token);
        ValidatePassword(request.Password);
        var name = ValidateName(request.Name, "Name");
        var now = DateTimeOffset.UtcNow;

        await using var connection = await store.OpenConnectionAsync(
            cancellationToken);
        await using var transaction = await connection.BeginTransactionAsync(
            cancellationToken);

        string email;
        string? groupId;
        string? groupRole;
        await using (var invitation = connection.CreateCommand())
        {
            invitation.Transaction = (SqliteTransaction)transaction;
            invitation.CommandText =
                """
                SELECT email, group_id, group_role
                FROM invitations
                WHERE token_hash = $token_hash
                  AND accepted_utc IS NULL
                  AND revoked_utc IS NULL
                  AND expires_utc > $now
                LIMIT 1;
                """;
            invitation.Parameters.AddWithValue(
                "$token_hash",
                HashToken(request.Token));
            invitation.Parameters.AddWithValue(
                "$now",
                now.ToString("O", CultureInfo.InvariantCulture));
            await using var reader = await invitation.ExecuteReaderAsync(
                cancellationToken);
            if (!await reader.ReadAsync(cancellationToken))
            {
                throw new AccountValidationException(
                    "Die Einladung ist ungültig oder abgelaufen.");
            }
            email = reader.GetString(0);
            groupId = reader.IsDBNull(1) ? null : reader.GetString(1);
            groupRole = reader.IsDBNull(2) ? null : reader.GetString(2);
        }

        var account = CreateAccount(name, email, request.Password, false);
        try
        {
            await InsertUserAsync(
                connection,
                transaction,
                account,
                cancellationToken);
        }
        catch (SqliteException exception) when (exception.SqliteErrorCode == 19)
        {
            throw new AccountValidationException(
                "Für diese E-Mail-Adresse besteht bereits ein Konto.");
        }

        if (groupId is not null)
        {
            await using var membership = connection.CreateCommand();
            membership.Transaction = (SqliteTransaction)transaction;
            membership.CommandText =
                """
                INSERT INTO budget_group_members(
                    group_id,
                    user_id,
                    role,
                    created_utc
                )
                VALUES ($group_id, $user_id, $role, $now);
                """;
            membership.Parameters.AddWithValue("$group_id", groupId);
            membership.Parameters.AddWithValue("$user_id", account.Id);
            membership.Parameters.AddWithValue(
                "$role",
                groupRole ?? "member");
            membership.Parameters.AddWithValue(
                "$now",
                now.ToString("O", CultureInfo.InvariantCulture));
            await membership.ExecuteNonQueryAsync(cancellationToken);
        }

        await using (var accept = connection.CreateCommand())
        {
            accept.Transaction = (SqliteTransaction)transaction;
            accept.CommandText =
                """
                UPDATE invitations
                SET accepted_utc = $now
                WHERE token_hash = $token_hash
                  AND accepted_utc IS NULL
                  AND revoked_utc IS NULL;
                """;
            accept.Parameters.AddWithValue(
                "$now",
                now.ToString("O", CultureInfo.InvariantCulture));
            accept.Parameters.AddWithValue(
                "$token_hash",
                HashToken(request.Token));
            if (await accept.ExecuteNonQueryAsync(cancellationToken) != 1)
            {
                throw new AccountValidationException(
                    "Die Einladung wurde bereits verwendet.");
            }
        }

        await transaction.CommitAsync(cancellationToken);
        return account.ToSummary();
    }

    public async Task RequestPasswordResetAsync(
        string email,
        CancellationToken cancellationToken = default)
    {
        string normalizedEmail;
        try
        {
            normalizedEmail = NormalizeEmail(email);
        }
        catch (AccountValidationException)
        {
            return;
        }

        await using var connection = await store.OpenConnectionAsync(
            cancellationToken);
        var account = await FindUserByEmailAsync(
            connection,
            normalizedEmail,
            cancellationToken);
        if (account is null || !account.IsActive)
        {
            return;
        }

        var token = WebEncoders.Base64UrlEncode(
            RandomNumberGenerator.GetBytes(32));
        var tokenHash = HashToken(token);
        var now = DateTimeOffset.UtcNow;
        var expires = now.AddMinutes(30);
        var resetId = Guid.NewGuid().ToString("N");

        await using (var transaction = await connection.BeginTransactionAsync(
            cancellationToken))
        {
            await using var command = connection.CreateCommand();
            command.Transaction = (SqliteTransaction)transaction;
            command.CommandText =
                """
                UPDATE password_reset_tokens
                SET revoked_utc = $now
                WHERE user_id = $user_id
                  AND used_utc IS NULL
                  AND revoked_utc IS NULL;

                INSERT INTO password_reset_tokens(
                    reset_id,
                    user_id,
                    token_hash,
                    created_utc,
                    expires_utc
                )
                VALUES ($reset_id, $user_id, $token_hash, $now, $expires);
                """;
            command.Parameters.AddWithValue("$reset_id", resetId);
            command.Parameters.AddWithValue("$user_id", account.Id);
            command.Parameters.AddWithValue("$token_hash", tokenHash);
            command.Parameters.AddWithValue(
                "$now",
                now.ToString("O", CultureInfo.InvariantCulture));
            command.Parameters.AddWithValue(
                "$expires",
                expires.ToString("O", CultureInfo.InvariantCulture));
            await command.ExecuteNonQueryAsync(cancellationToken);
            await transaction.CommitAsync(cancellationToken);
        }

        try
        {
            await emailSender.SendPasswordResetAsync(
                account.Email,
                account.DisplayName,
                token,
                cancellationToken);
        }
        catch
        {
            await RevokePasswordResetAsync(resetId, cancellationToken);
            throw;
        }
    }

    public async Task ResetPasswordAsync(
        ResetPasswordRequest request,
        CancellationToken cancellationToken = default)
    {
        ValidateToken(request.Token);
        ValidatePassword(request.Password);
        var now = DateTimeOffset.UtcNow;

        await using var connection = await store.OpenConnectionAsync(
            cancellationToken);
        await using var transaction = await connection.BeginTransactionAsync(
            cancellationToken);

        UserAccount account;
        await using (var find = connection.CreateCommand())
        {
            find.Transaction = (SqliteTransaction)transaction;
            find.CommandText =
                """
                SELECT
                    u.user_id,
                    u.display_name,
                    u.email,
                    u.email_normalized,
                    u.password_hash,
                    u.is_system_admin,
                    u.is_active,
                    u.created_utc,
                    u.updated_utc
                FROM password_reset_tokens r
                INNER JOIN users u ON u.user_id = r.user_id
                WHERE r.token_hash = $token_hash
                  AND r.used_utc IS NULL
                  AND r.revoked_utc IS NULL
                  AND r.expires_utc > $now
                  AND u.is_active = 1
                LIMIT 1;
                """;
            find.Parameters.AddWithValue(
                "$token_hash",
                HashToken(request.Token));
            find.Parameters.AddWithValue(
                "$now",
                now.ToString("O", CultureInfo.InvariantCulture));
            await using var reader = await find.ExecuteReaderAsync(
                cancellationToken);
            if (!await reader.ReadAsync(cancellationToken))
            {
                throw new AccountValidationException(
                    "Der Link ist ungültig oder abgelaufen.");
            }
            account = ReadUser(reader);
        }

        var newPasswordHash = passwordHasher.HashPassword(
            account,
            request.Password);
        await using var update = connection.CreateCommand();
        update.Transaction = (SqliteTransaction)transaction;
        update.CommandText =
            """
            UPDATE users
            SET password_hash = $password_hash,
                updated_utc = $now
            WHERE user_id = $user_id;

            UPDATE password_reset_tokens
            SET used_utc = $now
            WHERE token_hash = $token_hash
              AND used_utc IS NULL
              AND revoked_utc IS NULL;

            UPDATE sessions
            SET revoked_utc = $now
            WHERE user_id = $user_id
              AND revoked_utc IS NULL;
            """;
        update.Parameters.AddWithValue("$password_hash", newPasswordHash);
        update.Parameters.AddWithValue(
            "$now",
            now.ToString("O", CultureInfo.InvariantCulture));
        update.Parameters.AddWithValue("$user_id", account.Id);
        update.Parameters.AddWithValue(
            "$token_hash",
            HashToken(request.Token));
        await update.ExecuteNonQueryAsync(cancellationToken);
        await transaction.CommitAsync(cancellationToken);
    }

    private async Task RevokeInvitationAsync(
        string invitationId,
        CancellationToken cancellationToken)
    {
        await using var connection = await store.OpenConnectionAsync(
            cancellationToken);
        await using var command = connection.CreateCommand();
        command.CommandText =
            """
            UPDATE invitations
            SET revoked_utc = $now
            WHERE invitation_id = $invitation_id
              AND accepted_utc IS NULL;
            """;
        command.Parameters.AddWithValue(
            "$now",
            DateTimeOffset.UtcNow.ToString("O", CultureInfo.InvariantCulture));
        command.Parameters.AddWithValue("$invitation_id", invitationId);
        await command.ExecuteNonQueryAsync(cancellationToken);
    }

    private async Task RevokePasswordResetAsync(
        string resetId,
        CancellationToken cancellationToken)
    {
        await using var connection = await store.OpenConnectionAsync(
            cancellationToken);
        await using var command = connection.CreateCommand();
        command.CommandText =
            """
            UPDATE password_reset_tokens
            SET revoked_utc = $now
            WHERE reset_id = $reset_id
              AND used_utc IS NULL;
            """;
        command.Parameters.AddWithValue(
            "$now",
            DateTimeOffset.UtcNow.ToString("O", CultureInfo.InvariantCulture));
        command.Parameters.AddWithValue("$reset_id", resetId);
        await command.ExecuteNonQueryAsync(cancellationToken);
    }

    private UserAccount CreateAccount(
        string name,
        string email,
        string password,
        bool isSystemAdmin)
    {
        var displayName = ValidateName(name, "Name");
        var normalizedEmail = NormalizeEmail(email);
        ValidatePassword(password);
        var now = DateTimeOffset.UtcNow;
        var account = new UserAccount(
            Guid.NewGuid().ToString("N"),
            displayName,
            email.Trim(),
            normalizedEmail,
            string.Empty,
            isSystemAdmin,
            true,
            now,
            now);
        return account with
        {
            PasswordHash = passwordHasher.HashPassword(account, password),
        };
    }

    private static async Task InsertUserAsync(
        SqliteConnection connection,
        System.Data.Common.DbTransaction? transaction,
        UserAccount account,
        CancellationToken cancellationToken)
    {
        await using var command = connection.CreateCommand();
        command.Transaction = (SqliteTransaction?)transaction;
        command.CommandText =
            """
            INSERT INTO users(
                user_id,
                display_name,
                email,
                email_normalized,
                password_hash,
                is_system_admin,
                is_active,
                created_utc,
                updated_utc
            )
            VALUES (
                $user_id,
                $display_name,
                $email,
                $email_normalized,
                $password_hash,
                $is_system_admin,
                $is_active,
                $created_utc,
                $updated_utc
            );
            """;
        command.Parameters.AddWithValue("$user_id", account.Id);
        command.Parameters.AddWithValue("$display_name", account.DisplayName);
        command.Parameters.AddWithValue("$email", account.Email);
        command.Parameters.AddWithValue(
            "$email_normalized",
            account.EmailNormalized);
        command.Parameters.AddWithValue("$password_hash", account.PasswordHash);
        command.Parameters.AddWithValue(
            "$is_system_admin",
            account.IsSystemAdmin ? 1 : 0);
        command.Parameters.AddWithValue("$is_active", account.IsActive ? 1 : 0);
        command.Parameters.AddWithValue(
            "$created_utc",
            account.CreatedUtc.ToString("O", CultureInfo.InvariantCulture));
        command.Parameters.AddWithValue(
            "$updated_utc",
            account.UpdatedUtc.ToString("O", CultureInfo.InvariantCulture));
        await command.ExecuteNonQueryAsync(cancellationToken);
    }

    private static async Task<UserAccount?> FindUserByEmailAsync(
        SqliteConnection connection,
        string normalizedEmail,
        CancellationToken cancellationToken)
    {
        await using var command = connection.CreateCommand();
        command.CommandText =
            """
            SELECT
                user_id,
                display_name,
                email,
                email_normalized,
                password_hash,
                is_system_admin,
                is_active,
                created_utc,
                updated_utc
            FROM users
            WHERE email_normalized = $email
            LIMIT 1;
            """;
        command.Parameters.AddWithValue("$email", normalizedEmail);
        await using var reader = await command.ExecuteReaderAsync(
            cancellationToken);
        return await reader.ReadAsync(cancellationToken)
            ? ReadUser(reader)
            : null;
    }

    private static UserAccount ReadUser(SqliteDataReader reader) => new(
        reader.GetString(0),
        reader.GetString(1),
        reader.GetString(2),
        reader.GetString(3),
        reader.GetString(4),
        reader.GetInt32(5) == 1,
        reader.GetInt32(6) == 1,
        DateTimeOffset.Parse(reader.GetString(7), CultureInfo.InvariantCulture),
        DateTimeOffset.Parse(reader.GetString(8), CultureInfo.InvariantCulture));

    private static string NormalizeEmail(string email)
    {
        var trimmed = email?.Trim() ?? string.Empty;
        if (trimmed.Length is < 3 or > 254)
        {
            throw new AccountValidationException(
                "Bitte gib eine gültige E-Mail-Adresse ein.");
        }
        try
        {
            var parsed = new MailAddress(trimmed);
            if (!string.Equals(
                parsed.Address,
                trimmed,
                StringComparison.OrdinalIgnoreCase))
            {
                throw new FormatException();
            }
        }
        catch (FormatException)
        {
            throw new AccountValidationException(
                "Bitte gib eine gültige E-Mail-Adresse ein.");
        }
        return trimmed.ToUpperInvariant();
    }

    private static string ValidateName(string name, string fieldName)
    {
        var trimmed = name?.Trim() ?? string.Empty;
        if (trimmed.Length is < 2 or > 80)
        {
            throw new AccountValidationException(
                fieldName + " muss zwischen 2 und 80 Zeichen lang sein.");
        }
        return trimmed;
    }

    private static void ValidatePassword(string password)
    {
        if (password is null || password.Length is < 8 or > 256)
        {
            throw new AccountValidationException(
                "Das Kennwort muss mindestens 8 Zeichen lang sein.");
        }
    }

    private static void ValidateToken(string token)
    {
        if (string.IsNullOrWhiteSpace(token) || token.Length is < 32 or > 256)
        {
            throw new AccountValidationException(
                "Der Link ist ungültig oder abgelaufen.");
        }
    }

    private static string NormalizeGroupRole(string role)
    {
        var normalized = role.Trim().ToLowerInvariant();
        return normalized is "owner" or "manager" or "member"
            ? normalized
            : throw new AccountValidationException(
                "Die Gruppenrolle ist ungültig.");
    }

    private static string HashToken(string token) => Convert.ToHexString(
        SHA256.HashData(Encoding.UTF8.GetBytes(token)));

    private static string Limit(string value, int maxLength)
    {
        if (string.IsNullOrEmpty(value))
        {
            return string.Empty;
        }
        return value.Length <= maxLength ? value : value[..maxLength];
    }
}
