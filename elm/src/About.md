# ⚡ Stromfinder

Interaktive Karte aller Ladesäulen in Deutschland.

Hier findest du über 70.000 öffentlich zugängliche Ladestationen auf einen Blick – mit allen Details zu Steckertypen, Leistung, Öffnungszeiten und Betreibern.

## Features

- 🗺️ **Karte** – Alle Ladestationen auf einer OpenStreetMap-Karte mit Marker-Clustering
- 🔍 **Detailansicht** – Klicke auf eine Station für Adresse, Ladepunkte, Steckertypen und Leistung
- ⚡ **Schnell- & Normallader** – Farblich unterschieden: 🟠 Schnelllader / 🟢 Normallader
- 📱 **Mobil & Desktop** – Responsive Design, als App installierbar (PWA)
- 🔄 **Wöchentlich aktualisiert** – Die Daten werden automatisch erneuert

## Datenquelle

Die Daten stammen aus dem offiziellen [Ladesäulenregister der Bundesnetzagentur](https://www.bundesnetzagentur.de/DE/Fachthemen/ElektrizitaetundGas/E-Mobilitaet/start.html).

Das Schwesterprojekt [ratopi/ladesaeule](https://github.com/ratopi/ladesaeule) lädt die CSV-Datei der Bundesnetzagentur herunter, wandelt sie nach JSON und veröffentlicht das Ergebnis als komprimierte Datei auf GitHub Pages. Stromfinder lädt diese Datei und zeigt die Stationen auf der Karte.

## Open Source

Stromfinder ist Open Source unter der **Apache License 2.0**.

Quellcode: [github.com/ratopi/stromfinder](https://github.com/ratopi/stromfinder)

Fehler gefunden? → [Issue melden](https://github.com/ratopi/stromfinder/issues)

