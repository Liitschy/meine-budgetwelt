# Codex-Projektübergabe: Meine Budgetwelt

Stand: **0.42.0** vom 3. August 2026;
veröffentlicht sind Client **0.42.0** und Server **0.1.6**

Diese Datei enthält den aktuellen Projektstand und kann zusammen mit dem
Repository an einen neuen Codex-Task übergeben werden. Repository-Code und
aktuelle Tests haben bei Widersprüchen Vorrang vor älteren Chatverläufen.

## 1. Starttext für einen neuen Codex-Task

Den folgenden Text kann man vollständig in einen neuen Codex-Task kopieren:

> Arbeite am Projekt „Meine Budgetwelt“ im Repository
> `https://github.com/unique1986/meine-budgetwelt`.
>
> Lies vor jeder Änderung zuerst
> `docs/CODEX_PROJEKTUEBERGABE.md`, `README.md`, den aktuellen Git-Status und
> die betroffenen Dateien. Die App wird mit Godot 4.7.1 entwickelt und für
> Endnutzer als installierbare Windows-Setup-EXE sowie als PWA für iPhone und
> Android veröffentlicht. Die portable Windows-Datei ist nur ein internes
> Entwicklungs- und Testartefakt.
>
> Bewahre alle vorhandenen Funktionen, lokalen Finanzdaten und das bestehende
> Datenformat. Version 0.39.4 besitzt noch keine Bank- oder KI-Verbindung und
> zeigt den früheren Wocheneinkauf nicht an. Die verbindliche Roadmap unter
> `docs/ROADMAP.md` führt nach der Fehlerbereinigung eine kostenfreie, lokal
> über die bereits von Blenk Voice verwendete Ollama-Laufzeit gestützte
> Wochenplanung und einen ausschließlich lesenden, manuell ausgelösten
> Enable-Banking-Bankabruf ein. Wocheneinkauf, Rezepte und Speiseplan werden dabei
> wieder dauerhaft sichtbar und zeigen voraussichtliche Kosten. Zusätzlich wird
> bei jedem Start automatisch nach Updates gesucht und der Status auf einem
> Start-/Statusbildschirm angezeigt. Die regulär installierte Windows-App lädt,
> prüft und installiert neue Versionen selbständig und startet danach neu. Die
> PWA benötigt vor jeder weiteren
> Veröffentlichung zwingend einen serverseitigen Login für höchstens wenige
> freigeschaltete Konten; eine Client-PIN ist kein Schutz. Implementiere
> niemals Zahlungen und speichere keine PIN, TAN oder Anbieter-Geheimnisse im
> Client.
>
> Das verbindliche Design ist ein eigenständiges Weltraum-Universum: fast
> schwarzes Weltraumblau, dunkle violette Glaskarten, Kupfer, Champagner und
> gedecktes Rosé. Der Kontostand bildet im Sternenatlas das Zentrum; Fixkosten,
> Sparziele und freies Geld liegen auf umlaufenden Bahnen. App, PWA und Admin
> verwenden exakt dasselbe Designsystem. Alte Insel-, Wasser-, Pergament- oder
> Türkisflächen dürfen nicht sichtbar mit dem Cosmic-Design gemischt werden.
> Ändere nur den beauftragten Bereich. Führe danach die Godot-Tests,
> `git diff --check` und einen passenden Export aus. Veröffentliche, committe,
> tagge oder pushe nur, wenn ich das ausdrücklich verlange. Berühre keine
> fremden oder bereits vorhandenen Änderungen im Arbeitsverzeichnis.

## 2. Projektziel

„Meine Budgetwelt“ ist eine bewusst einfache Finanzübersicht für Menschen,
die ihre Daten manuell eintragen möchten. Die App soll auf einen Blick zeigen:

- aktueller Kontostand;
- reservierte und bereits bezahlte Fixkosten;
- verbleibendes freies Geld;
- wöchentliches Budget und verbleibender Wochenbetrag;
- Sparziele;
- Einnahmen und Ausgaben.

Der lokal weiterentwickelte Stand ergänzt einen ausschließlich lesenden,
manuell ausgelösten Abruf über Enable Banking; die Live-Abnahme steht noch aus.
Die manuelle Nutzung bleibt vollständig erhalten.
Die App verarbeitet auch dann keine PIN, TAN oder Banking-Passwörter und löst
keine Zahlungen aus.

