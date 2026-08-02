# Plattform-Architektur

## Zielplattformen

Die Anwendung soll langfristig auf folgenden Wegen verfügbar sein:

1. als benutzerfreundlich installierbare Windows-Anwendung über eine
   kompakte Setup-EXE;
2. als installierbare Web-App (PWA) für den iPhone-Startbildschirm;
3. als PWA und später optional als Android-App.

Die Geschäftslogik für Budget, Fixkosten, Monate und Preise bleibt von der
Darstellung getrennt. Dadurch kann sie später in einer Web-Oberfläche
wiederverwendet oder kontrolliert übertragen werden.

## Finanzdaten und read-only-Bankabruf

Monatslohn, Startkontostand, Fixkosten und tatsächliche Ausgaben können
weiterhin vollständig manuell gepflegt werden. Desktop und geschützte PWA
synchronisieren dieselbe Budgetgruppe über den eigenen Budgetwelt-Server.

Der lokale Entwicklungsstand ergänzt einen ausschließlich lesenden, manuell
ausgelösten Abruf über Enable Banking. Die Live-Abnahme steht noch aus. Die
Anwendung wird auch künftig keine PIN,
TAN oder Online-Banking-Passwörter abfragen und keine Zahlungen auslösen.

## GitHub und iPhone

GitHub Pages kann die statischen Dateien einer Web-App über HTTPS
bereitstellen. Mit Web-App-Manifest und Service Worker kann diese Seite auf dem
iPhone zum Home-Bildschirm hinzugefügt werden.

Geheime Schlüssel oder private Finanzdaten dürfen weder im Repository noch im
öffentlich ausgelieferten Browsercode gespeichert werden.

## Verbindlicher PWA-Login

Die bisherige GitHub-Pages-PWA wurde am 31. Juli 2026 deaktiviert. Die nächste
PWA darf erst wieder veröffentlicht werden, wenn sie vor Auslieferung der
privaten Oberfläche und vor jedem Zugriff auf Backenddaten eine serverseitig
geprüfte Anmeldung verlangt.

Für die vorgesehenen ein bis drei Nutzer werden Konten nur gezielt
freigeschaltet. Eine öffentliche Registrierung ist nicht vorgesehen. Ein
gemeinsames Passwort oder eine PIN im JavaScript wäre aus dem ausgelieferten
Code auslesbar und gilt nicht als Zugangsschutz.

Reine GitHub Pages bieten keine serverseitige Anmeldung. Deshalb muss die PWA
vor der nächsten Veröffentlichung auf geschütztes Hosting umziehen oder hinter
ein Authentifizierungs-Gateway gesetzt werden. Private Daten dürfen nicht in
öffentlich erreichbaren Service-Worker-Caches liegen. Für ein bereits
entsperrtes gemeinsames Gerät wird zusätzlich eine lokale App-Sperre geplant.

## Geschütztes Backend für lokale KI und Enable Banking

Die verbindliche lokale KI-Wochenplanung und der read-only-Bankabruf verwenden
den Budgetwelt-Server. Die KI teilt sich mit Blenk Voice ausschließlich die
loopback-gebundene Ollama-Laufzeit; Datenbanken und Anwendungskonfigurationen
bleiben getrennt. Enable-Banking-App-ID und privater Schlüssel werden nie an PWA oder Windows-EXE
ausgeliefert.

Bankumsätze werden nicht automatisch an die KI weitergegeben. Für die
KI-Planung darf nur ein notwendiger, vom Benutzer bestätigter Planungsbetrag
zusammen mit Rezept- und Ernährungsvorgaben verwendet werden. Die Daten
verlassen den Root-Server nicht.

Desktop und PWA greifen nach Anmeldung auf dieselben serverseitigen Daten der
zugeordneten Budgetgruppe zu. Lokale Daten dienen nur der robusten
Clientnutzung; der authentifizierte Server bleibt die gemeinsame
Synchronisationsstelle.

## Android

Die PWA soll responsiv und offline nutzbar sein. Sie kann auf Android direkt
installiert werden. Später ist außerdem eine Android-Verpackung als Trusted Web
Activity oder eine eigenständige App möglich.

## Responsive Oberfläche

Die laufende Godot-Oberfläche verwendet drei Layoutbereiche:

- Desktop ab 1180 Pixeln: Seitenleiste, Budgetwelt und Zusammenfassung
  nebeneinander;
- Tablet von 900 bis 1179 Pixeln: Seitenleiste bleibt sichtbar, Hauptinhalte
  werden untereinander angeordnet;
- Mobil unter 900 Pixeln: obere Touch-Navigation, vertikale Karten und
  kompakte Fixkostenansicht.

Schmale Inhalte sind scrollbar. Bedienelemente erhalten ausreichend große
Touch-Flächen. Die Grenzwerte werden später anhand realer iPhone- und
Android-Geräte weiter verfeinert.

## Datenschutz

- Finanzdaten werden ausschließlich im Client und auf dem eigenen Server gespeichert.
- Es werden keine Finanzdaten automatisch von Dritten abgerufen.
- Enable Banking wird ausschließlich auf Knopfdruck und nur lesend angesprochen.
- Übertragung erfolgt per HTTPS; Datenexport, Datensicherung und vollständige
  Löschung bleiben verbindliche Funktionen.

## Umsetzungsreihenfolge

1. Enable-Banking-Umstellung und Migration vollständig lokal prüfen;
2. neue Serverversion und Server-Installer bereitstellen;
3. Sandbox-App-ID und privaten PEM-Schlüssel auf dem Root-Server einrichten;
4. den vollständigen Sandbox-Ablauf mit einem Testinstitut abnehmen;
5. später eine getrennte Production-App für die eigenen Konten einrichten;
6. Desktop, iPhone-PWA und Android-PWA gemeinsam mit echter Synchronisation prüfen;
7. kostenlose Codesignatur bei stabiler Version erneut bewerten;
8. erst nach dieser Abnahme Client und geschützte PWA veröffentlichen.

Die vollständige Planung steht in [`ROADMAP.md`](ROADMAP.md).
