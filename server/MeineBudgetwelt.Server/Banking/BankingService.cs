using System.Globalization;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using MeineBudgetwelt.Server.Storage;
using MeineBudgetwelt.Server.Sync;

namespace MeineBudgetwelt.Server.Banking;

public sealed class BankingService(
    SqliteStore store,
    SyncService sync,
    EnableBankingClient provider)
{
    private const int MaximumKnownImportIds = 5_000;
    private const int MaximumPreviewTransactions = 5_000;

    public bool IsConfigured => provider.IsConfigured;

    public Task<IReadOnlyList<BankInstitution>> ListInstitutionsAsync(
        string? country,
        CancellationToken cancellationToken) =>
        provider.ListInstitutionsAsync(
            string.IsNullOrWhiteSpace(country) ? provider.DefaultCountry : country,
            cancellationToken);

    public async Task<IReadOnlyList<BankConnectionSummary>> ListConnectionsAsync(
        string groupId,
        string userId,
        CancellationToken cancellationToken)
    {
        await sync.EnsureMembershipAsync(groupId, userId, cancellationToken);
        await using var connection = await store.OpenConnectionAsync(cancellationToken);
        await using var command = connection.CreateCommand();
        command.CommandText =
            """
            SELECT
                connection_id,
                institution_id,
                institution_name,
                status,
                created_utc,
                updated_utc,
                last_refresh_utc,
                account_ids_json
            FROM bank_connections
            WHERE group_id = $group_id
            ORDER BY created_utc DESC;
            """;
        command.Parameters.AddWithValue("$group_id", groupId);
        var result = new List<BankConnectionSummary>();
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            result.Add(ToSummary(
                reader.GetString(0),
                reader.GetString(1),
                reader.GetString(2),
                reader.GetString(3),
                reader.GetString(4),
                reader.GetString(5),
                reader.IsDBNull(6) ? null : reader.GetString(6),
                reader.GetString(7)));
        }
        return result;
    }

    public async Task<CreatedBankConnection> CreateConnectionAsync(
        string groupId,
        string userId,
        CreateBankConnectionRequest request,
        CancellationToken cancellationToken)
    {
        await EnsureCanManageAsync(groupId, userId, cancellationToken);
        var institutionId = request.InstitutionId?.Trim() ?? string.Empty;
        if (
            institutionId.Length is < 3 or > 160
            || !institutionId.All(character =>
                char.IsLetterOrDigit(character) || character is '_' or '-')
        )
        {
            throw new BankingValidationException("Die ausgewählte Bank ist ungültig.");
        }

        var institutions = await provider.ListInstitutionsAsync(
            provider.DefaultCountry,
            cancellationToken);
        var institution = institutions.FirstOrDefault(item =>
            string.Equals(item.Id, institutionId, StringComparison.Ordinal));
        if (institution is null)
        {
            throw new BankingValidationException(
                "Die ausgewählte Bank ist für das konfigurierte Land nicht verfügbar.");
        }

        var connectionId = Guid.NewGuid().ToString("N");
        var redirectUrl =
            $"{provider.RedirectBaseUrl}/api/banking/callback";
        var authorization = await provider.StartAuthorizationAsync(
            institution,
            provider.DefaultCountry,
            redirectUrl,
            connectionId,
            cancellationToken);
        var now = DateTimeOffset.UtcNow;
        await using (var connection = await store.OpenConnectionAsync(cancellationToken))
        await using (var command = connection.CreateCommand())
        {
            command.CommandText =
                """
                INSERT INTO bank_connections(
                    connection_id,
                    group_id,
                    created_by_user_id,
                    provider,
                    provider_reference,
                    institution_id,
                    institution_name,
                    status,
                    account_ids_json,
                    created_utc,
                    updated_utc,
                    last_refresh_utc
                )
                VALUES (
                    $connection_id,
                    $group_id,
                    $user_id,
                    $provider,
                    $provider_reference,
                    $institution_id,
                    $institution_name,
                    $status,
                    '[]',
                    $created_utc,
                    $updated_utc,
                    NULL
                );
                """;
            command.Parameters.AddWithValue("$connection_id", connectionId);
            command.Parameters.AddWithValue("$group_id", groupId);
            command.Parameters.AddWithValue("$user_id", userId);
            command.Parameters.AddWithValue("$provider", EnableBankingClient.ProviderId);
            command.Parameters.AddWithValue("$provider_reference", authorization.Id);
            command.Parameters.AddWithValue("$institution_id", institution.Id);
            command.Parameters.AddWithValue("$institution_name", institution.Name);
            command.Parameters.AddWithValue("$status", NormalizeStatus(authorization.Status));
            command.Parameters.AddWithValue("$created_utc", now.ToString("O", CultureInfo.InvariantCulture));
            command.Parameters.AddWithValue("$updated_utc", now.ToString("O", CultureInfo.InvariantCulture));
            await command.ExecuteNonQueryAsync(cancellationToken);
        }

        return new CreatedBankConnection(
            new BankConnectionSummary(
                connectionId,
                institution.Id,
                institution.Name,
                NormalizeStatus(authorization.Status),
                now,
                now,
                null,
                0),
            authorization.Link);
    }

    public async Task<bool> CompleteCallbackAsync(
        string connectionId,
        string code,
        CancellationToken cancellationToken)
    {
        var stored = await GetConnectionByIdAsync(connectionId, cancellationToken);
        if (stored is null)
        {
            return false;
        }
        if (!string.Equals(stored.Provider, EnableBankingClient.ProviderId, StringComparison.Ordinal))
        {
            return false;
        }
        var session = await provider.AuthorizeSessionAsync(code, cancellationToken);
        await UpdateProviderStateAsync(
            stored.ConnectionId,
            session,
            false,
            cancellationToken);
        return string.Equals(
            session.Status,
            "AUTHORIZED",
            StringComparison.OrdinalIgnoreCase);
    }

    public async Task RejectCallbackAsync(
        string connectionId,
        CancellationToken cancellationToken)
    {
        var stored = await GetConnectionByIdAsync(connectionId, cancellationToken);
        if (stored is null)
        {
            return;
        }
        var now = DateTimeOffset.UtcNow;
        await using var connection = await store.OpenConnectionAsync(cancellationToken);
        await using var command = connection.CreateCommand();
        command.CommandText =
            "UPDATE bank_connections SET status = 'rejected', updated_utc = $updated_utc WHERE connection_id = $connection_id AND provider = 'enable-banking';";
        command.Parameters.AddWithValue("$updated_utc", now.ToString("O", CultureInfo.InvariantCulture));
        command.Parameters.AddWithValue("$connection_id", connectionId);
        await command.ExecuteNonQueryAsync(cancellationToken);
    }

    public async Task<BankRefreshPreview> RefreshAsync(
        string groupId,
        string userId,
        string connectionId,
        RefreshBankConnectionRequest request,
        CancellationToken cancellationToken)
    {
        await sync.EnsureMembershipAsync(groupId, userId, cancellationToken);
        var stored = await GetConnectionAsync(
            groupId,
            connectionId,
            cancellationToken);
        var knownIds = (request.KnownImportIds ?? [])
            .Where(value => !string.IsNullOrWhiteSpace(value))
            .Take(MaximumKnownImportIds + 1)
            .ToHashSet(StringComparer.Ordinal);
        if (knownIds.Count > MaximumKnownImportIds)
        {
            throw new BankingValidationException(
                "Es wurden zu viele bekannte Bankbuchungen übermittelt.");
        }
        if (!string.Equals(stored.Provider, EnableBankingClient.ProviderId, StringComparison.Ordinal))
        {
            throw new BankingValidationException(
                "Diese ältere Bankfreigabe wird nicht mehr unterstützt. Bitte trennen und neu verbinden.");
        }

        var session = await provider.GetSessionAsync(
            stored.ProviderReference,
            cancellationToken);
        await UpdateProviderStateAsync(
            stored.ConnectionId,
            session,
            true,
            cancellationToken);
        if (!string.Equals(session.Status, "AUTHORIZED", StringComparison.OrdinalIgnoreCase))
        {
            throw new BankingValidationException(
                session.Status.Equals("EXPIRED", StringComparison.OrdinalIgnoreCase)
                    ? "Die Bankfreigabe ist abgelaufen und muss erneuert werden."
                    : "Die Bankverbindung ist noch nicht vollständig freigegeben.");
        }

        var balances = new List<BankBalancePreview>();
        var transactions = new List<BankTransactionPreview>();
        foreach (var accountId in session.Accounts)
        {
            var accountReference = AccountReference(accountId);
            using var balanceDocument = await provider.GetBalancesAsync(
                accountId,
                cancellationToken);
            var balance = ParseBalance(
                balanceDocument.RootElement,
                accountReference);
            if (balance is not null)
            {
                balances.Add(balance);
            }

            using var transactionDocument = await provider.GetTransactionsAsync(
                accountId,
                cancellationToken);
            ParseTransactions(
                transactionDocument.RootElement,
                accountId,
                accountReference,
                knownIds,
                transactions);
            if (transactions.Count > MaximumPreviewTransactions)
            {
                throw new BankingProviderException(
                    "Die Bank hat für eine einzelne Aktualisierung zu viele Buchungen geliefert.");
            }
        }

        var now = DateTimeOffset.UtcNow;
        return new BankRefreshPreview(
            stored.ConnectionId,
            stored.InstitutionName,
            now,
            balances,
            transactions
                .OrderByDescending(item => item.BookingDate)
                .ThenBy(item => item.ImportId, StringComparer.Ordinal)
                .ToArray(),
            transactions.Count(item => item.AlreadyImported));
    }

    public async Task DisconnectAsync(
        string groupId,
        string userId,
        string connectionId,
        CancellationToken cancellationToken)
    {
        await EnsureCanManageAsync(groupId, userId, cancellationToken);
        var stored = await GetConnectionAsync(groupId, connectionId, cancellationToken);
        if (string.Equals(stored.Provider, EnableBankingClient.ProviderId, StringComparison.Ordinal))
        {
            await provider.DeleteSessionAsync(stored.ProviderReference, cancellationToken);
        }
        await using var connection = await store.OpenConnectionAsync(cancellationToken);
        await using var command = connection.CreateCommand();
        command.CommandText =
            "DELETE FROM bank_connections WHERE connection_id = $connection_id AND group_id = $group_id;";
        command.Parameters.AddWithValue("$connection_id", connectionId);
        command.Parameters.AddWithValue("$group_id", groupId);
        await command.ExecuteNonQueryAsync(cancellationToken);
    }

    private async Task EnsureCanManageAsync(
        string groupId,
        string userId,
        CancellationToken cancellationToken)
    {
        var role = await sync.GetMembershipRoleAsync(
            groupId,
            userId,
            cancellationToken);
        if (role is not "owner" and not "manager")
        {
            throw new BankingAccessDeniedException();
        }
    }

    private async Task<StoredBankConnection> GetConnectionAsync(
        string groupId,
        string connectionId,
        CancellationToken cancellationToken)
    {
        var result = await GetConnectionByIdAsync(connectionId, cancellationToken);
        if (result is null || !string.Equals(result.GroupId, groupId, StringComparison.Ordinal))
        {
            throw new BankingValidationException("Die Bankverbindung wurde nicht gefunden.");
        }
        return result;
    }

    private async Task<StoredBankConnection?> GetConnectionByIdAsync(
        string connectionId,
        CancellationToken cancellationToken)
    {
        if (
            connectionId.Length != 32
            || !connectionId.All(Uri.IsHexDigit)
        )
        {
            return null;
        }
        await using var connection = await store.OpenConnectionAsync(cancellationToken);
        await using var command = connection.CreateCommand();
        command.CommandText =
            """
            SELECT
                connection_id,
                group_id,
                provider,
                provider_reference,
                institution_id,
                institution_name,
                status,
                account_ids_json,
                created_utc,
                updated_utc,
                last_refresh_utc
            FROM bank_connections
            WHERE connection_id = $connection_id
            LIMIT 1;
            """;
        command.Parameters.AddWithValue("$connection_id", connectionId);
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        if (!await reader.ReadAsync(cancellationToken))
        {
            return null;
        }
        return new StoredBankConnection(
            reader.GetString(0),
            reader.GetString(1),
            reader.GetString(2),
            reader.GetString(3),
            reader.GetString(4),
            reader.GetString(5),
            reader.GetString(6),
            reader.GetString(7),
            ParseDate(reader.GetString(8)),
            ParseDate(reader.GetString(9)),
            reader.IsDBNull(10) ? null : ParseDate(reader.GetString(10)));
    }

    private async Task UpdateProviderStateAsync(
        string connectionId,
        ProviderSession session,
        bool refreshed,
        CancellationToken cancellationToken)
    {
        var now = DateTimeOffset.UtcNow;
        await using var connection = await store.OpenConnectionAsync(cancellationToken);
        await using var command = connection.CreateCommand();
        command.CommandText =
            """
            UPDATE bank_connections
            SET provider_reference = $provider_reference,
                status = $status,
                account_ids_json = $accounts,
                updated_utc = $updated_utc,
                last_refresh_utc = CASE
                    WHEN $refreshed = 1 THEN $updated_utc
                    ELSE last_refresh_utc
                END
            WHERE connection_id = $connection_id;
            """;
        command.Parameters.AddWithValue("$provider_reference", session.Id);
        command.Parameters.AddWithValue("$status", NormalizeStatus(session.Status));
        command.Parameters.AddWithValue(
            "$accounts",
            JsonSerializer.Serialize(session.Accounts));
        command.Parameters.AddWithValue("$updated_utc", now.ToString("O", CultureInfo.InvariantCulture));
        command.Parameters.AddWithValue("$refreshed", refreshed ? 1 : 0);
        command.Parameters.AddWithValue("$connection_id", connectionId);
        await command.ExecuteNonQueryAsync(cancellationToken);
    }

    private static BankBalancePreview? ParseBalance(
        JsonElement root,
        string accountReference)
    {
        if (
            !root.TryGetProperty("balances", out var values)
            || values.ValueKind != JsonValueKind.Array
        )
        {
            return null;
        }
        var priorities = new[]
        {
            "ITAV",
            "CLAV",
            "CLBD",
            "XPCD",
        };
        foreach (var preferredType in priorities)
        {
            foreach (var balance in values.EnumerateArray())
            {
                if (!string.Equals(
                    EnableBankingClient.GetString(balance, "balance_type"),
                    preferredType,
                    StringComparison.OrdinalIgnoreCase))
                {
                    continue;
                }
                if (TryReadAmount(balance, "balance_amount", out var amount, out var currency))
                {
                    return new BankBalancePreview(
                        accountReference,
                        currency,
                        amount,
                        preferredType);
                }
            }
        }
        foreach (var balance in values.EnumerateArray())
        {
            if (TryReadAmount(balance, "balance_amount", out var amount, out var currency))
            {
                return new BankBalancePreview(
                    accountReference,
                    currency,
                    amount,
                    EnableBankingClient.GetString(balance, "balance_type"));
            }
        }
        return null;
    }

    private static void ParseTransactions(
        JsonElement root,
        string accountId,
        string accountReference,
        HashSet<string> knownIds,
        List<BankTransactionPreview> result)
    {
        if (
            !root.TryGetProperty("transactions", out var values)
            || values.ValueKind != JsonValueKind.Array
        )
        {
            return;
        }
        foreach (var transaction in values.EnumerateArray())
        {
            if (!TryReadAmount(transaction, "transaction_amount", out var rawAmount, out var currency))
            {
                continue;
            }
            var indicator = EnableBankingClient.GetString(
                transaction,
                "credit_debit_indicator");
            var signedAmount = indicator.ToUpperInvariant() switch
            {
                "DBIT" => -Math.Abs(rawAmount),
                "CRDT" => Math.Abs(rawAmount),
                _ => rawAmount,
            };
            var dateText = EnableBankingClient.GetString(transaction, "booking_date");
            if (string.IsNullOrWhiteSpace(dateText))
            {
                dateText = EnableBankingClient.GetString(transaction, "value_date");
            }
            if (!DateOnly.TryParseExact(
                dateText,
                "yyyy-MM-dd",
                CultureInfo.InvariantCulture,
                DateTimeStyles.None,
                out var bookingDate))
            {
                continue;
            }
            var description = TransactionDescription(transaction, signedAmount);
            var status = NormalizeTransactionStatus(
                EnableBankingClient.GetString(transaction, "status"));
            var importId = TransactionImportId(
                transaction,
                accountId,
                bookingDate,
                signedAmount,
                currency,
                description);
            result.Add(new BankTransactionPreview(
                importId,
                accountReference,
                status,
                signedAmount >= 0 ? "income" : "expense",
                Math.Abs(signedAmount),
                currency,
                bookingDate,
                description,
                knownIds.Contains(importId)));
        }
    }

    private static bool TryReadAmount(
        JsonElement parent,
        string property,
        out decimal amount,
        out string currency)
    {
        amount = 0;
        currency = string.Empty;
        if (
            !parent.TryGetProperty(property, out var value)
            || value.ValueKind != JsonValueKind.Object
        )
        {
            return false;
        }
        var amountText = EnableBankingClient.GetString(value, "amount");
        currency = EnableBankingClient.GetString(value, "currency").ToUpperInvariant();
        return currency.Length == 3
            && decimal.TryParse(
                amountText,
                NumberStyles.Number | NumberStyles.AllowLeadingSign,
                CultureInfo.InvariantCulture,
                out amount);
    }

    private static string TransactionDescription(
        JsonElement transaction,
        decimal signedAmount)
    {
        var parts = new List<string>();
        var counterparty = GetNestedString(
            transaction,
            signedAmount < 0 ? "creditor" : "debtor",
            "name");
        if (!string.IsNullOrWhiteSpace(counterparty))
        {
            parts.Add(counterparty.Trim());
        }
        if (
            transaction.TryGetProperty("remittance_information", out var remittance)
            && remittance.ValueKind == JsonValueKind.Array
        )
        {
            foreach (var item in remittance.EnumerateArray())
            {
                var value = item.ValueKind == JsonValueKind.String
                    ? item.GetString()?.Trim() ?? string.Empty
                    : string.Empty;
                if (
                    !string.IsNullOrWhiteSpace(value)
                    && !parts.Contains(value, StringComparer.OrdinalIgnoreCase)
                )
                {
                    parts.Add(value);
                }
            }
        }
        foreach (var property in new[]
        {
            "note",
            "reference_number",
        })
        {
            var value = EnableBankingClient.GetString(transaction, property).Trim();
            if (
                !string.IsNullOrWhiteSpace(value)
                && !parts.Contains(value, StringComparer.OrdinalIgnoreCase)
            )
            {
                parts.Add(value);
            }
        }
        var result = string.Join(" · ", parts);
        if (string.IsNullOrWhiteSpace(result))
        {
            result = "Bankbuchung";
        }
        return result.Length <= 280 ? result : result[..280];
    }

    private static string TransactionImportId(
        JsonElement transaction,
        string accountId,
        DateOnly bookingDate,
        decimal amount,
        string currency,
        string description)
    {
        var providerId = EnableBankingClient.GetString(transaction, "entry_reference");
        if (string.IsNullOrWhiteSpace(providerId))
        {
            providerId = EnableBankingClient.GetString(
                transaction,
                "transaction_id");
        }
        var source = !string.IsNullOrWhiteSpace(providerId)
            ? $"enable-banking|{accountId}|provider|{providerId}"
            : string.Join('|',
                "enable-banking",
                accountId,
                bookingDate.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture),
                amount.ToString("0.00####", CultureInfo.InvariantCulture),
                currency,
                description.Trim().ToLowerInvariant());
        return "eb_" + Convert.ToHexString(
            SHA256.HashData(Encoding.UTF8.GetBytes(source)))
            .ToLowerInvariant();
    }

    private static string AccountReference(string accountId) =>
        "Konto " + Convert.ToHexString(
            SHA256.HashData(Encoding.UTF8.GetBytes(accountId)))[..8];

    private static BankConnectionSummary ToSummary(
        string id,
        string institutionId,
        string institutionName,
        string status,
        string created,
        string updated,
        string? lastRefresh,
        string accountsJson) =>
        new(
            id,
            institutionId,
            institutionName,
            status,
            ParseDate(created),
            ParseDate(updated),
            lastRefresh is null ? null : ParseDate(lastRefresh),
            ParseAccounts(accountsJson).Count);

    private static DateTimeOffset ParseDate(string value) =>
        DateTimeOffset.Parse(value, CultureInfo.InvariantCulture);

    private static IReadOnlyList<string> ParseAccounts(string json)
    {
        try
        {
            return JsonSerializer.Deserialize<string[]>(json) ?? [];
        }
        catch (JsonException)
        {
            return [];
        }
    }

    private static string NormalizeStatus(string status) =>
        status.Trim().ToUpperInvariant() switch
        {
            "AUTHORIZED" => "linked",
            "EXPIRED" => "expired",
            "CANCELLED" or "CLOSED" or "INVALID" or "REJECTED" or "REVOKED" or "ERROR" => "rejected",
            "PENDING_AUTHORIZATION" or "RETURNED_FROM_BANK" => "authorizing",
            _ => "unknown",
        };

    private static string NormalizeTransactionStatus(string status) =>
        status.Trim().ToUpperInvariant() switch
        {
            "BOOK" => "booked",
            "PDNG" or "HOLD" or "SCHD" => "pending",
            _ => "other",
        };

    private static string GetNestedString(
        JsonElement element,
        string property,
        string nestedProperty) =>
        element.TryGetProperty(property, out var nested)
            && nested.ValueKind == JsonValueKind.Object
                ? EnableBankingClient.GetString(nested, nestedProperty)
                : string.Empty;

    private sealed record StoredBankConnection(
        string ConnectionId,
        string GroupId,
        string Provider,
        string ProviderReference,
        string InstitutionId,
        string InstitutionName,
        string Status,
        string AccountIdsJson,
        DateTimeOffset CreatedUtc,
        DateTimeOffset UpdatedUtc,
        DateTimeOffset? LastRefreshUtc);
}