## 3. Aktueller sichtbarer Funktionsumfang

### Budgetwelt

- Monat einrichten und wechseln;
- Kontostand manuell ändern;
- Kontostand, Fixkosten, freies Geld und Sparziel anzeigen;
- Budgetwerte direkt in der Landschaft visualisieren;
- Wochenbudget aus dem freien Monatsbetrag ableiten;
- Wochenausgaben buchen;
- zusätzliches Budget nur für eine ausgewählte Woche aufladen;
- Wochenkarten mit Startbudget, Ausgaben und Restbetrag anzeigen;
- nächste fällige Fixkosten anzeigen.

### Fixkosten

- Fixkosten hinzufügen, bearbeiten und löschen;
- Kategorien, Betrag und Fälligkeit verwalten;
- monatliche, quartalsweise und jährliche Wiederholung;
- vollständige Zahlung markieren;
- Teilzahlungen erfassen;
- bezahlten und offenen Betrag anzeigen;
- Zahlung reduziert den Kontostand;
- nur im jeweiligen Monat fällige quartalsweise oder jährliche Kosten werden
  in der Monatsplanung berücksichtigt.

### Sparen

- Sparziele hinzufügen und löschen;
- Zielbetrag, bereits gesparten Betrag und monatliche Sparrate verwalten;
- Einzahlungen erfassen;
- Fortschritt und verbleibenden Zielbetrag anzeigen.

### Buchungen

- zusätzliche Einnahmen erfassen;
- freie Ausgaben erfassen;
- Sparzahlungen erfassen;
- Buchungsverlauf des ausgewählten Monats anzeigen;
- Buchungen nach Wochenbudget filtern;
- Ausgaben und Zahlungen aktualisieren den sichtbaren Kontostand.

### Daten und Updates

- automatische lokale Speicherung;
- manuelle Datensicherung in einen Zeitstempel-Ordner;
- Wiederherstellung einer Sicherung;
- automatische Sicherheitssicherung vor einer Wiederherstellung;
- Update-Prüfung über ein Manifest im neuesten GitHub Release;
- Windows-Downloads über GitHub Releases;
- eigener Budgetwelt-Startbildschirm mit realen Statusstufen für lokale Daten,
  Konto, Updates und Oberfläche;
- autonomer, SHA-256-geprüfter Update-Download mit sichtbarem Fortschritt,
  Datensicherung, stiller Installation und automatischem Neustart.

Der reguläre Windows-Download wird vor der nächsten Endnutzerversion von der
portablen App-EXE auf eine komprimierte, deutschsprachige NSIS-Setup-EXE
umgestellt. Buildskript und Release-Workflow sind im lokalen Entwicklungsstand
umgesetzt. Sie installiert benutzerbezogen, legt einen Startmenü-Eintrag an,
bietet eine optionale Desktopverknüpfung und unterstützt Update sowie
Deinstallation. Vor Updates wird gesichert; lokale Budgetdaten bleiben
standardmäßig erhalten. Reparatur, Versionsupdate, Downgrade-Schutz und
Rückfall auf die bisherige Programmdatei sind umgesetzt und isoliert geprüft.

## 4. Aktueller Ausbau nach Version 0.39.4

Der frühere Bereich „Wocheneinkauf“ mit Rezepten und Speiseplan ist in der
veröffentlichten Version 0.39.4 noch nicht sichtbar. Im lokalen, unveröffentlichten
Entwicklungsstand ist er zusammen mit Rezeptbibliothek, persönlicher Preisbasis
und verbindlicher lokaler KI-Planung vollständig neu integriert.

Einige ältere interne Module und Datendateien für Einkauf, Rezepte und
Speisepläne existieren weiterhin. Sie werden zur Datenverträglichkeit nicht
ungefragt gelöscht. Die Roadmap beauftragt ihre kontrollierte Prüfung und den
Neuaufbau einer Wochenplanung nach Abschluss der Fehlerbereinigung.

Noch nicht produktiv freigeschaltet sind die neue integrierte Wochenplanung,
der echte Durchstichtest mit der gemeinsamen Ollama-Laufzeit und die
read-only-Bankanbindung. Alle drei Bereiche sind lokal implementiert; für die
KI fehlt nur noch die Root-Server-Abnahme, für Enable Banking fehlen die
serverseitigen Geheimnisse sowie Sandbox-/Produktiv- und Geräteabnahme. Konten,
Server, Desktop/PWA-Synchronisierung, geschützte PWA und automatische Updates
sind bereits eingerichtet.

