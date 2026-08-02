# Meine Budgetwelt

Eine einfache lokale Windows-Anwendung für Monatsbudget, Fixkosten, Sparziele
und Buchungen.

Die Startseite stellt das Monatsbudget als lebendige kleine Landschaft dar:
Der Kontostand speist einen Wasserfall, Fixkosten liegen am Haus und der
Sparfortschritt lässt den Sparbaum wachsen.

Das visuelle Design verwendet ein dunkles Navy-Türkis, leuchtende Akzente,
feine Linien-Symbole, elegante Serifentitel und klar gegliederte Karten.

Das Dashboard umfasst außerdem eine Monatsübersicht, die nächsten fälligen
Fixkosten und einen kompakten Monatsfluss vom Kontostand bis zum Sparziel.

## Funktionen

- Monatslohn oder aktuellen Kontostand eintragen;
- verfügbares Geld vor und nach allen Fixkosten sehen;
- wiederkehrende Fixkosten erfassen, abhaken und in neue Monate übernehmen;
- Teilzahlungen für einzelne Fixkosten erfassen und den offenen Rest sehen;
- Sparziele mit monatlicher Sparrate verwalten;
- zusätzliche Einnahmen, variable Ausgaben und Sparzahlungen buchen;
- Wochenausgaben erfassen und das verbleibende Wochenbudget sehen;
- vergangene Monate wieder aufrufen;
- lokale Datenspeicherung und Sicherungen;
- Update-Prüfung über ein GitHub-Release-Manifest mit sicherem Setup-Download.

Wocheneinkauf, Rezeptbibliothek und Sieben-Tage-Speiseplan sind im aktuellen
Entwicklungsstand wieder sichtbar. Bereits vorhandene Einkaufsdaten werden
nicht ungefragt gelöscht.

## Verbindliche Weiterentwicklung

Nach der aktuellen Fehlerbereinigung werden folgende Funktionen kontrolliert
neu aufgebaut:

- kostenfreie lokale KI-Wochenplanung über die bereits auf dem Root-Server
  vorhandene Ollama-Laufzeit für Rezepte, Einkaufsliste,
  Resteverwertung und die Einhaltung des Wochenbudgets;
- dauerhaft sichtbarer Wocheneinkauf, Rezeptbereich und Sieben-Tage-Speiseplan
  mit voraussichtlichen Kosten pro Rezept, Tag und Woche;
- ausschließlich lesender Bankabruf über GoCardless Bank Account Data nach
  einem ausdrücklichen Knopfdruck;
- zwingender serverseitiger Login für die PWA mit höchstens wenigen
  ausdrücklich freigeschalteten Benutzern und ohne öffentliche Registrierung;
- gemeinsamer, selbst gehosteter Datenbestand für Windows-App und PWA über
  einen isolierten Budgetwelt-Serverdienst auf dem eigenen Root-Server;
- Import neuer Buchungen mit Dublettenprüfung und Bestätigung;
- automatische Updateprüfung beim Start mit sichtbarem Start-/Statusbildschirm
  sowie autonomem, geprüftem Windows-Update und Neustart;
- eine geführte, deutschsprachige Windows-Installation über eine kompakte
  `Meine-Budgetwelt-Setup-<Version>.exe` statt einer portablen Datei als
  regulärem Endnutzer-Download;
- weiterhin vollständige manuelle Nutzung ohne Bankverbindung.

Die genaue Reihenfolge und die Sicherheitsgrenzen stehen in
[`docs/ROADMAP.md`](docs/ROADMAP.md).

Wichtig: Die bisher öffentliche PWA 0.39.2 auf GitHub Pages wurde am
31. Juli 2026 deaktiviert. Der Workflow veröffentlicht nicht automatisch und
benötigt zusätzlich die ausdrückliche Freigabevariable
`PWA_AUTH_ENABLED=true`. Vor der nächsten PWA-Veröffentlichung wird ein echter
serverseitiger Zugangsschutz umgesetzt; eine reine Passwortabfrage im Browser
reicht nicht.

Der lokale Budgetwelt-Server liegt unter `server/MeineBudgetwelt.Server`.
Es wird als eigenständige Windows-EXE veröffentlicht, bindet standardmäßig nur
an `127.0.0.1:48732` und verwendet ausschließlich eine eigene eingebettete
SQLite-Datei. Bestehende Datenbanken und Datenbankdienste werden nicht
verändert.

Der Kontenkern kann inzwischen das erste Administratorkonto sicher
initialisieren, getrennte PWA- und Desktop-Sitzungen ausstellen, Benutzer
sperren und gemeinsame Budgetgruppen verwalten. Ein automatisierter
Durchstichtest prüft Anmeldung, Benutzeranlage, Gruppenzuordnung und die
sofortige Wirkung einer Kontosperre.

