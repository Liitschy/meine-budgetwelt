# Roadmap: Meine Budgetwelt

Stand: 1. August 2026

Diese Roadmap beschreibt die verbindliche Weiterentwicklung nach Version
0.39.2. Der veröffentlichte Stand bleibt bis zur jeweiligen Umsetzung
unverändert. Neue Funktionen werden erst nach bestandenen Tests und einer
risikogerechten Prüfung veröffentlicht.

## Verbindliche Zielrichtung

- Die KI-gestützte Wochenplanung mit OpenAI ist ein fester Bestandteil des
  Zielprodukts und nicht optional.
- Die Online-Banking-Anbindung erfolgt über GoCardless Bank Account Data,
  ausschließlich lesend und nur nach einem ausdrücklichen Knopfdruck.
- Wocheneinkauf, Rezepte und Speiseplan sind im Zielprodukt dauerhaft sichtbare
  Hauptfunktionen. Sie zeigen voraussichtliche Kosten pro Rezept, Tag und Woche.
- Beim Start wird automatisch nach Updates gesucht. Der Prüfstatus ist auf
  einem sichtbaren Start-/Statusbildschirm dargestellt; eine Installation
  erfolgt niemals unbemerkt.
- Die reguläre Windows-Veröffentlichung ist eine kompakte, installierbare
  Setup-EXE und kein portables Endnutzerpaket. Installation, Update und
  Deinstallation müssen ohne technische Vorkenntnisse verständlich sein.
- Die PWA darf vor der nächsten Veröffentlichung nur noch nach einer echten,
  serverseitig geprüften Anmeldung erreichbar sein. Es gibt keine öffentliche
  Selbstregistrierung; vorgesehen sind höchstens wenige ausdrücklich
  freigeschaltete Benutzerkonten.
- Desktop-App und PWA verwenden verpflichtend dasselbe Konto und denselben
  zentralen Datenbestand. Änderungen an Budget, Buchungen, Einkaufslisten,
  Rezepten und Speiseplänen werden in beide Richtungen synchronisiert.
- Der zentrale Datenbestand liegt nicht bei einem pausierbaren Fremddienst,
  sondern in einem eigenen, isolierten Budgetwelt-Serverdienst auf dem
  Windows-Root-Server des Projekteigentümers.
- Manuelle Eingaben bleiben immer erhalten. Die App muss auch dann nutzbar
  bleiben, wenn ein externer Dienst vorübergehend nicht erreichbar ist.
- Budgetberechnungen, Preisprüfung und Sicherheitsgrenzen bleiben in
  deterministischen Calculators beziehungsweise Managern. KI-Ausgaben werden
  vor der Anzeige und Speicherung gegen diese Regeln validiert.
- PIN, TAN, Banking-Passwörter sowie OpenAI- und GoCardless-Geheimnisse dürfen
  niemals in der PWA, der Windows-EXE oder dem Repository gespeichert werden.

## Phase 0: Fehlerbereinigung und belastbare Tests

Status: **lokaler Grundprüflauf, Datenrundlauf, Server-Client-Durchstichtest und
PWA-Exportprüfung umgesetzt; Geräteabnahme vor Veröffentlichung bleibt offen**

1. Einen frischen Godot-Import vor dem Headless-Test verbindlich machen.
   **Umgesetzt:** `tools/verify-project.ps1`.
2. Verhindern, dass Ressourcen- oder Skriptfehler als bestandener Testlauf
   erscheinen. **Umgesetzt:** Protokollprüfung im lokalen Prüflauf und in CI.
3. Einen CI-Prüflauf für Godot 4.7.1, Tests und `git diff --check` ergänzen.
   **Umgesetzt:** `.github/workflows/quality.yml`.
4. Aktuelle Warnungen und Fehler in den Testprotokollen einzeln prüfen.
   **Aktueller Prüflauf sauber.**
5. Backup, Wiederherstellung, leere Datenstände und Datenmigrationen stärker
   automatisiert testen. **Weitgehend umgesetzt:** Die Tests verwenden einen
   isolierten Benutzerdatenordner und prüfen leere Sparziele, zwei unmittelbar
   aufeinanderfolgende Sicherungen, Sicherheitssicherung, echten
   Wiederherstellungsrundlauf und falsche Backup-Wurzeltypen. Sicherungsordner
   sind kollisionsfrei und unvollständige Kopien gelten nicht mehr als Erfolg.