Kostenfreie lokale KI-Wochenplanung, verbindlicher PWA-Login und read-only-Enable-Banking-Abruf
sind inzwischen verbindlicher Zielumfang. Ebenso verbindlich sind der sichtbare
Wocheneinkauf mit Rezepten, Speiseplan und Schätzkosten sowie die automatische
Updateprüfung beim Start. Die Synchronisierung ist inzwischen verbindlich:
Windows-App und PWA verwenden dieselben Serverkonten, Budgetgruppen und
fachlichen Daten auf einem eigenen Budgetwelt-Dienst des Root-Servers. Die
regulär installierte Windows-App wird nach Manifest- und SHA-256-Prüfung
autonom aktualisiert; portable Entwicklungs-EXEs werden nicht automatisch
überschrieben.

Das erste isolierte Servergrundgerüst liegt unter
`server/MeineBudgetwelt.Server`. Es veröffentlicht eine eigenständig
lauffähige `Meine-Budgetwelt-Server.exe`, bindet standardmäßig nur an
`127.0.0.1:48732`, verwendet eine eigene SQLite-Datei und besitzt einen
geprüften Gesundheitsendpunkt. Der Release-Build und ein isolierter Starttest
sind bestanden; der NuGet-Abhängigkeitsbaum enthält zum Prüfzeitpunkt keine
bekannte Schwachstelle.

Auf diesem Kern sind produktiv beziehungsweise durchgängig geprüft:

- einmalige Anlage des ersten Systemadministrators ohne Kennwort in der
  Befehlszeile;
- getrennte sichere Sitzungen für PWA und Desktop;
- Benutzeranlage, Aktivierung und Sperrung mit Sitzungswiderruf;
- gemeinsame Budgetgruppen mit den Rollen `owner`, `manager` und
  `member`;
- 48 Stunden gültige, einmal verwendbare Einladungen mit optionaler
  Budgetgruppenzuordnung;
- 30 Minuten gültige Kennwort-Resetlinks über TLS-geschütztes SMTP und
  Sitzungswiderruf nach erfolgreicher Änderung;
- Begrenzung fehlgeschlagener Anmeldeversuche pro Client-IP.
- serverseitig validierte, versionierte Synchronisation aller acht fachlichen
  Datendateien mit Konfliktschutz;
- Desktop-Anmeldung mit verschlüsselt lokal gespeichertem, serverseitig
  widerrufbarem Sitzungstoken;
- separate PWA-Anmeldung im freigegebenen Glas-Design mit sicherem Sitzungscookie;
- standardmäßiges Desktop-Serverziel `https://budget.leno.info`, während die
  PWA automatisch dieselbe Herkunft wie ihre Serverauslieferung verwendet;
- responsiver separater Anmeldebildschirm, im echten 390 × 844-Pixel-
  Browserlauf vollständig und ohne horizontales Abschneiden geprüft;
- persönliche tageszeitabhängige Begrüßung und sichtbarer Synchronisationsstatus;
- PWA-Auslieferung durch denselben Server und dieselbe Herkunft wie die API;
- automatischer Durchstichtest Server → Client A → Client B → Client A;
- echter Browserlauf mit PWA-Anmeldung und Sitzungswiederherstellung nach
  Neuladen;
- reproduzierbarer PWA-Exporttest einschließlich Sicherheitsheadern,
  MIME-Typen, Cookie-Eigenschaften und unauthentifiziertem API-Zugriffsschutz.
- responsive Admin-Oberfläche im freigegebenen Glas-Design für Benutzer,
  Sperren, Budgetgruppen, Rollen, Einladungen und Serverstatus;
- sichere Löschoberfläche für Budgetgruppen mit Mitgliederwarnung und exakter
  Namensbestätigung;
- autonome Serverupdate-Aufgabe nach Systemstart und täglich, mit RSA-signiertem
  Manifest, SHA-256, Versionsschutz, Datensicherung und vollständigem
  Programm-Rückfall;
- aktive Serverkonfiguration und dokumentierter Caddy-Block für
  `https://budget.leno.info` mit internem Upstream `127.0.0.1:48732`.

