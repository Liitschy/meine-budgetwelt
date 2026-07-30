# Codex-Projektübergabe: Meine Budgetwelt

Stand: Version **0.39.2** vom 30. Juli 2026

Diese Datei enthält den aktuellen Projektstand und kann zusammen mit dem
Repository an einen neuen Codex-Task übergeben werden. Repository-Code und
aktuelle Tests haben bei Widersprüchen Vorrang vor älteren Chatverläufen.

## 1. Starttext für einen neuen Codex-Task

Den folgenden Text kann man vollständig in einen neuen Codex-Task kopieren:

> Arbeite am Projekt „Meine Budgetwelt“ im Repository
> `https://github.com/Liitschy/meine-budgetwelt`.
>
> Lies vor jeder Änderung zuerst
> `docs/CODEX_PROJEKTUEBERGABE.md`, `README.md`, den aktuellen Git-Status und
> die betroffenen Dateien. Die App wird mit Godot 4.7.1 entwickelt und als
> portable Windows-App sowie als PWA für iPhone und Android veröffentlicht.
>
> Bewahre alle vorhandenen Funktionen, lokalen Finanzdaten und das bestehende
> Datenformat. Es gibt ausdrücklich keine Online-Banking-Anbindung und keine
> KI-Verbindung. Der frühere Wocheneinkauf und Speiseplan sind nicht Teil der
> sichtbaren Anwendung.
>
> Das festgelegte Design ist eine magische Budgetlandschaft mit dunklem
> Navy-/Petrol-Hintergrund, leuchtendem türkisfarbenem Wasser, goldenen
> Rahmen, warmen Serifentiteln und dunklen halbtransparenten Glaskarten.
> Auf dem iPhone bleibt die Landschaft sichtbar. Verwende dort kein großes
> Buch und keinen flächigen Papierhintergrund. Texte müssen über jedem Teil
> der Landschaft gut lesbar sein und dürfen Rahmen nicht berühren.
>
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

Die App ist kein Bankprogramm. Sie ruft keine Kontodaten ab und verarbeitet
keine PIN, TAN oder Zugangsdaten.

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
- Update-Prüfung über ein Manifest auf GitHub Pages;
- Windows-Downloads über GitHub Releases.

## 4. Nicht mehr Bestandteil der sichtbaren App

Der frühere Bereich „Wocheneinkauf“ mit Rezepten, Speiseplan, KI-Vorschlägen,
Vorratsschrank und Schichtarbeit wurde bewusst entfernt.

Einige ältere interne Module und Datendateien für Einkauf, Rezepte und
Speisepläne existieren weiterhin. Sie werden zur Datenverträglichkeit nicht
ungefragt gelöscht, sollen aber ohne neuen ausdrücklichen Auftrag nicht wieder
in der Oberfläche erscheinen.

Ebenfalls nicht vorhanden:

- Online-Banking;
- Kontosynchronisierung;
- Cloud-Synchronisierung zwischen Geräten;
- OpenAI- oder andere KI-API;
- Serverkonto oder Benutzeranmeldung;
- automatische Update-Installation.

## 5. Verbindliche Designrichtung

### Gemeinsame Bildsprache

- magische, hochwertige Fantasy-Budgetwelt;
- dunkles Navy, Petrol und fast schwarzes Blau als Grundfarben;
- leuchtendes Türkis für Wasser, aktive Zustände und Fortschritt;
- warmes Gold für Rahmen, Titel und Navigation;
- Creme nur für gut lesbare Texte;
- elegante Serifenschrift für große Titel und Beträge;
- klare, größere Touch-Flächen;
- hochwertige Symbole statt einfacher Platzhalterzeichen, soweit passende
  Assets vorhanden sind.

### Windows

- große Landschaft als Mittelpunkt der Budgetseite;
- seitliche Navigation;
- Fixkosten, Sparen und Buchungen dürfen die märchenhafte Buch-/Pergamentoptik
  verwenden;
- Inhalte müssen im Vollbild die verfügbare Fläche sinnvoll nutzen;
- keine winzigen, weit auseinandergezogenen Bedienelemente.

### iPhone und andere Mobilgeräte

- Hochformat;
- Landschaft bleibt groß und sichtbar;
- kein großes offenes Buch und kein vollflächiger Papierhintergrund;
- dunkle halbtransparente Glaskarten mit goldener Kontur;
- feste Navigation am unteren Rand mit Budget, Fixkosten, Sparen, Buchungen;
- Karten und Listen werden vertikal gestapelt;
- Texte erhalten bei hellem Hintergrund eine dunkle Kontur oder Glasfläche;
- ausreichend Abstand zwischen Kennzahlenrahmen und nachfolgendem Text;
- keine abgeschnittenen Inhalte rechts;
- keine horizontale Seitennavigation;
- keine zu kleinen Desktop-Ansichten, die lediglich herunterskaliert werden.

