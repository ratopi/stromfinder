port module Main exposing (main)

import About
import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Json.Decode as D
import Json.Encode as E



-- MAIN


main : Program E.Value Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }



-- MODEL


type alias Model =
    { status : Status
    , stationCount : Int
    , lastModified : String
    , selectedStation : Maybe Station
    , aboutVisible : Bool
    , versionHash : String
    }


type Status
    = Loading
    | Loaded
    | Error String


type alias Station =
    { id : String
    , operator : String
    , displayName : String
    , status : String
    , deviceType : String
    , addr : Address
    , geo : Geo
    , locationName : String
    , parkingInfo : String
    , charging : Charging
    , payment : String
    , openingHours : String
    , openingWeekdays : String
    , openingDaytime : String
    }


type alias Address =
    { strasse : String
    , hausnummer : String
    , plz : String
    , ort : String
    , bundesland : String
    , kreis : String
    }


type alias Geo =
    { lat : Float
    , lon : Float
    }


type alias Charging =
    { inbetriebnahme : String
    , nennleistung : String
    , points : List ChargingPoint
    }


type alias ChargingPoint =
    { plugs : List String
    , power : List String
    , evseId : List String
    , pkey : String
    }


init : E.Value -> ( Model, Cmd Msg )
init flags =
    let
        versionHash =
            case D.decodeValue (D.field "hash" D.string) flags of
                Ok h ->
                    h

                Err _ ->
                    ""
    in
    ( { status = Loading
      , stationCount = 0
      , lastModified = ""
      , selectedStation = Nothing
      , aboutVisible = False
      , versionHash = versionHash
      }
    , initMap ()
    )



-- PORTS (Elm → JS)


port initMap : () -> Cmd msg


port locateMe : () -> Cmd msg




-- PORTS (JS → Elm)


port stationsLoaded : (E.Value -> msg) -> Sub msg


port stationClicked : (E.Value -> msg) -> Sub msg



port dataError : (String -> msg) -> Sub msg



-- UPDATE


type Msg
    = StationsLoaded E.Value
    | StationClicked E.Value
    | CloseInfoPanel
    | ToggleAbout
    | CloseAbout
    | NoOp
    | LocateMe
    | DataError String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        StationsLoaded value ->
            case D.decodeValue stationsMetaDecoder value of
                Ok meta ->
                    ( { model
                        | status = Loaded
                        , stationCount = meta.count
                        , lastModified = meta.lastModified
                      }
                    , Cmd.none
                    )

                Err _ ->
                    ( { model | status = Error "Datenformat nicht erkannt" }
                    , Cmd.none
                    )

        StationClicked value ->
            case D.decodeValue stationDecoder value of
                Ok station ->
                    ( { model | selectedStation = Just station }
                    , Cmd.none
                    )

                Err _ ->
                    ( model, Cmd.none )

        CloseInfoPanel ->
            ( { model | selectedStation = Nothing }
            , Cmd.none
            )

        ToggleAbout ->
            ( { model | aboutVisible = True }, Cmd.none )

        CloseAbout ->
            ( { model | aboutVisible = False }, Cmd.none )

        NoOp ->
            ( model, Cmd.none )

        LocateMe ->
            ( model, locateMe () )

        DataError errMsg ->
            ( { model | status = Error errMsg }, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ stationsLoaded StationsLoaded
        , stationClicked StationClicked
        , dataError DataError
        ]



-- JSON DECODERS


type alias StationsMeta =
    { count : Int
    , lastModified : String
    }


stationsMetaDecoder : D.Decoder StationsMeta
stationsMetaDecoder =
    D.map2 StationsMeta
        (D.field "count" D.int)
        (D.field "lastModified" D.string)


stationDecoder : D.Decoder Station
stationDecoder =
    D.succeed Station
        |> dp "id" D.string ""
        |> dp "operator" D.string ""
        |> dp "display_name" D.string ""
        |> dp "status" D.string ""
        |> dp "device_type" D.string ""
        |> dpObj "addr" addressDecoder emptyAddress
        |> dpObj "geo" geoDecoder { lat = 0, lon = 0 }
        |> dp "location_name" D.string ""
        |> dp "parking_info" D.string ""
        |> dpObj "charging" chargingDecoder emptyCharging
        |> dp "payment" D.string ""
        |> dp "opening_hours" D.string ""
        |> dp "opening_weekdays" D.string ""
        |> dp "opening_daytime" D.string ""


