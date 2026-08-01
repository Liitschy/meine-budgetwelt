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

## Finanzdaten in Version 0.39.2

Monatslohn, Startkontostand, Fixkosten und tatsächliche Ausgaben werden
ausschließlich vom Benutzer eingetragen. Die veröffentlichte Version 0.39.2
enthält noch keine Bank- oder KI-Verbindung.

Die Roadmap sieht einen ausschließlich lesenden, manuell ausgelösten Abruf über
GoCardless Bank Account Data vor. Die Anwendung wird auch künftig keine PIN,
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

## Geschütztes Backend für OpenAI und GoCardless

Die verbindlich geplante OpenAI-Wochenplanung und der read-only-Bankabruf
benötigen einen kleinen Backenddienst. Dieser hält die Anbieter-Geheimnisse und
verarbeitet Rückleitungen, ohne die Schlüssel an PWA oder Windows-EXE
auszuliefern.

Bankumsätze werden nicht automatisch an OpenAI weitergegeben. Für die
KI-Planung darf nur ein notwendiger, vom Benutzer bestätigter Planungsbetrag
zusammen mit Rezept- und Ernährungsvorgaben verwendet werden.

Eine rein lokale PWA kann manuelle Finanzdaten im Gerätespeicher halten. Der
PWA-Login ist unabhängig davon verbindlich. Für eine optionale Synchronisierung
zwischen Windows, iPhone und Android wäre später zusätzlich ein
authentifizierter, verschlüsselter Datendienst erforderlich.

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

- Finanzdaten werden standardmäßig nur lokal gespeichert.
- Es werden keine Finanzdaten automatisch von Dritten abgerufen.
- Eine spätere Gerätesynchronisierung muss freiwillig und abschaltbar sein.
- Vor einer Synchronisierung werden Verschlüsselung, Datenexport,
  Datensicherung und vollständige Löschung umgesetzt.

## Umsetzungsreihenfolge

1. Fehlerbereinigung und belastbare automatische Tests;
2. automatische Updateprüfung und -installation beim Start mit sichtbarem
   Status und anschließendem Neustart;
3. kompakten Offline-Installer mit Startmenü, optionaler
   Desktopverknüpfung, autonomem Update-, Reparatur- und Deinstallationsweg
   umsetzen;
4. serverseitigen PWA-Login ohne öffentliche Registrierung umsetzen;
5. Wocheneinkauf, Rezepte und Speiseplan sichtbar mit Schätzkosten aufbauen;
6. verbindliche KI-Planung mit OpenAI umsetzen;
7. read-only-Bankabruf über GoCardless mit Dublettenprüfung umsetzen;
8. gemeinsame Windows-, iPhone- und Android-Prüfung;
9. kostenlose Open-Source-Codesignatur prüfen und bei Eignung integrieren;
10. erst danach eine neue Version veröffentlichen.

Die vollständige Planung steht in [`ROADMAP.md`](ROADMAP.md).
