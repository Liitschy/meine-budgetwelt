# Technik und Updates

## Technische Basis

Die Windows-Anwendung wird mit Godot 4.7.1 entwickelt. Dadurch kann die
Budgetwelt als lebendige, animierte Oberfläche umgesetzt werden, während
Budgetdaten lokal auf dem PC gespeichert bleiben.

Die Anwendung wird aus Godot exportiert und für Endnutzer in einer kompakten
Setup-EXE verpackt. Auf dem Ziel-PC ist keine separate Godot-Installation
erforderlich.

## Windows-Installer

Der reguläre Windows-Download heißt
`Meine-Budgetwelt-Setup-<Version>.exe`. Er ist ein vollständiger,
komprimierter Offline-Installer. Ein reiner Web-Bootstrapper wird nicht
verwendet: Seine Download-Datei wäre zwar kleiner, die Installation würde aber
von einer funktionierenden Verbindung und einem weiterhin verfügbaren Server
abhängen.

Der Installer muss:

- standardmäßig benutzerbezogen und ohne Administratorabfrage installieren;
- eine kurze deutschsprachige Führung ohne Werbung oder Zusatzsoftware bieten;
- einen Startmenü-Eintrag und einen funktionierenden Uninstaller anlegen;
- die Desktopverknüpfung als verständliche optionale Auswahl anbieten;
- eine bestehende Version erkennen und kontrolliert aktualisieren oder
  reparieren;
- vor jedem Update eine Datensicherung auslösen und bei einem technischen
  Fehlschlag die vorherige Programmversion wiederherstellen können;
- Programmdateien und persönliche Daten strikt trennen;
- bei der normalen Deinstallation persönliche Daten erhalten und deren
  Löschung nur separat und ausdrücklich anbieten.

Die Größenoptimierung erfolgt durch Kompression des Installers und das
Entfernen nicht benötigter Exportdateien. Die installierte App enthält dennoch
die von Godot benötigte Laufzeit; die kleine Setup-Datei darf deshalb nicht
durch einen unzuverlässigen oder intransparenten Nachlade-Installer erkauft
werden.

Die Umsetzung verwendet NSIS mit solidem LZMA, Unicode-Oberfläche und
benutzerbezogener Installation unter
`%LOCALAPPDATA%\Programs\Meine Budgetwelt`. Der lokale Probelauf reduzierte
die Downloadgröße von rund 114,5 MB für die interne Godot-EXE auf rund
31,9 MB für den Installer. Setup, Start der installierten App und Uninstaller
wurden erfolgreich in einem getrennten Testverzeichnis ausgeführt.

## Lokale Daten

Budgetdaten werden im Godot-Benutzerverzeichnis in `budget_data.json`
gespeichert. Dieses Verzeichnis liegt außerhalb der installierten Anwendung.
Eine Aktualisierung der Programmdateien überschreibt daher nicht die
persönlichen Daten.

Vor einer Veröffentlichung werden Datensicherung und versionierte
Datenmigration ergänzt.

## Update-Architektur

Der Autoload `UpdateManager` ist von der eigentlichen Budgetlogik getrennt. Er
prüft ein kleines, über HTTPS bereitgestelltes JSON-Manifest. Ab dem lokalen
Entwicklungsstand 0.39.3 startet die Prüfung bei jedem normalen App-Start
automatisch; die manuelle Schaltfläche bleibt für eine erneute Prüfung erhalten.

Vorgesehenes Format:

```json
{
  "version": "0.39.3",
  "download_url": "https://github.com/unique1986/meine-budgetwelt/releases/download/v0.39.3/Meine-Budgetwelt-Setup-0.39.3.exe",
  "sha256_url": "https://github.com/unique1986/meine-budgetwelt/releases/download/v0.39.3/Meine-Budgetwelt-Setup-0.39.3.sha256"
}
```

Die Manifest-Adresse ist in `project.godot` auf das Asset
`update-manifest.json` des jeweils neuesten GitHub Releases gesetzt. Der
Windows-Release-Workflow erzeugt das Manifest passend zur Projektversion und
verweist auf den offiziellen Setup-Installer sowie dessen SHA-256-Datei. Damit
bleibt die Windows-Updateprüfung unabhängig von der deaktivierten PWA.