Der installierbare Windows-Serverdienst wurde auf dem echten Root-Server
eingerichtet. Caddy, HTTPS, Admin-Oberfläche, Konten, geschützte PWA und die
Synchronisierung mit dem Desktop sind unter `https://budget.leno.info`
in Betrieb. Diese Arbeiten sind abgeschlossen.

Am 2. August 2026 begann der gemeinsame Ausbau von Rezepten, Sieben-Tage-
Speiseplan, Wocheneinkauf und lokaler KI. Der neue geschützte Serverendpunkt
prüft Gruppenzugehörigkeit und Eingabegrenzen, fordert ein strukturiertes
Planungsergebnis an und validiert Kosten, Budget, Rezeptverweise, doppelte
Einkaufsartikel, Allergien und ausgeschlossene Zutaten nochmals
deterministisch. Er speichert oder bucht den Entwurf nicht. Nach ausdrücklicher
Bestätigung übernimmt der lokal integrierte Client Rezepte, genau sieben Tage
und die Einkaufsliste gemeinsam, legt vorher eine Sicherung an und erzeugt
keine Finanzbuchung. Die aktive Woche zeigt anschließend Speiseplan,
Rezeptdetails und den dauerhaften Wocheneinkauf; Artikel lassen sich manuell
ergänzen, abhaken und nach Bestätigung löschen. Nur die ausdrücklich abgehakten
Artikel können über die bestehende Funktion als Monatsausgabe verbucht werden.
Desktop- und Mobilvorschau wurden aus der echten Godot-Oberfläche auf
vollständige Darstellung geprüft. Version 0.41.0 konfigurierte ursprünglich
`qwen3.5:4b`; auf dem Root-Server ist tatsächlich `qwen3.5:9b` installiert.
Server 0.1.6 migriert die Konfiguration auf
`qwen3.5:9b`, erkennt installierte Qwen-Modelle über Ollamas `/api/tags` und
liefert konkrete Transport-/Providerfehler statt nur einer Sammelmeldung.
Ollama bleibt serverseitig an Loopback gebunden und benötigt keinen API-Schlüssel.
Ebenfalls am 2. August 2026 wurde die freigegebene read-only-Bankoberfläche in
den Buchungsbereich integriert. Der Server speichert Bankfreigaben isoliert,
ruft über Enable Banking ausschließlich auf Knopfdruck Kontostände und Buchungen ab
und liefert nur eine Vorschau mit pseudonymisierten Kontoreferenzen. Der Client
importiert ausschließlich ausgewählte, gebuchte EUR-Umsätze und verhindert
Dubletten über stabile Import-IDs. PIN, TAN, Banking-Kennwort und rohe
Bankzugangsdaten gelangen weder in Client/PWA noch zur lokalen KI. Die lokale
KI benötigt kein Geheimnis. App-ID und privater Schlüssel werden mit dem
installierten Werkzeug `tools/Configure-Integrations.ps1` eingerichtet. Es
kopiert den Schlüssel in die geschützte Serverablage; sein Inhalt landet weder
in `appsettings.json` noch in einer Befehlszeile.
Sandbox und Produktion werden durch getrennte, bei Enable Banking registrierte
Apps bestimmt. Für die erste echte Abnahme wird die vorhandene Sandbox-App
verwendet. Für den späteren eingeschränkten Produktivbetrieb ist eine eigene
Production-App vorgesehen, die auf die eigenen Konten begrenzt wird. Ein echter
Anbieter-Live-Test steht noch aus; die Oberfläche und der read-only-Vertrag sind
mit Version 0.41.0 veröffentlicht.

Der Providerwechsel verwendet Serverversion 0.1.2 und Datenbankschema 6. Der
lokale Server-Installer wurde reproduzierbar gebaut; Server-, PWA-, Desktop-
Synchronisations-, JWT-Vertrags-, Datenbank- und Konfigurationsmigrationstests
sind erfolgreich. Der vollständige Windows-Dienst-Upgrade-Test läuft als
verpflichtendes Gate im administrativen Server-Release-Workflow. Version 0.1.2 ist über den signierten
Server-Updatekanal veröffentlicht und wird vom autonomen Server-Updater installiert.

Serverversion 0.1.4 behebt zusätzlich die Manifest-Dekodierung unter Windows
PowerShell 5.1. GitHub liefert das signierte JSON-Manifest als UTF-8-Bytefolge
mit `application/octet-stream`; ältere Updater behandelten diese Antwort nicht
als Text und meldeten deshalb ein unvollständiges Manifest. Nach einer einmaligen
manuellen Aktualisierung auf 0.1.4 funktionieren folgende Serverupdates wieder
autonom.

