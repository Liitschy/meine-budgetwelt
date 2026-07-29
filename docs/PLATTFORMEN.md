# Plattform-Architektur

## Zielplattformen

Die Anwendung soll langfristig auf folgenden Wegen verfügbar sein:

1. als eigenständige Windows-Anwendung;
2. als installierbare Web-App (PWA) für den iPhone-Startbildschirm;
3. als PWA und später optional als Android-App.

Die Geschäftslogik für Budget, Fixkosten, Monate und Preise bleibt von der
Darstellung getrennt. Dadurch kann sie später in einer Web-Oberfläche
wiederverwendet oder kontrolliert übertragen werden.

## Manuelle Finanzdaten

Monatslohn, Startkontostand, Fixkosten und tatsächliche Ausgaben werden
ausschließlich vom Benutzer eingetragen.

Die Anwendung enthält keine Verbindung zu Banken oder anderen Finanzinstituten
und fordert keine Zugangsdaten, PIN oder TAN an.

## GitHub und iPhone

GitHub Pages kann die statischen Dateien einer Web-App über HTTPS
bereitstellen. Mit Web-App-Manifest und Service Worker kann diese Seite auf dem
iPhone zum Home-Bildschirm hinzugefügt werden.

Geheime Schlüssel oder private Finanzdaten dürfen weder im Repository noch im
öffentlich ausgelieferten Browsercode gespeichert werden.

Eine rein lokale PWA kann manuelle Finanzdaten im Gerätespeicher halten. Für
eine optionale Synchronisierung zwischen Windows, iPhone und Android wäre
später ein authentifizierter, verschlüsselter Datendienst erforderlich.

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

1. lokale manuelle Anwendung stabilisieren;
2. Datenformat und Migrationen festigen;
3. responsive PWA mit lokaler Datenspeicherung erstellen;
4. iPhone- und Android-Installation testen;
5. optional eine sichere, freiwillige Gerätesynchronisierung ergänzen.