6. Windows-Vollbild sowie echte schmale Mobilansichten erneut prüfen.
   **Weitgehend umgesetzt:** Windows-Vollbild und eine 390 × 844 Pixel schmale
   Ansicht wurden am 31. Juli 2026 mit einem frischen Export geprüft. Dabei
   wurde der seitlich abgeschnittene Start-/Updatebildschirm gefunden und
   responsiv korrigiert. Die offiziellen Godot-4.7.1-Web-Exportvorlagen sind
   installiert; der reproduzierbare PWA-Export und ein echter Browserlauf mit
   Anmeldung und Sitzungswiederherstellung sind bestanden. Die abschließende
   Prüfung auf realen iPhone-/Android-Geräten folgt vor Veröffentlichung.

Abnahmekriterien:

- ein sauberer Checkout lässt sich ohne Skript- oder Ressourcenfehler testen;
- ein fehlerhaftes Skript oder Asset führt zuverlässig zu einem Fehlschlag;
- vorhandene Finanzdaten und das aktuelle JSON-Format bleiben kompatibel;
- Windows- und Web-Export funktionieren weiterhin.

## Phase 1: Automatische Updateprüfung und Status

Status: **Autonome Windows-Aktualisierung einschließlich sicherem Download,
Datensicherung, stiller Installation, Neustart und Installer-Rückfall im
lokalen Entwicklungsstand umgesetzt; noch nicht veröffentlicht**

Die bereits vorhandene manuelle Manifestprüfung wird zu einem sicheren
Startablauf erweitert.

1. Nach dem Aufbau der Oberfläche automatisch genau eine Updateprüfung starten.
   **Umgesetzt im lokalen Entwicklungsstand.**
2. Auf dem Start-/Statusbildschirm einen Updatestatus mit mindestens folgenden
   Zuständen anzeigen: **Prüfung läuft**, **App ist aktuell**,
   **Update verfügbar**, **offline** und **Prüfung fehlgeschlagen**.
   **Umgesetzt im lokalen Entwicklungsstand.**
3. Die App darf bei fehlender Verbindung ohne Verzögerung weiter nutzbar sein.
   **Umgesetzt:** kurze Zeitgrenze und überspringbare Prüfung.
4. Bei einer neuen Version Versionsnummer und den laufenden automatischen
   Aktualisierungsvorgang anzeigen. Die manuelle Aktion bleibt als Rückfall
   erhalten. **Umgesetzt im lokalen Entwicklungsstand.**
5. Windows-Downloads vor der Ausführung mit veröffentlichter SHA-256-Prüfsumme
   und später zusätzlich mit Codesignatur prüfen.
   **SHA-256 umgesetzt:** Manifest, Installer- und Prüfsummenadresse werden
   strikt auf das eigene Repository und die erwartete Version begrenzt. Eine
   abweichende Datei wird gelöscht und niemals gestartet. Codesignatur folgt
   nach Stabilisierung.
6. PWA-Aktualisierungen mit einem verständlichen Hinweis und kontrolliertem
   Neuladen verbinden.
7. Die manuelle Schaltfläche **Nach Updates suchen** als erneute Prüfung
   beibehalten. **Umgesetzt.**
8. Den offiziellen Windows-Download auf
   `Meine-Budgetwelt-Setup-<Version>.exe` umstellen. Der Installer enthält die
   komprimierte Anwendung vollständig und benötigt während der Installation
   keinen weiteren Download. **Build und Manifest umgesetzt; noch nicht
   veröffentlicht.**
9. Standardmäßig benutzerbezogen ohne Administratorrechte installieren,
   einen Startmenü-Eintrag anlegen und eine Desktopverknüpfung nur auf Wunsch
   erstellen. **Umgesetzt und lokal geprüft.**
10. Vor jedem Update automatisch eine Datensicherung erzeugen. Eine neuere
    Version aktualisiert die bestehende Installation ohne Verlust
    persönlicher Daten und kann bei einem technischen Fehlschlag auf die
    vorherige funktionierende Programmversion zurückfallen.
    **Umgesetzt und isoliert geprüft:** Bei Sicherungsfehler startet das Setup
    nicht; der Installer hält die bisherige EXE als Rückfallkopie und stellt sie
    bei einem erzwungenen Installationsfehler wieder her.
