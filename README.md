# ⚡ Stromfinder

Interaktive Karte aller Ladesäulen in Deutschland.

Die Daten stammen aus dem Projekt [ratopi/ladesaeule](https://github.com/ratopi/ladesaeule),
das die CSV-Datei des [Ladesäulenregisters der Bundesnetzagentur](https://www.bundesnetzagentur.de/DE/Fachthemen/ElektrizitaetundGas/E-Mobilitaet/start.html)
herunterlädt, nach JSON wandelt und als komprimierte `ladesaeulen.json.gz` auf GitHub Pages
veröffentlicht. Stromfinder visualisiert diese JSON-Daten auf einer OpenStreetMap-Karte.

## Live

**https://ratopi.github.io/stromfinder/**

Die Daten werden wöchentlich automatisch durch das ladesaeule-Projekt aktualisiert.

## Features

- 🗺️ OpenStreetMap-Karte mit Marker-Clustering für ~70.000 Ladestationen
- 🔍 Detailansicht mit Adresse, Ladepunkten, Steckertypen, Leistung, Öffnungszeiten
- ⚡ Schnelllader und Normallader farblich unterschieden (orange / grün)
- 📱 Responsive – funktioniert auf Desktop und Mobil
- 📲 Progressive Web App – installierbar auf Handy und Desktop, offline-fähig nach erstem Laden

## Datenquelle

Die Rohdaten kommen ursprünglich von der Bundesnetzagentur als CSV.
Das Schwesterprojekt [ratopi/ladesaeule](https://github.com/ratopi/ladesaeule) wandelt
diese CSV nach JSON und veröffentlicht das Ergebnis als
[`ladesaeulen.json.gz`](https://ratopi.github.io/ladesaeule/ladesaeulen.json.gz)
auf GitHub Pages.

Stromfinder lädt diese gzip-komprimierte JSON-Datei und dekomprimiert sie im Browser
mit [pako](https://github.com/nodeca/pako).

## Technik

Die UI ist in [Elm](https://elm-lang.org/) geschrieben. Die Kartenintegration (Leaflet)
und das Laden/Entpacken der Daten (pako) laufen über Elm Ports in JavaScript.

| Komponente | Bibliothek |
|------------|-----------|
| UI / State | [Elm](https://elm-lang.org/) 0.19 |
| Karte | [Leaflet](https://leafletjs.com/) 1.9 |
| Tiles | [OpenStreetMap](https://www.openstreetmap.org/) |
| Clustering | [Leaflet.markercluster](https://github.com/Leaflet/Leaflet.markercluster) |
| Dekompression | [pako](https://github.com/nodeca/pako) (gzip im Browser) |

## Struktur

```
api/
  ladesaeule/
    openapi.yaml    – OpenAPI-Spezifikation der ladesaeule-Datenquelle
elm/
  elm.json          – Elm-Abhängigkeiten
  src/Main.elm      – Elm-Applikation (UI, State, JSON-Decoder)
public/             – Statische Dateien (= Deploy-Verzeichnis)
  index.html        – Einstiegsseite
  app.js            – Kompiliertes Elm (Build-Artefakt, nicht eingecheckt)
  ports.js          – JS-Brücke: Leaflet, pako, Geolocation ↔ Elm Ports
  style.css         – Styling
  sw.js             – Service Worker (Offline-Cache)
  manifest.json     – PWA-Manifest
  icons/            – App-Icons (192×192, 512×512)
docker/
  Dockerfile        – Multi-Stage Build: Elm + pandoc → nginx
  docker-compose.yml
  nginx.conf
build.sh            – Kompiliert Elm → public/app.js (optimiert)
ABOUT.md            – Info-Text für das About-Modal in der App
```

## Bauen

    ./build.sh

Kompiliert `elm/src/Main.elm` optimiert nach `public/app.js`.

Voraussetzung: [Elm 0.19.1](https://elm-lang.org/) installiert.

## Lokal testen

### Mit Docker (empfohlen)

Baut die komplette App im Container (Elm + pandoc), identisch zum GitHub-Actions-Build.
Keine lokale Installation von Elm oder pandoc nötig.

    cd docker
    docker compose up --build

Dann http://localhost:8080 öffnen.

Neubauen nach Änderungen:

    docker compose up --build

### Ohne Docker

    ./build.sh
    cd public
    python3 -m http.server 8000

Dann http://localhost:8000 öffnen.

Voraussetzung: Elm 0.19.1 lokal installiert. `about.html` und `version.json` fehlen
dann (werden nur von Docker bzw. der GitHub Action erzeugt).

> **Hinweis:** Die JSON-Daten (~80 MB unkomprimiert, ~5–10 MB gzip) werden von
> `ratopi.github.io/ladesaeule/` geladen. Beim ersten Aufruf kann das einige Sekunden dauern.

## GitHub Pages

Bei jedem Push auf `main` / `master` wird eine GitHub Action ausgeführt, die:

1. Elm kompiliert (`elm make --optimize`)
2. Die `ABOUT.md` mit [pandoc](https://pandoc.org/) nach `about.html` rendert
3. Eine `version.json` mit Git-Hash und Datum erzeugt
4. Das `public/`-Verzeichnis auf den `gh-pages`-Branch deployed

Im Repository unter *Settings → Pages → Source* den Branch `gh-pages` und `/` (root) auswählen.

## Lizenz

Apache License 2.0 – siehe [LICENSE](LICENSE)