Einladungen und die Kennwortwiederherstellung sind ebenfalls serverseitig
umgesetzt: zeitlich begrenzte Einmallinks werden ausschließlich über
konfiguriertes TLS-geschütztes SMTP versendet. Eine Kennwortänderung widerruft
alle alten Sitzungen. Im automatisierten Test werden die Nachrichten in einem
isolierten Abholverzeichnis geprüft; reale SMTP-Zugangsdaten sind nicht im
Repository enthalten.

Der lokale Entwicklungsstand verbindet inzwischen Windows-App und PWA mit
diesem Server. Beide verwenden dasselbe Konto, dieselbe Budgetgruppe und einen
versionierten Snapshot der acht fachlichen Datendateien. Ein automatisierter
Durchstichtest über zwei getrennte Godot-Clients prüft Änderungen in beide
Richtungen und den Schutz gegen veraltetes Überschreiben. Der Server liefert
außerdem den PWA-Export unter derselben Herkunft wie die geschützte API aus.
Ein echter Browserlauf hat Anmeldung, persönliche Begrüßung,
Synchronisationsstatus und Sitzungswiederherstellung nach Neuladen bestätigt.
Der Windows-Client verwendet im Produktionsbuild standardmäßig
`https://budget.leno.info`; die PWA verwendet automatisch ihre eigene Herkunft.
Der separate Glas-Anmeldebildschirm wurde zusätzlich in einer echten
390 × 844-Pixel-Browseransicht ohne horizontales Abschneiden geprüft.

Der installierbare Serverdienst, die responsive Admin-Oberfläche und das
autonome kryptografisch signierte Serverupdate sind umgesetzt. Ein
vollständiger erhöhter Windows-Test hat Erstinstallation, eigenen Dienst,
Updateaufgabe, Admin-Anmeldung, Datensicherung, Update, erneuten gesunden Start
und Deinstallation geprüft. Der eigenständige Serverdienst, Caddy/HTTPS und
die geschützte PWA laufen auf dem Root-Server unter `https://budget.leno.info`.
Die gemeinsame lokale Ollama-KI wird mit Serverversion 0.1.1 aktiviert.

Vollständige lokale Prüfungen:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\verify-project.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\verify-server.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\verify-client-server.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\verify-pwa.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\verify-server-updater.ps1
# benötigt für den isolierten Windows-Diensttest ein administratives Fenster
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\verify-server-installer.ps1
```

## Windows-Testversion und geplanter Installer

Die rohe portable Godot-EXE unter `build/windows` ist nur ein internes
Entwicklungs- und Testartefakt. Der lokale Entwicklungsstand erzeugt eine
kompakte, installierbare Setup-EXE. Der Installer führt verständlich durch Installation,
Aktualisierung, Reparatur und Deinstallation. Eine Desktopverknüpfung ist
optional; der Startmenü-Eintrag wird automatisch angelegt. Persönliche Daten
liegen außerhalb des Programmordners und bleiben bei Updates erhalten.

Der lokale Probelauf komprimiert die rund 114,5 MB große Godot-App auf eine
Setup-Datei von rund 31,9 MB. Installation, Start und Deinstallation wurden in
einem getrennten Testverzeichnis erfolgreich geprüft.

## Updates

Seit Version 0.39.3 kann die Prüfung zusätzlich über den Button **Nach Updates
suchen** erneut ausgelöst werden. Version 0.39.4 zeigt beim Start einen eigenen
Budgetwelt-Ladebildschirm mit echtem Status für Daten, Konto, Updates und
Oberfläche. Eine regulär installierte Windows-App lädt nur den
offiziellen Setup-Installer und dessen SHA-256-Datei aus den GitHub Releases
dieses Projekts, verwirft abweichende Downloads, erstellt eine Datensicherung,
schließt sich kontrolliert, installiert das Update still und startet danach
neu. Portable Entwicklungs-EXEs werden nicht automatisch überschrieben. Die
0.39.3 musste einmal manuell installiert werden; ab dort können künftige
veröffentlichte Versionen autonom übernommen werden. Offline- oder
Serverfehler blockieren den App-Start nicht.

Ein Tag im Format `v1.2.3` muss zur Versionsnummer in `project.godot` passen.
Der Workflow `Windows-Version veröffentlichen` erzeugt die interne Godot-App,
verpackt sie mit NSIS als
`Meine-Budgetwelt-Setup-<Version>.exe` und veröffentlicht nur diesen Installer
mit seiner SHA-256-Prüfsumme.

## Datenschutz

Version 0.39.4 speichert Budget- und Buchungsdaten ausschließlich lokal und
enthält noch keine Online-Banking- oder KI-Verbindung. Die geplante lokale KI
läuft ausschließlich über Ollama auf dem eigenen Root-Server. GoCardless-
Geheimnisse, PIN und TAN dürfen niemals in der App oder im Repository
gespeichert werden.