11. In einer regulären Windows-Installation das geprüfte Update selbständig
    herunterladen, nach dem Beenden der App still installieren und die App
    anschließend neu starten. Portable Entwicklungs-EXEs oder unerwartete
    Installationspfade werden nicht autonom überschrieben.
    **Umgesetzt im lokalen Entwicklungsstand.**
12. Erneute Ausführung derselben Setup-Version bietet eine verständliche
    Reparatur. Die Deinstallation entfernt Programmdateien vollständig, lässt
    persönliche Daten aber ohne ausdrückliche Löschbestätigung bestehen.
    **Umgesetzt und isoliert geprüft:** dieselbe Version bietet Reparatur,
    neuere Versionen werden als Update erkannt und eine stille Rückstufung auf
    eine ältere Version wird verhindert.

Die regulär installierte **Windows-Client-App** aktualisiert sich nach einer
gültigen Manifest- und SHA-256-Prüfung autonom. Die erste Installation von
0.39.3 muss noch einmal manuell erfolgen, weil die bereits veröffentlichte
0.39.2 den neuen Aktualisierungscode nicht nachträglich erhalten kann. Danach
laufen Download, Sicherung, stille Installation und Neustart selbständig. Der
getrennte Root-Serverdienst wird gemäß Phase 1a nach gültiger kryptografischer
Prüfung ebenfalls autonom aktualisiert.

Abnahmekriterien:

- jeder App-Start zeigt einen nachvollziehbaren Prüfstatus;
- offline startet die App normal und zeigt keinen blockierenden Fehlerdialog;
- ein verfügbares Update wird nur von den offiziellen Projektadressen geladen;
- der Update-Download verweist auf den Installer und nicht auf die interne
  portable Entwicklungs-EXE;
- lokale Finanz-, Einkaufs- und Rezeptdaten bleiben bei Updates unverändert;
- fehlerhafte Prüfsumme oder Signatur verhindert die Installation;
- eine reguläre Installation wird nach einem erfolgreichen Update automatisch
  neu gestartet;
- Installation, Update, Reparatur und Deinstallation bestehen einen Test auf
  einem frischen Windows-Benutzerprofil.

## Phase 1a: Eigener Server, Konten, Synchronisation und PWA-Zugangsschutz

Status: **lokale Server-, Konto-, Login-, Synchronisations-, Admin-,
Windows-Dienst- und Auto-Update-Grundlage umgesetzt und durchgängig geprüft;
Root-Server-Installation und echte Geräteabnahme noch offen**

**Umgesetzt am 31. Juli 2026:** Das Repository wurde auf `unique1986`
übertragen und die öffentliche GitHub-Pages-Site in den Repository-Einstellungen
deaktiviert. Der Pages-Workflow startet nicht automatisch bei einem Push und
besitzt zusätzlich die Freigabeschranke `PWA_AUTH_ENABLED=true`.

Die nächste PWA darf erst nach Umsetzung und Abnahme des serverseitigen Logins
veröffentlicht werden. Eine nur im ausgelieferten JavaScript geprüfte PIN oder
ein dort hinterlegtes Passwort gilt nicht als Sicherheit und ist ausgeschlossen.

**Umgesetzt am 31. Juli 2026:** Das erste .NET-Servergrundgerüst läuft als
eigenständig veröffentlichbare `Meine-Budgetwelt-Server.exe`, bindet
standardmäßig nur an `127.0.0.1:48732`, legt ausschließlich im eigenen
Datenstamm eine SQLite-Datenbank an und stellt eine Gesundheitsprüfung bereit.
Der Release-Build ist warnungsfrei; der vollständige NuGet-Abhängigkeitsbaum
wurde ohne bekannte Schwachstellen geprüft. Ein isolierter Starttest mit
temporärer Datenbank ist bestanden. Die Windows-Dienstinstallation, die
sichtbare Admin-Oberfläche und das autonome signierte Serverupdate sind
inzwischen ebenfalls umgesetzt und isoliert geprüft.

**Kontenkern ebenfalls lokal umgesetzt:** Das erste Administratorkonto wird
einmalig vor dem öffentlichen Start über einen kennwortgeschützten
Bootstrap-Befehl angelegt. PWA-Anmeldung verwendet ein
`HttpOnly`-/`Secure`-/`SameSite=Strict`-Cookie; die Desktop-App erhält ein
separates und serverseitig widerrufbares Sitzungstoken. Benutzer können erstellt,
aktiviert und gesperrt sowie gemeinsamen Budgetgruppen mit den Rollen
`owner`, `manager` und `member` zugeordnet werden. Eine Sperre widerruft
laufende Sitzungen.

