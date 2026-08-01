using MailKit.Net.Smtp;
using MailKit.Security;
using Microsoft.Extensions.Options;
using MimeKit;

namespace MeineBudgetwelt.Server.Accounts;

public sealed class AccountEmailOptions
{
    public string Host { get; init; } = string.Empty;
    public int Port { get; init; } = 587;
    public string Username { get; init; } = string.Empty;
    public string FromAddress { get; init; } = string.Empty;
    public string FromName { get; init; } = "Meine Budgetwelt";
    public string Security { get; init; } = "StartTls";
    public string PublicBaseUrl { get; init; } = string.Empty;
}

public interface IAccountEmailSender
{
    Task SendInvitationAsync(
        string email,
        string name,
        string token,
        CancellationToken cancellationToken);

    Task SendPasswordResetAsync(
        string email,
        string name,
        string token,
        CancellationToken cancellationToken);
}

public sealed class AccountEmailSender(
    IOptions<AccountEmailOptions> options,
    ILogger<AccountEmailSender> logger) : IAccountEmailSender
{
    private const string SmtpPasswordEnvironmentVariable =
        "BUDGETWELT_SMTP_PASSWORD";
    private const string PickupDirectoryEnvironmentVariable =
        "BUDGETWELT_EMAIL_PICKUP_DIR";
    private readonly AccountEmailOptions _options = options.Value;

    public Task SendInvitationAsync(
        string email,
        string name,
        string token,
        CancellationToken cancellationToken)
    {
        var link = BuildLink("konto-erstellen", token);
        return SendAsync(
            email,
            name,
            "Einladung zu Meine Budgetwelt",
            "Hallo " + name + ",\n\n"
                + "über diesen einmaligen Link kannst du dein Konto erstellen:\n"
                + link + "\n\n"
                + "Der Link ist 48 Stunden gültig.",
            cancellationToken);
    }

    public Task SendPasswordResetAsync(
        string email,
        string name,
        string token,
        CancellationToken cancellationToken)
    {
        var link = BuildLink("kennwort-zuruecksetzen", token);
        return SendAsync(
            email,
            name,
            "Kennwort für Meine Budgetwelt zurücksetzen",
            "Hallo " + name + ",\n\n"
                + "über diesen einmaligen Link kannst du ein neues Kennwort vergeben:\n"
                + link + "\n\n"
                + "Der Link ist 30 Minuten gültig. Falls du das nicht angefordert hast, "
                + "kannst du diese Nachricht ignorieren.",
            cancellationToken);
    }

    private async Task SendAsync(
        string email,
        string name,
        string subject,
        string body,
        CancellationToken cancellationToken)
    {
        var message = CreateMessage(email, name, subject, body);
        var pickupDirectory = Environment.GetEnvironmentVariable(
            PickupDirectoryEnvironmentVariable);
        if (!string.IsNullOrWhiteSpace(pickupDirectory))
        {
            var fullDirectory = Path.GetFullPath(pickupDirectory);
            Directory.CreateDirectory(fullDirectory);
            var filePath = Path.Combine(
                fullDirectory,
                DateTimeOffset.UtcNow.ToString("yyyyMMddHHmmssfff")
                    + "-"
                    + Guid.NewGuid().ToString("N")
                    + ".eml");
            await message.WriteToAsync(filePath, cancellationToken);
            logger.LogInformation(
                "Kontonachricht in isoliertes Abholverzeichnis geschrieben: {FilePath}",
                filePath);
            return;
        }

        ValidateSmtpConfiguration();
        var smtpPassword = Environment.GetEnvironmentVariable(
            SmtpPasswordEnvironmentVariable);
        if (string.IsNullOrWhiteSpace(smtpPassword))
        {
            throw new AccountEmailException(
                "Der SMTP-Kennwortschlüssel ist nicht konfiguriert.");
        }

        try
        {
            using var client = new SmtpClient();
            await client.ConnectAsync(
                _options.Host,
                _options.Port,
                ParseSecurity(_options.Security),
                cancellationToken);
            await client.AuthenticateAsync(
                _options.Username,
                smtpPassword,
                cancellationToken);
            await client.SendAsync(message, cancellationToken);
            await client.DisconnectAsync(true, cancellationToken);
        }
        catch (Exception exception) when (
            exception is not AccountEmailException
            && exception is not OperationCanceledException)
        {
            logger.LogError(exception, "Kontonachricht konnte nicht versendet werden.");
            throw new AccountEmailException(
                "Die E-Mail konnte derzeit nicht versendet werden.",
                exception);
        }
    }

    private MimeMessage CreateMessage(
        string email,
        string name,
        string subject,
        string body)
    {
        if (string.IsNullOrWhiteSpace(_options.FromAddress))
        {
            throw new AccountEmailException(
                "Die Absenderadresse ist nicht konfiguriert.");
        }

        var message = new MimeMessage();
        message.From.Add(new MailboxAddress(
            _options.FromName,
            _options.FromAddress));
        message.To.Add(new MailboxAddress(name, email));
        message.Subject = subject;
        message.Body = new TextPart("plain") { Text = body };
        return message;
    }

    private string BuildLink(string path, string token)
    {
        if (
            !Uri.TryCreate(
                _options.PublicBaseUrl,
                UriKind.Absolute,
                out var baseUri)
            || (baseUri.Scheme != Uri.UriSchemeHttps
                && !baseUri.IsLoopback)
        )
        {
            throw new AccountEmailException(
                "Die öffentliche HTTPS-Adresse ist nicht konfiguriert.");
        }

        return new Uri(
            baseUri,
            path + "?token=" + Uri.EscapeDataString(token)).AbsoluteUri;
    }

    private void ValidateSmtpConfiguration()
    {
        if (
            string.IsNullOrWhiteSpace(_options.Host)
            || _options.Port is < 1 or > 65535
            || string.IsNullOrWhiteSpace(_options.Username)
        )
        {
            throw new AccountEmailException(
                "Der SMTP-Versand ist nicht vollständig konfiguriert.");
        }
    }

    private static SecureSocketOptions ParseSecurity(string value) =>
        value.Trim().ToLowerInvariant() switch
        {
            "starttls" => SecureSocketOptions.StartTls,
            "sslonconnect" => SecureSocketOptions.SslOnConnect,
            _ => throw new AccountEmailException(
                "Für SMTP ist ausschließlich StartTls oder SslOnConnect erlaubt."),
        };
}