dp : String -> D.Decoder a -> a -> D.Decoder (a -> b) -> D.Decoder b
dp field decoder default_ =
    D.map2 (|>)
        (D.oneOf [ D.field field decoder, D.succeed default_ ])


dpObj : String -> D.Decoder a -> a -> D.Decoder (a -> b) -> D.Decoder b
dpObj field decoder default_ =
    D.map2 (|>)
        (D.oneOf [ D.field field decoder, D.succeed default_ ])


addressDecoder : D.Decoder Address
addressDecoder =
    D.map6 Address
        (optStr "Straße")
        (optStr "Hausnummer")
        (optStr "Postleitzahl")
        (optStr "Ort")
        (optStr "Bundesland")
        (optStr "Kreis/kreisfreie Stadt")


emptyAddress : Address
emptyAddress =
    Address "" "" "" "" "" ""


geoDecoder : D.Decoder Geo
geoDecoder =
    D.map2 Geo
        (D.field "lat" D.float)
        (D.field "lon" D.float)


chargingDecoder : D.Decoder Charging
chargingDecoder =
    D.map3 Charging
        (optStr "Inbetriebnahmedatum")
        (optStr "Nennleistung Ladeeinrichtung [kW]")
        (D.oneOf
            [ D.field "points" (D.list chargingPointDecoder)
            , D.succeed []
            ]
        )


emptyCharging : Charging
emptyCharging =
    Charging "" "" []


chargingPointDecoder : D.Decoder ChargingPoint
chargingPointDecoder =
    D.map4 ChargingPoint
        (D.oneOf [ D.field "plugs" (D.list D.string), D.succeed [] ])
        (D.oneOf [ D.field "power" (D.list D.string), D.succeed [] ])
        (D.oneOf [ D.field "evse_id" (D.list D.string), D.succeed [] ])
        (optStr "pkey")


optStr : String -> D.Decoder String
optStr field =
    D.oneOf [ D.field field D.string, D.succeed "" ]



-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ viewHeader model
        , viewInfoPanel model.selectedStation
        , viewAboutOverlay model
        ]


viewHeader : Model -> Html Msg
viewHeader model =
    div [ id "header" ]
        [ h1 []
            [ text "⚡ Stromfinder"
            , viewVersion model.versionHash
            ]
        , span
            [ id "status"
            , classList [ ( "loading", model.status == Loading ) ]
            ]
            [ text (statusText model) ]
        , div [ id "header-links" ]
            [ a
                [ id "bugs-link"
                , href (bugsUrl model.versionHash)
                , target "_blank"
                , rel "noopener"
                , title "Bugs melden"
                ]
                [ text "🐛 Bugs" ]
            , a
                [ href "https://github.com/ratopi/stromfinder"
                , target "_blank"
                , rel "noopener"
                , title "Quellcode auf GitHub"
                ]
                [ githubIcon, text " Source" ]
            , button
                [ id "about-btn"
                , onClick ToggleAbout
                , title "Über Stromfinder"
                ]
                [ span [ style "font-size" "0.75rem" ] [ text "ℹ️" ], text " Info" ]
            ]
        ]


viewVersion : String -> Html Msg
viewVersion hash =
    if hash == "" then
        text ""

    else
        let
            short =
                String.left 7 hash
        in
        a
            [ id "version"
            , href ("https://github.com/ratopi/stromfinder/commit/" ++ hash)
            , target "_blank"
            , rel "noopener"
            , title ("Commit " ++ hash)
            ]
            [ text (" " ++ short) ]


