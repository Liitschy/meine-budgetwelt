# Fachkonzept: Preise und Wocheneinkauf

## Ziel

Die Anwendung erstellt einen alltagstauglichen Wochenplan, der ein vorgegebenes
Einkaufsbudget möglichst sicher unterschreitet. Die Planung verbindet Rezepte,
Meal-Prep, schnelle Gerichte, ausgewählte Fertiggerichte, Eigenmarken und
bereits vorhandene Vorräte.

Alle vor dem Einkauf angezeigten Preise sind Schätzwerte. Nach dem Einkauf kann
der tatsächliche Kassenbetrag erfasst werden.

## Verbindlicher Produktbestandteil

Die KI-gestützte Planung mit OpenAI ist ein fester Bestandteil des
Zielprodukts. Sie wird nach der technischen Fehlerbereinigung und der
Stabilisierung der lokalen Planungslogik umgesetzt.

Die KI erstellt Vorschläge, aber sie ist nicht die Quelle der verbindlichen
Budgetberechnung. Wochenbudget, Sicherheitspuffer, Packungskosten und
Allergieprüfungen werden zusätzlich durch deterministische lokale Logik
validiert. Ein Plan darf erst übernommen werden, wenn diese Prüfung erfolgreich
war.

Wocheneinkauf, Rezepte und Speiseplan sind dauerhaft sichtbare Bereiche der
Anwendung. Sie werden nicht als versteckte Altmodule oder reine Hintergrundlogik
geführt.

## Preisgrundlage

- Ausgangspunkt sind realistische Durchschnittspreise deutscher Supermärkte und
  Discounter.
- Standardmäßig wird das Preisniveau günstiger Eigenmarken verwendet.
- Preise werden mit Quelle beziehungsweise Preisbasis und Aktualisierungsdatum
  gespeichert.
- Nicht ausreichend aktuelle Preise werden sichtbar als Schätzung
  gekennzeichnet.
- Regionale, filialabhängige und kurzfristige Abweichungen werden ausdrücklich
  berücksichtigt.
- Die Anwendung gibt keine Preisgarantie.

## Sichere Budgetplanung

Die KI plant nicht bis zur vollständigen Budgetgrenze. Standardmäßig werden
zehn Prozent als Sicherheitspuffer reserviert.

Beispiel:

- Wochenbudget: 70,00 Euro
- Sicherheitspuffer: 7,00 Euro
- maximales Planungsziel: 63,00 Euro

Der Benutzer kann den Puffer später verändern. Die Anwendung warnt, wenn ein
Plan den Zielbetrag oder das vollständige Wochenbudget überschreitet.

## Einkaufswert und Verbrauchswert

Für die Budgetberechnung zählt der Preis der Packung, die tatsächlich gekauft
werden muss. Der anteilige Verbrauchspreis eines Rezepts dient nur der
Auswertung.

Beispiel:

- Packung Reis: 1 Kilogramm für geschätzt 2,49 Euro
- Bedarf der geplanten Rezepte: 400 Gramm
- Belastung des Einkaufsbudgets: 2,49 Euro
- Packungsüberschuss: ungefähr 600 Gramm

Dadurch unterschätzt die Anwendung den Betrag an der Kasse nicht. Der
Packungsüberschuss wird nur als Information angezeigt.

## Preisstrategie der KI

Bei der Erstellung eines Plans bevorzugt die KI:

1. günstige Grundnahrungsmittel wie Kartoffeln, Reis, Nudeln, Hülsenfrüchte und
   Eier;
2. saisonales, lagerbares oder tiefgekühltes Obst und Gemüse;
3. günstige Eigenmarken;
4. Zutaten, die in mehreren Gerichten verwendet werden;
5. passende Großpackungen, wenn deren Rest sinnvoll eingelagert oder zeitnah
   verbraucht werden kann;
6. vorhandene Vorräte;
7. Resteverwertung und Meal-Prep.

Eine Großpackung wird nicht allein wegen des niedrigeren Kilopreises empfohlen.
Die KI berücksichtigt auch den Kassenpreis, den erwarteten Verbrauch und das
Risiko, dass Lebensmittel verderben.

## Planungsarten

### Sehr günstig

Plant deutlich unter dem Budget, verwendet viele günstige Grundzutaten und
priorisiert Resteverwertung.

### Ausgewogen