## 6. Technische Basis

- Engine: **Godot 4.7.1**
- Sprache: **GDScript**
- Hauptszene: `res://app/Main.tscn`
- Hauptoberfläche: `app/main.gd`
- Landschaftsansicht: `ui/budget_world_view.gd`
- Renderer: GL Compatibility
- Desktop-Viewport: 1440 × 900
- aktuelle Version: 0.39.2

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
- `core/month_manager.gd` – Monatswechsel und Monatshistorie
- `core/storage_manager.gd` – JSON-Speicherung, Backup und Wiederherstellung
- `core/update_manager.gd` – Versions- und Update-Prüfung
- `tests/budget_manager_test.gd` – vorhandene Logiktests
- `tests/TestRunner.tscn` – Headless-Testeinstieg
- `assets/world/budget_world_island.png` – zentrale Landschaft
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

Die PWA speichert lokal im Browserbereich des jeweiligen Geräts. Windows- und
iPhone-Daten werden derzeit nicht miteinander synchronisiert.

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
$godot = 'C:\Godot\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe'
& $godot --headless --path . --scene res://tests/TestRunner.tscn
git diff --check
```

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

`https://github.com/Liitschy/meine-budgetwelt`

Aktuelle PWA:

`https://liitschy.github.io/meine-budgetwelt/v0.39.2/`

Aktuelle Windows-Version:

`https://github.com/Liitschy/meine-budgetwelt/releases/download/v0.39.2/Budget-und-Wocheneinkauf-0.39.2.exe`

Veröffentlichungsablauf:

1. Versionsnummer in `project.godot` erhöhen;
2. Datei- und Produktversion in `export_presets.cfg` angleichen;
3. Tests und Export ausführen;
4. Änderungen auf einem Arbeitsbranch committen und per Pull Request nach
   `main` bringen;
5. für die Windows-Version einen passenden Tag wie `v0.39.3` erstellen;
6. Push auf `main` baut automatisch die PWA;
7. Push des Versionstags baut automatisch EXE und SHA-256-Datei;
8. beide GitHub-Actions abwarten und Links mit HTTP 200 prüfen.

Versionsnummer, Git-Tag und Dateiname müssen übereinstimmen.

## 13. Bekannte Einschränkungen

- keine Cloud- oder Gerätesynchronisierung;
- PWA- und Windows-Daten sind getrennt;
- keine Codesignatur für die Windows-EXE;
- keine automatische Installation neuer Windows-Versionen;
- die PWA kann auf dem iPhone durch Safari-/Service-Worker-Caches kurzzeitig
  eine alte Version zeigen; deshalb existieren versionierte PWA-Links;
- lokale Web-Exports benötigen die zu Godot 4.7.1 passenden Exportvorlagen;
- ein Teil der Oberfläche wird zentral in der großen Datei `app/main.gd`
  erzeugt und sollte langfristig vorsichtig in kleinere UI-Komponenten
  zerlegt werden;
- ältere Shopping- und Rezeptmodule sind intern vorhanden, aber unsichtbar.

## 14. Arbeitsregeln für zukünftige Änderungen

1. Vor jeder Aufgabe `git status`, relevante Dateien und aktuelle Tests prüfen.
2. Fremde Änderungen im Arbeitsverzeichnis nicht überschreiben oder stageen.
3. Pro Auftrag nur einen logisch zusammenhängenden Bereich ändern.
4. Die Landschaft und den festgelegten Fantasy-Stil bewahren.
5. Mobil und Windows nicht mit identischen starren Größen behandeln.
6. Finanzlogik nicht in mehreren UI-Funktionen duplizieren.
7. Bestehende IDs und gespeicherte JSON-Felder nicht ohne Migration umbenennen.
8. Keine Bank-, Cloud- oder KI-Verbindung ohne neuen ausdrücklichen Auftrag.
9. Keine entfernten Einkaufsfunktionen ohne ausdrücklichen Auftrag reaktivieren.
10. Keine Commits, Tags, Pushes oder Releases ohne ausdrücklichen Benutzerwunsch.
11. Nach Änderungen Tests, `git diff --check` und einen risikogerechten Export
    ausführen.
12. Bei visuellen Änderungen echte schmale Mobilansichten und Windows-Vollbild
    prüfen.

## 15. Aktueller Repository-Zustand bei Erstellung dieser Übergabe

- Branch: `main`
- Version/Tag: `v0.39.2`
- letzter veröffentlichter Stand: „Improve mobile readability and spacing“
- PWA- und Windows-Workflow für 0.39.2 erfolgreich
- vor Erstellung dieser Datei bestanden bereits lokale Änderungen an:
  - `assets/ui/fixed_costs_ledger_background.png.import`
  - `assets/ui/transactions_ledger_background.png.import`

Diese beiden Importdateien gehörten nicht zur Übergabe und dürfen nicht
ungeprüft verworfen, gestaget oder committed werden.
