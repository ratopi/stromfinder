module About exposing (view)

import Html exposing (..)
import Html.Attributes exposing (..)


view : Html msg
view =
    div []
        [ h1 [] [ text "⚡ Stromfinder" ]
        , p [] [ text "Interaktive Karte aller Ladesäulen in Deutschland." ]
        , p []
            [ text "Hier findest du über 70.000 öffentlich zugängliche Ladestationen auf einen Blick – mit allen Details zu Steckertypen, Leistung, Öffnungszeiten und Betreibern." ]
        , h2 [] [ text "Features" ]
        , ul []
            [ li [] [ text "🗺️ ", strong [] [ text "Karte" ], text " – Alle Ladestationen auf einer OpenStreetMap-Karte mit Marker-Clustering" ]
            , li [] [ text "🔍 ", strong [] [ text "Detailansicht" ], text " – Klicke auf eine Station für Adresse, Ladepunkte, Steckertypen und Leistung" ]
            , li [] [ text "⚡ ", strong [] [ text "Schnell- & Normallader" ], text " – Farblich unterschieden: 🟠 Schnelllader / 🟢 Normallader" ]
            , li [] [ text "📱 ", strong [] [ text "Mobil & Desktop" ], text " – Responsive Design, als App installierbar (PWA)" ]
            , li [] [ text "🔄 ", strong [] [ text "Wöchentlich aktualisiert" ], text " – Die Daten werden automatisch erneuert" ]
            ]
        , h2 [] [ text "Datenquelle" ]
        , p []
            [ text "Die Daten stammen aus dem offiziellen "
            , a [ href "https://www.bundesnetzagentur.de/DE/Fachthemen/ElektrizitaetundGas/E-Mobilitaet/start.html" ] [ text "Ladesäulenregister der Bundesnetzagentur" ]
            , text "."
            ]
        , p []
            [ text "Das Schwesterprojekt "
            , a [ href "https://github.com/ratopi/ladesaeule" ] [ text "ratopi/ladesaeule" ]
            , text " lädt die CSV-Datei der Bundesnetzagentur herunter, wandelt sie nach JSON und veröffentlicht das Ergebnis als komprimierte Datei auf GitHub Pages. Stromfinder lädt diese Datei und zeigt die Stationen auf der Karte."
            ]
        , h2 [] [ text "Open Source" ]
        , p [] [ text "Stromfinder ist Open Source unter der ", strong [] [ text "Apache License 2.0" ], text "." ]
        , p []
            [ text "Quellcode: "
            , a [ href "https://github.com/ratopi/stromfinder" ] [ text "github.com/ratopi/stromfinder" ]
            ]
        , p []
            [ text "Fehler gefunden? → "
            , a [ href "https://github.com/ratopi/stromfinder/issues" ] [ text "Issue melden" ]
            ]
        ]