**Einladung und Kontowiederherstellung ebenfalls umgesetzt:** Der Admin kann
eine 48 Stunden gültige Einladung für eine bestimmte E-Mail-Adresse und
Budgetgruppe versenden. Der Empfänger vergibt Name und Kennwort selbst; der
Einladungslink ist nur einmal verwendbar. `Kennwort vergessen` versendet einen
30 Minuten gültigen Einmallink, widerruft ältere Resetlinks und beendet nach
erfolgreicher Kennwortänderung alle bestehenden Sitzungen. SMTP-Zugangsdaten
liegen ausschließlich in der Serverkonfiguration beziehungsweise als
Umgebungsgeheimnis. Der isolierte Durchstichtest prüft beide E-Mail-Abläufe.
**Synchronisation und Client-Anmeldung lokal umgesetzt:** Windows-App und PWA
verwenden denselben Kontenkern und dieselben Budgetgruppen. Acht fachliche
Datendateien werden als validierter, versionierter Snapshot synchronisiert.
Optimistische Revisionsprüfung verhindert, dass ein veralteter Client neuere
Daten unbemerkt überschreibt. Der Desktop speichert nur ein verschlüsseltes,
serverseitig widerrufbares Sitzungstoken; die PWA nutzt das sichere Cookie.
Nach einer Serveränderung werden auch die bereits laufenden lokalen Manager neu
geladen. Ein automatischer Test über zwei getrennte Godot-Clients sowie ein
echter PWA-Browserlauf mit Anmeldung und Sitzungswiederherstellung sind grün.
Der installierbare Desktop-Client ist auf `https://budget.leno.info`
vorkonfiguriert; die PWA verwendet weiterhin automatisch ihre Serverherkunft.
Der separate Login wurde im 390 × 844-Pixel-Mobilformat vollständig ohne
horizontales Abschneiden geprüft.

**PWA-Auslieferung lokal umgesetzt:** Der Budgetwelt-Server kann den Godot-Web-
Export unter derselben Herkunft wie die API ausliefern. Dadurch funktionieren
PWA-Cookie und Synchronisation ohne fremde Cross-Origin-Freigaben. Der Server
setzt restriktive Sicherheitsheader und verhindert dauerhaftes Caching von
Startdatei und Service Worker. `tools/verify-pwa.ps1` baut den Export und prüft
Paketinhalt, MIME-Typen, Sicherheitsheader, Sitzungscookie sowie den Schutz der
Synchronisations-API.

**Server-Installer und Windows-Dienst lokal umgesetzt:** Die kompakte
NSIS-Setup-EXE installiert den selbstenthaltenen Server unter `Program Files`,
legt Konfiguration, SQLite-Datenbank und Sicherungen ausschließlich im eigenen
`ProgramData`-Stamm ab, richtet den Dienst als eingeschränktes `LocalService`-
Konto ein und öffnet keinen Firewall-Port. Portprüfung, Erstanlage des Admins
ohne Kennwort in Befehlszeile oder Log, Gesundheitsprüfung, Rückfall bei
fehlgeschlagenem Start und Datenerhalt bei Deinstallation sind umgesetzt. Ein
erhöhter E2E-Lauf unter einem Installationspfad mit Leerzeichen hat den sicher
gequoteten Dienstpfad, Dienststart, Admin-Anmeldung, PWA/API, Datenbank,
Update-Sicherung, erneuten gesunden Start und Deinstallation bestätigt.

**Admin-Oberfläche lokal umgesetzt und visuell abgenommen:** Unter `/admin/`
steht eine eigene responsive Verwaltung im freigegebenen Glas-Design bereit.
Sie verwaltet Benutzer, Sperren, Budgetgruppen, Rollen und Einladungen und
zeigt Server-, Datenbank- und Updatezustand. Desktop- und 390 × 844-Pixel-
Mobilansicht wurden in einem echten Browser geprüft; Anmeldung und Sitzung
bleiben beim Neuladen erhalten.

