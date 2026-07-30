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
- Update-Prüfung über GitHub Pages mit sicherem Download aus GitHub Releases.

Der frühere Wocheneinkauf und Speiseplan sind nicht mehr Teil der sichtbaren
Anwendung. Bereits vorhandene Einkaufsdaten werden nicht ungefragt gelöscht.

## Windows-Testversion

Die portable Testversion liegt unter:

`build/windows/Budget-und-Wocheneinkauf.exe`

Eine Installation ist nicht erforderlich.

## Updates

Der Button **Nach Updates suchen** liest die veröffentlichte Versionsdatei
unter GitHub Pages. Wenn eine neuere Version verfügbar ist, öffnet die App
den offiziellen Windows-Download aus den GitHub Releases dieses Projekts.

Ein Tag im Format `v1.2.3` muss zur Versionsnummer in `project.godot` passen.
Der Workflow `Windows-Version veröffentlichen` erzeugt anschließend
automatisch die portable EXE und eine SHA-256-Prüfsumme.

## Datenschutz

Alle Budget- und Buchungsdaten werden ausschließlich lokal auf diesem PC
gespeichert. Es besteht keine Online-Banking- oder KI-Verbindung.