statusText : Model -> String
statusText model =
    case model.status of
        Loading ->
            "Lade Daten…"

        Error msg ->
            "Fehler: " ++ msg

        Loaded ->
            let
                count =
                    String.fromInt model.stationCount

                date =
                    if model.lastModified /= "" then
                        " · Stand: " ++ model.lastModified

                    else
                        ""
            in
            count ++ " Ladestationen" ++ date


bugsUrl : String -> String
bugsUrl hash =
    if hash == "" then
        "https://github.com/ratopi/stromfinder/issues"

    else
        "https://github.com/ratopi/stromfinder/issues/new?body=Version%3A%20" ++ hash ++ "%0A%0A**Beschreibung%3A**%0A"


githubIcon : Html msg
githubIcon =
    Html.node "svg"
        [ attribute "height" "16"
        , attribute "width" "16"
        , attribute "viewBox" "0 0 16 16"
        , attribute "fill" "currentColor"
        , style "vertical-align" "middle"
        ]
        [ Html.node "path"
            [ attribute "d" "M8 0C3.58 0 0 3.58 0 8c0 3.54 2.29 6.53 5.47 7.59.4.07.55-.17.55-.38 0-.19-.01-.82-.01-1.49-2.01.37-2.53-.49-2.69-.94-.09-.23-.48-.94-.82-1.13-.28-.15-.68-.52-.01-.53.63-.01 1.08.58 1.23.82.72 1.21 1.87.87 2.33.66.07-.52.28-.87.51-1.07-1.78-.2-3.64-.89-3.64-3.95 0-.87.31-1.59.82-2.15-.08-.2-.36-1.02.08-2.12 0 0 .67-.21 2.2.82.64-.18 1.32-.27 2-.27s1.36.09 2 .27c1.53-1.04 2.2-.82 2.2-.82.44 1.1.16 1.92.08 2.12.51.56.82 1.27.82 2.15 0 3.07-1.87 3.75-3.65 3.95.29.25.54.73.54 1.48 0 1.07-.01 1.93-.01 2.2 0 .21.15.46.55.38A8.01 8.01 0 0 0 16 8c0-4.42-3.58-8-8-8z"
            ]
            []
        ]


viewInfoPanel : Maybe Station -> Html Msg
viewInfoPanel maybeStation =
    case maybeStation of
        Nothing ->
            div [ id "info-panel", class "hidden" ] []

        Just station ->
            div [ id "info-panel" ]
                [ button [ id "info-close", onClick CloseInfoPanel, title "Schließen" ] [ text "✕" ]
                , div [ id "info-content" ] (viewStationDetail station)
                ]


