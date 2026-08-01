# Meine Budgetwelt Server

Der Server ist der gemeinsame, selbst gehostete Daten- und
Authentifizierungsdienst für Windows-App und PWA. Er wird als eigener
Windows-Dienst installiert und verändert keine bereits vorhandene Datenbank.

## Isolation

- Dienstname: `MeineBudgetweltServer`
- Standardbindung: `http://127.0.0.1:48732`
- Programm: `C:\Program Files\Meine Budgetwelt Server`
- Daten: `C:\ProgramData\Meine Budgetwelt Server\data`
- Sicherungen: `C:\ProgramData\Meine Budgetwelt Server\backups`
- Protokolle: `C:\ProgramData\Meine Budgetwelt Server\logs`

Die eingebettete SQLite-Datei benötigt keinen eigenen Datenbankdienst und
öffnet keinen Datenbankport. Für Entwicklung und Tests kann das Datenverzeichnis
mit `BUDGETWELT_DATA_DIR` überschrieben werden.

## Lokaler Start

```powershell
$env:BUDGETWELT_DATA_DIR = 'C:\tmp\MeineBudgetweltServer-Entwicklung'
dotnet run --project .\server\MeineBudgetwelt.Server -- \
  --Server:ListenUrl=http://127.0.0.1:48732
```

Der Gesundheitsstatus ist danach unter
`http://127.0.0.1:48732/health` erreichbar.
Die responsive Admin-Oberfläche liegt unter
`http://127.0.0.1:48732/admin/`.

## Erstes Administratorkonto

Das erste Konto wird vor der Freigabe des Reverse-Proxys einmalig angelegt.
Das Kennwort wird nicht als Befehlszeilenargument übergeben:

```powershell
$env:BUDGETWELT_DATA_DIR = 'C:\ProgramData\Meine Budgetwelt Server'
$env:BUDGETWELT_BOOTSTRAP_PASSWORD = '<mindestens 8 Zeichen>'
& '.\Meine-Budgetwelt-Server.exe' bootstrap-admin --name 'Administrator' --email 'admin@example.de'
```

Nach dem ersten Konto verweigert der Server einen weiteren Bootstrap. Das
Administratorkonto besitzt automatisch eine persönliche Budgetgruppe.

## Bereits vorhandene Konto-API

- PWA-Anmeldung über sicheres, nicht per JavaScript lesbares Sitzungscookie;
- Desktop-Anmeldung über ein widerrufbares Bearer-Token;
- angemeldetes Profil und Abmeldung;
- Benutzer anlegen, auflisten, sperren und wieder aktivieren;
- gemeinsame Budgetgruppen und Rollen `owner`, `manager`, `member`;
- einmalige Einladungen mit 48 Stunden Laufzeit;
- Kontoerstellung durch den eingeladenen Benutzer;
- Kennwort-Zurücksetzen über einen 30 Minuten gültigen Einmallink;
- Widerruf aller Sitzungen nach einer Kennwortänderung;
- Anmeldebegrenzung pro Client-IP;
- sofortiger Sitzungswiderruf bei Kontosperre.

Für den E-Mail-Versand werden SMTP-Host, Port, Benutzer, Absender und die
öffentliche HTTPS-Adresse im Abschnitt `Email` der externen
`appsettings.json` gesetzt. Das SMTP-Kennwort liegt ausschließlich in
`BUDGETWELT_SMTP_PASSWORD`. `StartTls` oder `SslOnConnect` ist
verpflichtend; unverschlüsseltes SMTP wird verweigert.

Die sichtbare Admin-Oberfläche verwaltet Benutzer, Sperren, Budgetgruppen,
Rollen und Einladungen. Der Installer öffnet keinen Port in der Firewall und
verändert keine bestehende Datenbank oder einen fremden Dienst.

## Windows-Installer

```powershell
powershell -NoProfile -ExecutionPolicy Bypass \
  -File .\tools\build-server-installer.ps1
```

Das Setup fragt lokalen Port sowie Name, E-Mail und Kennwort des ersten Admins
ab. Das Kennwort wird nur über die vererbte Prozessumgebung an den Bootstrap
gegeben und weder in Befehlszeile noch Installerprotokoll geschrieben. Der
Der Dienst läuft als `LocalService`, bindet ausschließlich an Loopback und erhält
nur Änderungsrechte am eigenen Datenstamm. Vor einem Update wird über den
Serverbefehl `backup` eine Sicherung erzeugt; bei fehlerhaftem Start wird die
vorherige vollständige Programmversion wiederhergestellt. Eine Deinstallation entfernt
Programm und Dienst, behält aber Konfiguration, Datenbank und Sicherungen.

Das Setup richtet zusätzlich die geplante Aufgabe
`MeineBudgetweltServerUpdater` als `SYSTEM` ein. Sie prüft fünf Minuten nach
einem Systemstart und täglich um 03:15 Uhr den stabilen GitHub-Kanal
`server-updates`. Nur ein neueres Manifest mit gültiger RSA-Signatur und ein
Installer mit passender SHA-256-Prüfsumme werden ausgeführt. Der Serverdienst
selbst bleibt weiterhin auf das eingeschränkte `LocalService`-Konto begrenzt.

Der isolierte Installationslauf benötigt ein administratives PowerShell-
Fenster:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass \
  -File .\tools\verify-server-installer.ps1
```

Der E2E-Test umfasst Erstinstallation, Dienst, geplante Updateaufgabe,
Admin-Anmeldung, erneute Installation als Update, vorherige Datensicherung,
Gesundheit nach dem Update sowie Deinstallation mit Datenerhalt. Konto-,
Gruppen-, Einladungs-, Reset- und fachliche Synchronisationsendpunkte sind
ebenfalls implementiert und geprüft.

## Caddy und öffentliche Domain

Der vorbereitete Block für `budget.leno.info` liegt unter
`ops/caddy/budget.leno.info.caddy`. Er aktiviert Kompression und HSTS und leitet
nur intern auf `127.0.0.1:48732` weiter. Vor dem Neuladen auf dem Root-Server:

```powershell
caddy validate --config C:\Pfad\zum\Caddyfile
caddy reload --config C:\Pfad\zum\Caddyfile
```

Danach sind mindestens `https://budget.leno.info/health` und
`https://budget.leno.info/admin/` zu prüfen. Der Port 48732 wird nicht in der
Firewall freigegeben.

## Server-Releases

Der Workflow `Budgetwelt-Server freigeben` startet ausschließlich manuell und
verlangt die Bestätigung `SERVER FREIGEBEN`. Vor dem ersten Lauf muss der
private, zum eingebetteten öffentlichen Prüfschlüssel gehörende RSA-Schlüssel
als GitHub-Secret `SERVER_UPDATE_SIGNING_KEY_XML` hinterlegt werden. Der
Workflow erzeugt ein versioniertes Release `server-v<Version>` und schaltet
erst anschließend das signierte Manifest im stabilen Kanal `server-updates`
um. Private Schlüssel dürfen niemals committed oder in Clientdateien kopiert
werden.
