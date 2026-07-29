# Windows-Testanleitung

## Start

Die portable Testversion liegt unter:

`build/windows/Budget-und-Wocheneinkauf.exe`

Die EXE kann ohne Installation per Doppelklick gestartet werden.

## Empfohlener Testablauf

1. Unter **Monat einrichten** einen eigenen Startkontostand eintragen.
2. Unter **Fixkosten** einen Kostenpunkt hinzufügen und als bezahlt markieren.
3. Unter **Sparen** ein Sparziel und eine Einzahlung anlegen.
4. Unter **Buchungen** eine Ausgabe und eine zusätzliche Einnahme erfassen.
5. Zur Budgetwelt zurückkehren und die aktualisierten Beträge prüfen.
6. Einen neuen Monat anlegen und kontrollieren, ob Fixkosten übernommen und
   wieder als offen angezeigt werden.
7. Über **Daten sichern** eine lokale Sicherung erzeugen.

## Speicherort

Persönliche Daten liegen unter:

`%APPDATA%\Godot\app_userdata\Budget & Wocheneinkauf`

Eine neue Testversion überschreibt diese Daten nicht.

## Bekannte Grenzen

- kein Installer und keine Codesignatur;
- bestehende Einträge können teilweise nur gelöscht und neu angelegt werden;
- die Update-Prüfung besitzt noch keine Veröffentlichungsadresse.