**Autonomes signiertes Serverupdate lokal umgesetzt:** Eine als `SYSTEM`
ausgeführte, auf den Budgetwelt-Namen begrenzte Windows-Aufgabe prüft fünf
Minuten nach Systemstart und täglich um 03:15 Uhr einen eigenen stabilen
Updatekanal. Manifest und SHA-256 des Installers werden mit einem eingebetteten
RSA-Prüfschlüssel kontrolliert; fremde URLs, manipulierte Manifeste,
abweichende Dateien und Downgrades werden abgelehnt. Vor der Installation wird
gesichert, das vollständige bisherige Programmverzeichnis bleibt bis zum
bestandenen Gesundheitstest als Rückfallkopie erhalten. Ein manueller, durch
Bestätigung geschützter GitHub-Workflow kann versionierte Server-Releases
erzeugen und erst danach den stabilen signierten Kanal umschalten. Es wurde
nichts veröffentlicht.

**Domain vorbereitet:** Der installierte Server ist auf
`https://budget.leno.info` vorkonfiguriert. Ein konfliktfreier Caddy-Block für
den ausschließlich lokalen Upstream `127.0.0.1:48732` liegt unter
`ops/caddy/budget.leno.info.caddy`; eine zusammengeführte Prüffassung der vom
Projekteigentümer bereitgestellten Caddy-Datei wurde erzeugt. Die echte
Installation, Caddy-Validierung, HTTPS-Abnahme und Mobilgeräteprüfung auf dem
Root-Server bleiben offen.

### Verbindliche Serverarchitektur

1. Einen eigenständigen, installierbaren
   `Meine-Budgetwelt-Server.exe`-Windows-Dienst mit eigener Admin-Oberfläche
   bereitstellen.
2. Programm, Daten, Sicherungen und Protokolle in eindeutig eigenen
   Verzeichnissen ablegen. Der Server darf keine vorhandene Datenbank, keinen
   Datenbankbenutzer und keinen bestehenden Dienst verändern.
3. Für die vorgesehenen ein bis drei Nutzer eine eingebettete SQLite-Datenbank
   verwenden. Sie öffnet keinen Datenbankport und benötigt keinen zusätzlichen
   Datenbankdienst.
4. Den internen HTTP-Port bei der Installation auf Belegung prüfen,
   konfigurierbar machen und standardmäßig ausschließlich an `127.0.0.1`
   binden. Öffentlicher Zugriff erfolgt nur über eine eigene HTTPS-Adresse und
   den Reverse-Proxy des Root-Servers.
5. Benutzerkonten, Rollen und gemeinsame Budgetgruppen verwalten. Ein
   Administrator kann Konten erstellen, sperren, wieder freigeben und einer
   oder mehreren Budgetgruppen zuordnen.
6. Es gibt keine offene Selbstregistrierung. `Konto erstellen` verwendet eine
   vorherige Einladung oder benötigt eine Admin-Freigabe.
7. Desktop-App und PWA verwenden dieselbe Authentifizierung und
   Synchronisations-API. Lokale Daten dienen danach als Offline-Kopie und
   Sicherung, nicht als voneinander getrennter Hauptdatenbestand.
8. OpenAI- und GoCardless-Geheimnisse sowie Bankzugriffstoken liegen
   ausschließlich im Serverdienst und niemals in Client, PWA-Cache oder
   Repository.
9. Der Server prüft selbständig nach dem Start und täglich auf signierte
   Updates. Vor der Installation sichert er Datenbank und Konfiguration,
   installiert atomar und führt einen Gesundheitstest aus. Bei einem Fehler
   wird automatisch die vorherige Version wiederhergestellt.
10. Server-Updates mit einer eingebetteten, kostenfreien kryptografischen
    Release-Signatur und SHA-256 absichern. Automatische Downgrades sind
    ausgeschlossen.

### Konto- und PWA-Schutz

1. PWA und zugehörige Backend-APIs serverseitig vor nicht angemeldeten
   Zugriffen schützen.
2. Nur einzeln freigeschaltete Konten für die vorgesehenen ein bis drei Nutzer
   zulassen; keine öffentliche Registrierung.
3. Sichere Sitzungscookies mit `HttpOnly`, `Secure`, geeignetem `SameSite`,
   begrenzter Laufzeit und serverseitigem Widerruf verwenden.
4. Anmeldeversuche begrenzen und Schutz gegen automatisiertes Ausprobieren,
   Sitzungsübernahme und CSRF vorsehen.
5. Abmeldung, Sitzungsablauf und verständliche Kontowiederherstellung anbieten.
6. Persönliche Finanz-, Einkaufs- und Planungsdaten nicht in öffentlich
   abrufbare PWA-Caches schreiben; private Caches bei Abmeldung entfernen.