## 5. Verbindliche Designrichtung

### Gemeinsame Bildsprache

- eigenständiges, hochwertiges Weltraum-Universum statt Fantasy-Insel;
- fast schwarzes Weltraumblau und dunkles Violett als Grundfarben;
- Kupfer, Champagner, gedecktes Rosé und zurückhaltendes Violett als Akzente;
- halbtransparente Glaskarten mit feinen, warmen Konturen;
- Sternenatlas, Konstellationen und Umlaufbahnen als wiederkehrende Motive;
- elegante Serifenschrift für große Titel und Beträge;
- klare, größere Touch-Flächen und hochwertige Linien-Symbole;
- keine sichtbare Mischung mit alten Insel-, Wasser-, Türkis-, Buch- oder
  Pergamentflächen.

### Windows

- kosmischer Sternenatlas als Mittelpunkt der Budgetseite;
- Kontostand zentral, Fixkosten, Sparziele und freies Geld auf Umlaufbahnen;
- seitliche Navigation und einheitliche Glaskarten in allen Untermenüs;
- Fixkosten, Sparen, Buchungen, Wochenplanung, Banking und Einstellungen nutzen
  dieselben Farben, Abstände, Rahmen und Bedienelemente;
- Inhalte müssen nach jeder Fenstergrößenänderung neu angeordnet werden und die
  verfügbare Fläche sinnvoll nutzen;
- keine winzigen oder nur hochskalierten Mobilbedienelemente.

### PWA, iPhone und Android

- echtes Hochformatlayout mit vertikalem Scrollbereich;
- Sternenatlas bleibt sichtbar, ohne Inhalte oder Texte zu überlagern;
- dunkle halbtransparente Glaskarten mit Kupfer-/Champagnerkontur;
- feste Navigation am unteren Rand mit ausreichendem sicheren Abstand;
- Karten und Listen werden vertikal gestapelt;
- keine abgeschnittenen Inhalte rechts und keine horizontale Seitennavigation;
- keine verkleinerte Desktop-Seite, sondern eigene responsive Größen und
  Abstände für 390 × 844 und vergleichbare Geräte.

### Administration

- Login, Übersicht, Benutzer, Budgetgruppen, Einladungen, Serverstatus, Updates
  und Dialoge verwenden exakt dasselbe Cosmic-Glasdesign;
- die Administration verwendet den Cosmic-Star-Atlas-Hintergrund und keine
  frühere Budgetinsel;
- Desktop-Seitennavigation und mobile Bottom-Navigation bleiben funktional und
  visuell konsistent mit App und PWA.
## 6. Technische Basis

- Engine: **Godot 4.7.1**
- Sprache: **GDScript**
- Hauptszene: `res://app/Main.tscn`
- Hauptoberfläche: `app/main.gd`
- Landschaftsansicht: `ui/budget_world_view.gd`
- Renderer: GL Compatibility
- Desktop-Viewport: 1440 × 900
- lokaler Entwicklungsstand: 0.42.0
- lokaler Server-Entwicklungsstand: 0.1.6
- zuletzt veröffentlichte Serverversion: 0.1.6
- zuletzt veröffentlichte Version: 0.42.0

Wichtige Autoloads aus `project.godot`:

- `StorageManager`
- `BudgetManager`
- `FixedCostManager`
- `SavingsManager`
- `MonthManager`
- `TransactionManager`
- `ShoppingManager`
- `MealPlanManager`
- `CustomRecipeManager`
- `AiPlanningManager`
- `BankingManager`
- `SyncManager`
- `UpdateManager`

Die Manager halten Geschäftslogik und Speicherung von der Darstellung in
`app/main.gd` getrennt. Neue Berechnungen sollen möglichst in einem Manager
oder Calculator landen und nicht mehrfach in der Oberfläche implementiert
werden.

## 7. Zentrale Dateien