## Verbindlicher Startablauf

Im lokalen Entwicklungsstand wird die Prüfung bei jedem normalen App-Start
automatisch mit einer kurzen Zeitgrenze ausgelöst und kann sofort übersprungen
werden. Ein sichtbarer Start-/Statusbildschirm unterscheidet:

- Prüfung läuft;
- aktuelle Version installiert;
- neue Version verfügbar;
- offline;
- Prüfung fehlgeschlagen.

Die manuelle Schaltfläche bleibt erhalten. Ein Netzwerkausfall darf den Start
und die lokalen Funktionen nicht verzögern oder verhindern.

Die produktive Update-Lösung bietet beziehungsweise erhält zusätzlich:

- später signierte Windows-Pakete;
- HTTPS-Download;
- Prüfsumme und Signaturprüfung;
- Wiederherstellung bei einem fehlgeschlagenen Update;
- Datenmigration und vorherige Sicherung;
- autonomen Aufruf der offiziellen Setup-EXE nach erfolgreicher Prüfung und
  sauberem Beenden der laufenden App;
- automatischen Neustart der aktualisierten App.

Bei einer regulär unter `%LOCALAPPDATA%\Programs\Meine Budgetwelt`
installierten Windows-App werden verfügbare Updates selbständig geladen,
geprüft und still installiert. Eine portable oder aus einem unerwarteten Pfad
gestartete Entwicklungs-EXE wird aus Sicherheitsgründen nicht automatisch
überschrieben und behält den manuellen Installer-Start. Das Update-Manifest
verweist für Windows auf den Installer; die portable Godot-Exportdatei ist kein
regulärer Endnutzer-Download.

Im lokalen Entwicklungsstand lädt der `UpdateManager` zuerst die
versionierte SHA-256-Datei und danach den Installer in einen temporären
`user://updates`-Pfad. Manifest, Installer und Prüfsumme müssen exakt zur
Release-Adresse von `unique1986/meine-budgetwelt` und zur angegebenen Version
passen. Erst nach erfolgreicher Datei-Hashprüfung wird der Installer
bereitgestellt. Eine abweichende oder unvollständige Datei wird gelöscht.

Vor dem Start des geprüften Installers erzeugt die App eine Datensicherung.
Schlägt diese bei vorhandenen Daten fehl, wird das Setup nicht gestartet. Ein
separater Update-Helfer wartet auf das vollständige Beenden der App, startet
den NSIS-Installer mit `/S`, prüft dessen Ergebnis und startet anschließend die
installierte App erneut. Bei einem Fehler wird die weiterhin vorhandene oder
vom Installer wiederhergestellte Programmversion gestartet. Der NSIS-Installer
erkennt Erstinstallation, Reparatur und Update, verhindert eine stille
Rückstufung und hält beim Austausch der Programmdatei eine temporäre
Rückfallkopie bereit. Installation, Reparatur, Update, Downgrade-Schutz,
erzwungener Fehlerfall und Wiederherstellung werden durch
`tools/verify-installer.ps1` in einem isolierten Testordner geprüft; Syntax und
Sicherheitsmerkmale des Client-Helfers prüft `tools/verify-client-updater.ps1`.

## Codesignatur

Die kostenlose Open-Source-Codesignatur der
[SignPath Foundation](https://signpath.org/) wird geprüft, sobald der
Release- und Updateablauf stabil ist. Ein früher technischer Probelauf ist
sinnvoll, sobald das endgültige Release-Artefakt und der GitHub-Actions-Ablauf
feststehen. Eine kostenpflichtige Signaturlösung wird nicht ohne ausdrücklichen
Auftrag gebucht.

SignPath verlangt unter anderem eine OSI-anerkannte Open-Source-Lizenz. Im
Repository ist derzeit noch keine `LICENSE`-Datei vorhanden. Die Auswahl einer
Lizenz ist daher eine notwendige, aber ausdrücklich zu bestätigende
Projektentscheidung vor der Bewerbung.