7. Für installierte PWAs auf gemeinsam genutzten Geräten zusätzlich eine
   lokale App-Sperre beziehungsweise Geräteentsperrung vorsehen.
8. Das PWA-Hosting von rein öffentlichen GitHub Pages auf einen Dienst mit
   serverseitiger Zugriffskontrolle umstellen oder durch ein entsprechendes
   Authentifizierungs-Gateway schützen.
9. Bis zur Abnahme des Logins keine neue PWA ausrollen. Der vorhandene
   Pages-Workflow darf nur mit der ausdrücklichen Repository-Freigabevariable
   `PWA_AUTH_ENABLED=true` laufen und startet nicht mehr automatisch bei einem
   Push auf `main`.

### Freigegebenes Oberflächendesign

Die am 31. Juli 2026 erstellten drei Designvorschauen sind als verbindliche
visuelle Zielrichtung freigegeben:

- separater Login-Bildschirm für Desktop;
- responsiver Login-Bildschirm für die mobile PWA;
- angemeldete Startseite mit großer, unveränderter Budgetwelt-Illustration,
  hochwertigem dunklem Glas-Stil, zurückhaltenden Türkis- und Goldakzenten
  sowie sichtbarem Synchronisationsstatus.

Die bisherige Überschrift `Deine Budgetwelt` wird durch eine
tageszeitabhängige persönliche Begrüßung ersetzt: `Guten Morgen, <Name>`,
`Guten Tag, <Name>` oder `Guten Abend, <Name>`.

Kontoerstellung verlangt Name, E-Mail-Adresse und ein Kennwort mit mindestens
acht Zeichen. Kennwort anzeigen, angemeldet bleiben und eine funktionierende
Kontowiederherstellung gehören zum Pflichtumfang. Kennwörter werden niemals im
Klartext gespeichert.

Abnahmekriterien:

- ein nicht angemeldeter Browser erhält weder die private App-Oberfläche noch
  persönliche Daten;
- ungültige oder abgelaufene Sitzungen werden serverseitig abgewiesen;
- nach Abmeldung sind private Daten nicht mehr aus Cache oder Verlauf abrufbar;
- es existiert keine offene Registrierung;
- der Zugriff jedes freigeschalteten Kontos kann einzeln entzogen werden;
- PWA, OpenAI-Backend und GoCardless-Backend verwenden denselben verbindlichen
  Benutzer- und Sitzungsgrenzschutz.
- Desktop und PWA zeigen nach abgeschlossener Synchronisation denselben
  fachlichen Datenstand;
- Benutzer derselben Budgetgruppe sehen die gemeinsam freigegebenen Daten,
  nicht zugeordnete Benutzer erhalten keinen Zugriff;
- Serverinstallation und -updates verändern keine bestehenden Datenbanken oder
  Dienste und fallen bei einem fehlgeschlagenen Update automatisch zurück.

## Phase 2: Sichtbarer Wocheneinkauf, Rezepte und Speiseplan

Status: **nach Server-, Konto- und Synchronisationsgrundlage aus Phase 1a**

1. Die vorhandenen internen Rezept-, Einkaufs- und Speiseplanmodule prüfen und
   nur die weiterhin geeigneten Teile kontrolliert reaktivieren.
2. Personenanzahl, Portionen, Allergien, Unverträglichkeiten, Ernährungsweise,
   Vorlieben, Kochzeit und vorhandene Vorräte verwalten.
3. Wochenbudget, veränderbaren Sicherheitspuffer und maximales Planungsziel
   verbinden.
4. Packungspreise, tatsächlich benötigte Einkaufsmenge, Restmengen und
   persönliche Kassenpreise getrennt berechnen.
5. **Wocheneinkauf**, **Rezepte** und **Speiseplan** als dauerhaft sichtbare,
   direkt erreichbare Bereiche für Mobilgeräte und Desktop einführen.
6. Pro Rezept und Tag die voraussichtlichen Kosten sowie für die ganze Woche
   Einkaufssumme, Sicherheitspuffer und verbleibendes Budget anzeigen.
7. Schätzpreise klar von tatsächlich bezahlten Kassenpreisen unterscheiden.

Abnahmekriterien:

- die Planungslogik kann einen strukturierten Wochenplan ohne ungültige oder
  doppelte Zutaten verarbeiten;