- `app/main.gd` – komplette Hauptnavigation, Dialoge und responsive Oberfläche
- `app/Main.tscn` – Hauptszene
- `ui/budget_world_view.gd` – Landschaft und Werte in der Budgetwelt
- `core/budget_manager.gd` – Kontostand und Budgetgrunddaten
- `core/fixed_cost_manager.gd` – Fixkosten und Zahlungsintervalle
- `core/fixed_cost_calculator.gd` – Fixkostenzusammenfassung
- `core/savings_manager.gd` – Sparziele und Einzahlungen
- `core/transaction_manager.gd` – Einnahmen und Ausgaben
- `core/ai_planning_manager.gd` – validierte KI-Entwürfe und atomare Übernahme
- `core/banking_manager.gd` – read-only-Bankstatus, Vorschau und Importauswahl
- `ui/weekly_planning_page.gd` – Wochenplanung, Rezepte und persönliche Preise
- `ui/banking_panel.gd` – responsive, manuell ausgelöste Bankimportoberfläche
- `core/month_manager.gd` – Monatswechsel und Monatshistorie
- `core/storage_manager.gd` – JSON-Speicherung, Backup und Wiederherstellung
- `core/update_manager.gd` – Versions- und Update-Prüfung
- `tests/budget_manager_test.gd` – vorhandene Logiktests
- `tests/TestRunner.tscn` – Headless-Testeinstieg
- `assets/space/cosmic-star-atlas-background.png` – gemeinsamer Sternenatlas-Hintergrund
- `assets/icons/` – Navigationssymbole
- `assets/pwa/` – PWA-Symbole
- `.github/workflows/pages.yml` – PWA-Build und GitHub Pages
- `.github/workflows/windows-release.yml` – Windows-Release
- `export_presets.cfg` – Windows- und Web-Export

## 8. Lokale Daten

Die Daten werden als JSON im Godot-Benutzerverzeichnis gespeichert.

Windows-Speicherort:

`%APPDATA%\Godot\app_userdata\Budget & Wocheneinkauf`

Aktuelle Datendateien:

- `budget_data.json`
- `fixed_costs.json`
- `month_history.json`
- `savings_goals.json`
- `transactions.json`
- `shopping.json`
- `meal_plans.json`
- `custom_recipes.json`

Backups liegen unter `user://backups/<Zeitstempel>`.

Wichtige Regeln:

- App-Updates dürfen persönliche Daten nicht überschreiben;
- gelöschte Sparziele oder Fixkosten müssen als leere Liste gespeichert
  bleiben und dürfen nach einem Neustart nicht als Beispieldaten zurückkehren;
- vor Formatänderungen müssen bestehende Dateien weiterhin lesbar bleiben;
- Sicherungen validieren JSON-Dateien vor der Wiederherstellung;
- vor dem Überschreiben aktueller Daten wird eine Sicherheitssicherung erzeugt.

Die PWA und die Windows-App halten weiterhin eine lokale Offline-Kopie im
Speicherbereich des jeweiligen Geräts. Im lokalen Entwicklungsstand werden die
acht fachlichen Datendateien nach Anmeldung über dieselbe Budgetgruppe des
eigenen Servers in beide Richtungen synchronisiert. Der Serverstand ist dabei
versioniert; ein veralteter Client darf neuere Daten nicht unbemerkt
überschreiben.

## 9. Budgetregeln

- Der Kontostand ist der manuell eingetragene aktuelle Geldstand.
- Eine neue Ausgabe reduziert den Kontostand.
- Eine bezahlte oder teilweise bezahlte Fixkostenposition reduziert den
  Kontostand um den tatsächlich erfassten Zahlungsbetrag.
- Bereits bezahlte Fixkosten bleiben Bestandteil der Monatsplanung, damit sie
  nicht doppelt als zusätzlich frei verfügbares Geld behandelt werden.
- Der Vorschauwert „nach allen Fixkosten frei“ berücksichtigt die für den
  gewählten Monat vorgesehenen Fixkosten.
- Wochenbudget-Ausgaben reduzieren nur das verbleibende Budget der jeweiligen
  Woche und werden im Buchungsverlauf sichtbar.
- Eine zusätzliche Wochenaufladung gilt nur für die ausgewählte Woche.

Bei Änderungen an diesen Regeln müssen Budgetwelt, Fixkostenübersicht,
Buchungen und Wochenkarten gemeinsam geprüft werden.

## 10. Responsive Aufbau

Die Oberfläche entscheidet in `app/main.gd` anhand der verfügbaren Breite
zwischen Desktop-, Tablet- und kompakter Mobilansicht.

Für die mobile Finanzansicht sind insbesondere relevant:

- `_apply_mobile_book_layout()`
- `_configure_book_region()`
- `_style_mobile_book_header()`
- `_style_mobile_section_label()`

Der historische Funktionsname `_apply_mobile_book_layout()` bedeutet nicht,
dass auf dem iPhone wieder ein Buch angezeigt werden soll. In der aktuellen
kompakten Ansicht werden die Landschaft und Glaskarten verwendet.

## 11. Test- und Prüfablauf

Vor jeder Übergabe mindestens:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\verify-project.ps1
```

Für den aktuellen Server-/Synchronisationsblock zusätzlich:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\verify-server.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\verify-client-server.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\verify-pwa.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\verify-ai-planning.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\verify-banking.ps1
```

Der Prüflauf importiert bei einem frischen Checkout zuerst alle Assets, führt
danach die Testszene und `git diff --check` aus und wertet Ressourcen- oder
Skriptfehler auch dann als Fehlschlag, wenn Godot selbst Exitcode 0 liefert.
Ein abweichender Godot-Pfad kann mit `-GodotPath` übergeben werden.

Windows-Export:

```powershell
New-Item -ItemType Directory -Force -Path build\windows | Out-Null
& $godot --headless --path . --export-release 'Windows Desktop' `
  'build/windows/Budget-und-Wocheneinkauf.exe'
```

Zusätzlich visuell prüfen:

1. Budgetwelt im Windows-Vollbild;
2. Fixkosten mit mehreren Einträgen und Teilzahlung;
3. leere Fixkostenliste;
4. Sparziele mit und ohne Ziel;
5. Buchungen mit und ohne Einträge;
6. iPhone-Hochformat, besonders rechte Kante, Textkontrast und untere
   Navigation;
7. Dezimalbeträge mit Komma und Punkt.

## 12. Veröffentlichung

Repository:

`https://github.com/unique1986/meine-budgetwelt`

PWA-Status: **GitHub Pages am 31. Juli 2026 deaktiviert; die geschützte PWA
läuft mit serverseitigem Login unter `https://budget.leno.info`.**

Aktuelle Windows-Version:

`https://github.com/unique1986/meine-budgetwelt/releases/download/v0.42.0/Meine-Budgetwelt-Setup-0.42.0.exe`

Veröffentlichungsablauf:

1. Versionsnummer in `project.godot` erhöhen;
2. Datei- und Produktversion in `export_presets.cfg` angleichen;
3. Tests und Export ausführen;
4. Änderungen auf einem Arbeitsbranch committen und per Pull Request nach
   `main` bringen;
5. für die Windows-Version einen passenden Tag wie `v0.39.3` erstellen;
6. eine PWA nur mit bestandenem serverseitigem Login- und Datenschutztest
   über den geschützten Server veröffentlichen;
7. Push des Versionstags baut automatisch Setup-EXE, SHA-256-Datei und
   Update-Manifest;
8. die jeweils freigegebenen GitHub-Actions abwarten und Links mit HTTP 200
   prüfen.

Versionsnummer, Git-Tag und Dateiname müssen übereinstimmen.

## 13. Bekannte Einschränkungen

- Server 0.1.6 migriert die alte Modellvorgabe `qwen3.5:4b` auf das auf dem
  Root-Server installierte `qwen3.5:9b`, erkennt kompatible installierte
  Qwen-Modelle automatisch und liefert konkrete Providerfehler; der echte
  Wochenplan muss nach dem automatischen Serverupdate einmal live geprüft werden;
- keine Codesignatur für die Windows-Dateien; der veröffentlichte Installer
  wird bis zur späteren kostenlosen Signaturlösung per SHA-256 geschützt;
- die PWA kann auf dem iPhone durch Safari-/Service-Worker-Caches kurzzeitig
  eine alte Version zeigen; deshalb existieren versionierte PWA-Links;
- neue Versionen des integrierten Planungsbereichs müssen erneut auf echten
  iPhone-/Android-Geräten und unter Windows abgenommen werden;
- ein Teil der Oberfläche wird zentral in der großen Datei `app/main.gd`
  erzeugt und sollte langfristig vorsichtig in kleinere UI-Komponenten
  zerlegt werden;
- `app/main.gd` enthält noch ältere, nicht instanziierte Shopping-, Rezept- und
  Speiseplanoberflächen; geeignete Logik wird übernommen, die sichtbare
  Oberfläche jedoch erst nach Vorschaufreigabe neu integriert.

