# Technik und Updates

## Technische Basis

Die Windows-Anwendung wird mit Godot 4.7.1 entwickelt. Dadurch kann die
Budgetwelt als lebendige, animierte Oberfläche umgesetzt werden, während
Budgetdaten lokal auf dem PC gespeichert bleiben.

Die Anwendung wird später als eigenständige Windows-Datei exportiert. Auf dem
Ziel-PC ist keine separate Godot-Installation erforderlich.

## Lokale Daten

Budgetdaten werden im Godot-Benutzerverzeichnis in `budget_data.json`
gespeichert. Dieses Verzeichnis liegt außerhalb der installierten Anwendung.
Eine Aktualisierung der Programmdateien überschreibt daher nicht die
persönlichen Daten.

Vor einer Veröffentlichung werden Datensicherung und versionierte
Datenmigration ergänzt.

## Update-Architektur

Der Autoload `UpdateManager` ist von der eigentlichen Budgetlogik getrennt. Er
kann ein kleines, über HTTPS bereitgestelltes JSON-Manifest prüfen.

Vorgesehenes Format:

```json
{
  "version": "0.2.0",
  "download_url": "https://example.invalid/download"
}
```

Die endgültige Manifest-Adresse wird erst eingerichtet, wenn Download- und
Veröffentlichungsort feststehen. Bis dahin meldet die Anwendung verständlich,
dass die Update-Quelle noch nicht konfiguriert ist.

Eine spätere produktive Update-Lösung muss zusätzlich bieten:

- signierte Windows-Pakete;
- HTTPS-Download;
- Prüfsumme und Signaturprüfung;
- ausdrückliche Bestätigung vor der Installation;
- Wiederherstellung bei einem fehlgeschlagenen Update;
- Datenmigration und vorherige Sicherung.

Die Anwendung installiert niemals still und ohne Zustimmung ein Update.