viewStationDetail : Station -> List (Html Msg)
viewStationDetail s =
    let
        name =
            if s.displayName /= "" then
                s.displayName

            else if s.operator /= "" then
                s.operator

            else
                "Ladestation"

        statusBadge =
            if s.status /= "" then
                let
                    cls =
                        if s.status == "In Betrieb" then
                            "badge badge-status-ok"

                        else
                            "badge badge-status-other"
                in
                [ span [ class cls ] [ text s.status ], text " " ]

            else
                []

        typeBadge =
            if s.deviceType /= "" then
                let
                    cls =
                        if String.contains "schnell" (String.toLower s.deviceType) then
                            "badge badge-schnell"

                        else
                            "badge badge-normal"
                in
                [ span [ class cls ] [ text s.deviceType ] ]

            else
                []

        addressRows =
            List.filterMap identity
                [ tableRow "Straße" s.addr.strasse
                , tableRow "Hausnummer" s.addr.hausnummer
                , tableRow "Postleitzahl" s.addr.plz
                , tableRow "Ort" s.addr.ort
                , tableRow "Bundesland" s.addr.bundesland
                , tableRow "Kreis" s.addr.kreis
                ]

        addressSection =
            if List.isEmpty addressRows then
                []

            else
                [ div [ class "section-title" ] [ text "Adresse" ]
                , table [] addressRows
                ]

        locationSection =
            List.filterMap identity
                [ if s.locationName /= "" then
                    Just (div [ class "section-title" ] [ text "Standort" ])

                  else
                    Nothing
                , if s.locationName /= "" then
                    Just (p [ style "font-size" "0.85rem" ] [ text s.locationName ])

                  else
                    Nothing
                , if s.parkingInfo /= "" then
                    Just (p [ style "font-size" "0.85rem", style "color" "#666" ] [ text ("Parkraum: " ++ s.parkingInfo) ])

                  else
                    Nothing
                ]

        chargingRows =
            List.filterMap identity
                [ tableRow "Nennleistung" (if s.charging.nennleistung /= "" then s.charging.nennleistung ++ " kW" else "")
                , tableRow "In Betrieb seit" s.charging.inbetriebnahme
                ]

        chargingSection =
            if List.isEmpty chargingRows && List.isEmpty s.charging.points then
                []

            else
                [ div [ class "section-title" ] [ text "Laden" ]
                , table [] chargingRows
                ]
                    ++ viewChargingPoints s.charging.points

        paymentSection =
            if s.payment /= "" then
                [ div [ class "section-title" ] [ text "Bezahlung" ]
                , p [ style "font-size" "0.85rem" ] [ text s.payment ]
                ]

            else
                []

        openingSection =
            let
                rows =
                    List.filterMap identity
                        [ tableRow "Verfügbar" s.openingHours
                        , tableRow "Wochentage" s.openingWeekdays
                        , tableRow "Uhrzeiten" s.openingDaytime
                        ]
            in
            if List.isEmpty rows then
                []

            else
                [ div [ class "section-title" ] [ text "Öffnungszeiten" ]
                , table [] rows
                ]

        idSection =
            if s.id /= "" then
                [ div [ style "margin-top" "1rem", style "font-size" "0.75rem", style "color" "#999" ]
                    [ text ("ID: " ++ s.id) ]
                ]

            else
                []
    in
    [ h2 [] [ text name ] ]
        ++ statusBadge
        ++ typeBadge
        ++ addressSection
        ++ locationSection
        ++ chargingSection
        ++ paymentSection
        ++ openingSection
        ++ idSection


viewChargingPoints : List ChargingPoint -> List (Html Msg)
viewChargingPoints points =
    if List.isEmpty points then
        []

    else
        [ div [ class "section-title" ]
            [ text ("Ladepunkte (" ++ String.fromInt (List.length points) ++ ")") ]
        ]
            ++ List.indexedMap viewChargingPoint points


viewChargingPoint : Int -> ChargingPoint -> Html Msg
viewChargingPoint idx point =
    let
        rows =
            [ Just (tr [] [ th [] [ text "Ladepunkt" ], td [] [ b [] [ text (String.fromInt (idx + 1)) ] ] ]) ]
                ++ [ if List.isEmpty point.plugs then
                        Nothing

                     else
                        Just (tr [] [ th [] [ text "Stecker" ], td [] [ text (String.join ", " point.plugs) ] ])
                   ]
                ++ [ if List.isEmpty point.power then
                        Nothing

                     else
                        Just (tr [] [ th [] [ text "Leistung" ], td [] [ text (String.join ", " point.power ++ " kW") ] ])
                   ]
                ++ [ if List.isEmpty point.evseId then
                        Nothing

                     else
                        Just (tr [] [ th [] [ text "EVSE-ID" ], td [] [ text (String.join ", " point.evseId) ] ])
                   ]
    in
    table [] (List.filterMap identity rows)


tableRow : String -> String -> Maybe (Html Msg)
tableRow label value =
    if value /= "" then
        Just (tr [] [ th [] [ text label ], td [] [ text value ] ])

    else
        Nothing


viewAboutOverlay : Model -> Html Msg
viewAboutOverlay model =
    if model.aboutVisible then
        div [ id "about-overlay", onClick CloseAbout ]
            [ div [ id "about-modal", stopPropagationClick ]
                [ button [ id "about-close", onClick CloseAbout, title "Schließen" ] [ text "✕" ]
                , div [ id "about-content" ]
                    [ About.view ]
                ]
            ]

    else
        div [ id "about-overlay", class "hidden" ] []


stopPropagationClick : Attribute Msg
stopPropagationClick =
    Html.Events.stopPropagationOn "click" (D.succeed ( NoOp, True ))