## 14. Arbeitsregeln für zukünftige Änderungen

1. Vor jeder Aufgabe `git status`, relevante Dateien und aktuelle Tests prüfen.
2. Fremde Änderungen im Arbeitsverzeichnis nicht überschreiben oder stageen.
3. Pro Auftrag nur einen logisch zusammenhängenden Bereich ändern.
4. Das verbindliche Cosmic-Glasdesign in App, PWA und Admin einheitlich bewahren.
5. Mobil und Windows nicht mit identischen starren Größen behandeln.
6. Finanzlogik nicht in mehreren UI-Funktionen duplizieren.
7. Bestehende IDs und gespeicherte JSON-Felder nicht ohne Migration umbenennen.
8. Lokale KI und Enable Banking nur innerhalb der Grenzen von `docs/ROADMAP.md`
   implementieren; Ollama bleibt loopback-gebunden und Bankgeheimnisse oder
   Bankzugangsdaten gehören nicht in den Client.
9. Einkaufs- und Rezeptfunktionen erst nach der Fehlerbereinigung kontrolliert
   gemäß Roadmap reaktivieren und bestehende Daten kompatibel halten.
10. Keine Commits, Tags, Pushes oder Releases ohne ausdrücklichen Benutzerwunsch.
11. Nach Änderungen Tests, `git diff --check` und einen risikogerechten Export
    ausführen.
12. Bei visuellen Änderungen echte schmale Mobilansichten und Windows-Vollbild
    prüfen.

## 15. Aktueller Repository-Zustand bei Erstellung dieser Übergabe

- veröffentlichter Stand: Client `0.42.0`, Server `0.1.6`;
- Arbeitsbranch: `agent/complete-cosmic-ai-fix`;
- Cosmic-Star-Atlas-Design für App, PWA und die vollständige Administration
  vereinheitlicht;
- echte Vorschauen für 1440 × 900 und 390 × 844 für Login, Dashboard,
  Fixkosten, Sparen, Buchungen, Wochenplanung und Banking erzeugt;
- Admin-Login und Admin-Dashboard zusätzlich mit Edge in Desktop- und
  Mobilgröße gerendert;
- KI-Modellvorgabe auf `qwen3.5:9b` migriert und installierte Qwen-Modelle werden
  über Ollama erkannt;
- Client zeigt konkrete Server-/Transportfehler für die KI-Planung;
- Projekt-, Server-, KI-, Client-Server-, PWA- und Banking-Prüfungen bestanden;
- die fremde bestehende Löschung `build/.gdignore` gehört nicht zu diesem
  Auftrag und darf nicht gestaget oder verworfen werden;
- Veröffentlichung und Installation erst nach ausdrücklicher Freigabe der
  neuen Vorschaubilder.
## 16. Verbindliche Roadmap ab 31. Juli 2026

Die weitere Reihenfolge ist in `docs/ROADMAP.md` festgelegt:

1. Fehlerbereinigung und belastbare Tests;
2. automatische Updateprüfung und -installation beim Start mit sichtbarem
   Start-/Statusbildschirm und benutzerfreundlichem Setup-Installer;
3. eigener isolierter Serverdienst, Konten, Admin-Oberfläche und gemeinsame
   Synchronisation für Windows-App und PWA;
4. zwingender serverseitiger PWA-Login ohne öffentliche Registrierung;
5. sichtbarer Wocheneinkauf, Rezepte und Speiseplan mit Schätzkosten;
6. feste, kostenfreie lokale KI-Planung über die gemeinsame Ollama-Laufzeit
   für Budget, Rezepte und Einkauf;
7. read-only-Enable-Banking-Import auf Knopfdruck;
8. gemeinsame Integration, kostenlose Codesignaturprüfung, Geräteprüfung und
   erst danach Veröffentlichung.

Die KI-Planung ist nicht optional. Die Bankanbindung bleibt strikt lesend;
Überweisungen und andere Zahlungsauslösungen sind ausgeschlossen. Der
serverseitige PWA-Login ist ebenfalls nicht optional; bis zu seiner Abnahme
darf keine neue PWA veröffentlicht werden. Die zuvor öffentliche
GitHub-Pages-PWA wurde nach der Übertragung des Repositorys auf `unique1986`
am 31. Juli 2026 deaktiviert.