- Allergien und Unverträglichkeiten haben immer Vorrang;
- Planungsziel und vollständiges Wochenbudget werden nachvollziehbar geprüft;
- Kosten pro Rezept, Tag und Woche sind vor dem Einkauf sichtbar;
- ältere gespeicherte Einkaufsdaten werden nicht ungefragt gelöscht.

## Phase 3: Verbindliche KI-Planung mit OpenAI

Status: **fester Zielumfang nach Phase 2**

Die OpenAI-Unterstützung erstellt passend zum verfügbaren Wochenbudget einen
alltagstauglichen Plan mit Rezepten, Resteverwertung und Einkaufsliste.

Vorgesehene Eingaben:

- Wochenbudget und Sicherheitspuffer;
- Personenanzahl und Portionen;
- Allergien, Unverträglichkeiten und Ernährungsweise;
- bevorzugte oder abgelehnte Zutaten;
- vorhandene Vorräte und persönliche Preisbasis;
- verfügbare Kochzeit und gewünschte Planungsart.

Vorgesehene Ergebnisse:

- sieben Tage mit Gerichten und Portionen;
- strukturierte Rezepte mit Zutaten und Zubereitung;
- zusammengefasste Einkaufsliste;
- geschätzte Packungskosten und Restmengen;
- ausgewiesener Sicherheitspuffer und verbleibendes Budget;
- Hinweise zu Meal-Prep und Resteverwertung.

Technische und fachliche Grenzen:

- Die Integration verwendet die OpenAI Responses API über einen kleinen
  geschützten Backenddienst.
- Antworten werden als strukturiertes, schema-validiertes Ergebnis verarbeitet.
- Das verwendete Modell wird serverseitig konfiguriert und vor der Festlegung
  anhand von Qualität, Kosten und Latenz bewertet; es wird nicht fest in der
  Godot-Oberfläche verdrahtet.
- Die KI darf keine Budgetwerte buchen oder Finanzdaten verändern.
- Berechnete Packungskosten und Budgetgrenzen werden nach der KI-Antwort erneut
  durch lokale Calculator-Logik geprüft.
- Rohumsätze, IBAN, Kontoinhaber, PIN, TAN oder Bankzugangsdaten werden nicht an
  OpenAI übertragen. Zulässig sind nur die für die Planung benötigten, vom
  Benutzer bestätigten Angaben und abgeleiteten Budgetwerte.
- API-Schlüssel werden niemals in Clientcode oder lokalen Datensicherungen
  abgelegt.
- Bei einer Dienststörung bleiben gespeicherte Pläne, manuelle Planung und alle
  Finanzfunktionen verfügbar. Das ist eine Ausfallsicherung; die KI-Planung
  bleibt dennoch verbindlicher Produktbestandteil.

Offizielle technische Referenzen:

- [OpenAI Structured Outputs](https://developers.openai.com/api/docs/guides/structured-outputs)
- [OpenAI Safety Best Practices](https://developers.openai.com/api/docs/guides/safety-best-practices)

Abnahmekriterien:

- strukturierte Antworten entsprechen dem festgelegten Schema;
- Pläne oberhalb des Planungsziels werden korrigiert oder abgelehnt;
- Allergien und ausgeschlossene Zutaten werden automatisiert geprüft;
- jeder KI-Plan zeigt Preisbasis, Schätzcharakter und Sicherheitspuffer;
- Übertragung und Löschung der Planungsdaten sind transparent dokumentiert.

## Phase 4: Read-only-Bankanbindung mit GoCardless

Status: **verbindlicher Zielumfang nach der KI-Planungsgrundlage**

GoCardless Bank Account Data wird ausschließlich für einen manuellen,
lesenden Abruf verwendet.

Damit werden umgesetzt:

- Kontostand abrufen;
- neue Buchungen importieren;
- doppelte Buchungen erkennen;
- Einnahmen und Ausgaben nach Bestätigung übernehmen;
- vorhandene manuelle Funktionen weiterhin nutzen;
- Überweisungen und andere Zahlungen vollständig ausschließen.

Sicherheits- und Datenschutzregeln:

- Der Abruf startet nur über **Bank aktualisieren** oder eine vergleichbar
  eindeutige Benutzeraktion; keine unbemerkte Hintergrundsynchronisierung.
- Anmeldung und starke Authentifizierung erfolgen bei der Bank beziehungsweise
  im von GoCardless vorgesehenen Ablauf.
- Die App fragt keine PIN oder TAN ab und speichert keine Bankzugangsdaten.
- GoCardless-Geheimnisse und Zugriffstoken liegen nur in einem geschützten
  Backend, niemals in GitHub Pages oder der Windows-EXE.
- Importierte Buchungen werden anhand stabiler Bank-IDs und eines geprüften
  Fallback-Fingerprints dedupliziert.
- Bankverbindungen können getrennt und zugehörige Tokens gelöscht werden.
- Die vorhandene lokale Datenspeicherung und manuelle Erfassung bleiben
  unabhängig von GoCardless funktionsfähig.
- Es wird kein Zahlungsauslösedienst implementiert.

Abnahmekriterien:

- erneuter Abruf erzeugt keine doppelten Buchungen;
- ein Abbruch oder Ausfall verändert keine vorhandenen Finanzdaten;
- jede Übernahme wird nachvollziehbar angezeigt und bestätigt;
- die App besitzt keine Funktion zum Auslösen einer Zahlung;
- die Verbindung lässt sich vollständig widerrufen.

## Phase 5: Gemeinsame Integration, Codesignatur und Veröffentlichung

1. Wochenbudget aus manuellen oder bestätigten importierten Buchungen ableiten.
2. Nur den abgeleiteten, bestätigten Planungsbetrag an die KI-Planung übergeben.
3. Windows, iPhone-PWA und Android-PWA vollständig prüfen.
4. Vor jeder neuen PWA-Veröffentlichung den verbindlichen Login aus Phase 1a
   und den Schutz aller privaten Backend-Endpunkte abnehmen.
5. Kosten-, Datenschutz- und Löschinformationen in der App anzeigen.
6. Den reproduzierbaren Windows-Release aus Godot-App, komprimierter Setup-EXE,
   Uninstaller und SHA-256-Datei erzeugen. Nur die Setup-EXE ist der reguläre
   Endnutzer-Download; die rohe App-EXE bleibt ein internes Testartefakt.
   **Umgesetzt mit NSIS und lokal vollständig getestet.**
7. Frühzeitig prüfen, ob das Projekt die Bedingungen der SignPath Foundation
   für kostenlose Open-Source-Codesignatur erfüllt. Die eigentliche
   Release-Integration erfolgt, sobald Build und Updateablauf stabil sind.
8. Vor einer Bewerbung eine passende OSI-anerkannte Projektlizenz auswählen
   und als `LICENSE` dokumentieren. Diese rechtliche Auswahl erfolgt nicht
   automatisch oder ohne ausdrückliche Entscheidung des Projekteigentümers.
9. Setup-EXE, Uninstaller und installierte Programmdateien signieren sowie
   Signaturprüfung und Zeitstempel in den Release-Workflow aufnehmen, sofern
   die kostenlose Aufnahme bestätigt wird.
10. Falls die kostenlose Codesignatur nicht verfügbar ist, bleibt SHA-256 die
   Mindestprüfung; eine kostenpflichtige Lösung wird nicht ohne neuen Auftrag
   gebucht.
11. Erst nach vollständiger Abnahme eine neue Version, PWA und Windows-Datei
   veröffentlichen.

Aktueller Hinweis: Im Repository ist noch keine `LICENSE`-Datei vorhanden.
Damit sind die veröffentlichten SignPath-Bedingungen derzeit noch nicht
vollständig erfüllt.

Referenz für die kostenlose Open-Source-Prüfung:

- [SignPath Foundation](https://signpath.org/)
- [Bedingungen für kostenlose Open-Source-Codesignatur](https://signpath.org/terms.html)

## Nicht vorgesehen

- Überweisungen, Lastschriften oder andere Zahlungsauslösungen;
- Speicherung von PIN, TAN oder Online-Banking-Passwörtern;
- automatische Weitergabe vollständiger Bankumsätze an OpenAI;
- Zwang zur Bankverbindung, damit die manuellen Finanzfunktionen arbeiten;
- unkontrollierte Updateinstallation ohne Manifest-, Herkunfts- und
  Integritätsprüfung;
- erneute Veröffentlichung einer ungeschützten PWA;
- reine Client-PIN oder ein im Browsercode hinterlegtes gemeinsames Passwort
  als vermeintlicher PWA-Zugangsschutz;
- Veröffentlichung, Tag oder Release ohne ausdrücklichen Auftrag.
