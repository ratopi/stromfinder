# Lokales Testen mit Docker

Baut die komplette App im Container (Elm + pandoc), identisch zum GitHub-Actions-Build.
Keine lokale Elm- oder pandoc-Installation nötig.

Bauen und starten:

    cd docker
    docker compose up --build

Öffnen: http://localhost:8080

Stoppen:

    docker compose down

Neubauen nach Änderungen:

    docker compose up --build