Gewichtet Preis, Abwechslung, Nährwert und Arbeitsaufwand möglichst gleichmäßig.

### Bequem

Erlaubt mehr schnelle Produkte und ausgewählte Fertiggerichte, solange
Planungsziel und Wochenbudget eingehalten werden.

## Alltagstaugliche Planung

Die Planung kombiniert normales Kochen, Meal-Prep, schnelle Gerichte,
Restetage und bewusst eingeplante Fertiggerichte. Zutaten sollen möglichst
über mehrere Tage verwendet werden.

## Persönliche Vorgaben

Für die Planung können gespeichert werden:

- Personenzahl und benötigte Portionen;
- bevorzugte und abgelehnte Zutaten;
- Allergien und Unverträglichkeiten;
- Ernährungsweise;
- bevorzugte Supermärkte;
- gewünschte Eigenmarken-Priorität;
- maximale Koch- und Vorbereitungszeit;
- vorhandene Kühl-, Gefrier- und Aufwärmmöglichkeiten.

Gesundheitsrelevante Einschränkungen haben immer Vorrang vor Preis und Komfort.

## OpenAI-Integration und Datenminimierung

- OpenAI wird über einen geschützten Backenddienst und nicht direkt aus der PWA
  oder Windows-EXE aufgerufen.
- Die Antwort wird in einem festen strukturierten Schema für Tage, Rezepte,
  Zutaten, Einkaufsliste und Schätzkosten angefordert.
- Übermittelt werden nur die vom Benutzer bestätigten Planungsangaben.
- Vollständige Kontoumsätze, IBAN, Kontoinhaber und Bankzugangsdaten gehören
  nicht zu den KI-Eingaben.
- Ein aus manuellen oder importierten Buchungen abgeleitetes Wochenbudget wird
  nur als Betrag und nur nach Bestätigung verwendet.
- API-Schlüssel werden weder im Repository noch in lokalen Sicherungen
  gespeichert.
- Bei Nichterreichbarkeit bleiben vorhandene Pläne und eine manuelle Planung
  nutzbar; die KI-Planung bleibt dennoch Teil des verbindlichen Zielumfangs.

## Ablauf eines Wocheneinkaufs

1. Wochenbudget festlegen.
2. Sieben fertige Rezepte für zwei Personen ansehen.
3. Anwendung bildet daraus eine zusammengefasste Einkaufsliste.
4. Benötigte Packungen werden mit Schätzpreisen berechnet.
5. Nach dem Einkauf wird der tatsächliche Kassenbetrag eingetragen.
6. Der tatsächliche Betrag wird dem Monatsbudget zugeordnet.

## Transparenz in der Oberfläche

Die Anwendung zeigt bei jeder Planung:

- voraussichtliche Kosten jedes Rezepts;
- voraussichtliche Tageskosten;
- geschätzte Einkaufssumme;
- verbleibenden Sicherheitspuffer;
- vollständiges Wochenbudget;
- Preisbasis und Aktualisierungsdatum;
- angenommene Eigenmarken;
- neu zu kaufende Packungen;
- voraussichtliche Restmengen.

Die Wochenansicht stellt Planungsziel, voraussichtliche Gesamtkosten,
Sicherheitspuffer und erwarteten Restbetrag unmittelbar nebeneinander dar.
Nach dem Einkauf werden Schätzwert und tatsächlicher Kassenbetrag getrennt
angezeigt.

Vorgesehener Hinweis:

> Realistische Schätzung auf Basis durchschnittlicher Preise deutscher
> Supermärkte und Discounter. Bevorzugt werden günstige Eigenmarken, saisonale
> Zutaten und mehrfach verwendbare Packungsgrößen. Regionale und kurzfristige
> Preisabweichungen sind möglich.

## Spätere Verbesserung durch persönliche Daten

Nach jedem Einkauf kann die Anwendung tatsächliche Preise, Geschäft und
Packungsgröße speichern. Diese persönlichen Werte erhalten bei zukünftigen
Planungen Vorrang vor allgemeinen Durchschnittspreisen, sofern sie noch
ausreichend aktuell sind.

Finanzdaten werden nicht automatisch an einen KI-Dienst übermittelt. Für die
Planung werden ausschließlich notwendige, bestätigte Eingaben und abgeleitete
Budgetwerte verwendet.
