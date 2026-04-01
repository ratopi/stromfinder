// ---------------------------------------------------------------------------
// Stromfinder – Elm Ports / JS interop
// Bridges Elm with Leaflet, pako (gzip), Geolocation, and About-HTML loading
// ---------------------------------------------------------------------------

(async function () {
  "use strict";

  var DATA_URL = "https://ratopi.github.io/ladesaeule/ladesaeulen.json.gz";

  // --- Load version info ------------------------------------------------

  var versionFlags = {};
  try {
    var vres = await fetch("version.json");
    if (vres.ok) versionFlags = await vres.json();
  } catch (e) { /* ignore */ }

  // --- Init Elm app -----------------------------------------------------

  var app = Elm.Main.init({
    node: document.getElementById("elm-app"),
    flags: versionFlags,
  });

  // --- Map --------------------------------------------------------------

  var map = null;
  var locationMarker = null;
  var locationCircle = null;

  app.ports.initMap.subscribe(function () {
    requestAnimationFrame(function () {
      map = L.map("map", {
        center: [51.16, 10.45],
        zoom: 7,
        zoomControl: true,
      });

      L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
        attribution:
          '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> | Daten: <a href="https://www.bundesnetzagentur.de">Bundesnetzagentur</a>',
        maxZoom: 19,
      }).addTo(map);

      // Locate button
      var LocateControl = L.Control.extend({
        options: { position: "topleft" },
        onAdd: function () {
          var btn = L.DomUtil.create("div", "leaflet-bar leaflet-control");
          btn.innerHTML = '<a href="#" title="Mein Standort" role="button">&#8853;</a>';
          btn.querySelector("a").style.cssText = "font-size:20px;line-height:30px;text-align:center;display:block;width:30px;height:30px;text-decoration:none;color:#333;";
          L.DomEvent.disableClickPropagation(btn);
          L.DomEvent.on(btn, "click", function (e) {
            L.DomEvent.preventDefault(e);
            locateUser();
          });
          return btn;
        },
      });
      map.addControl(new LocateControl());

      loadData();
    });
  });

  // --- Locate -----------------------------------------------------------

  app.ports.locateMe.subscribe(function () {
    locateUser();
  });

  function locateUser() {
    if (!navigator.geolocation || !map) return;
    navigator.geolocation.getCurrentPosition(
      function (pos) {
        var lat = pos.coords.latitude;
        var lon = pos.coords.longitude;
        var acc = pos.coords.accuracy;
        map.setView([lat, lon], 14);
        if (locationMarker) map.removeLayer(locationMarker);
        if (locationCircle) map.removeLayer(locationCircle);
        locationCircle = L.circle([lat, lon], {
          radius: acc, color: "#4285f4", fillColor: "#4285f4", fillOpacity: 0.15, weight: 1
        }).addTo(map);
        locationMarker = L.circleMarker([lat, lon], {
          radius: 8, color: "#fff", fillColor: "#4285f4", fillOpacity: 1, weight: 3
        }).addTo(map).bindTooltip("Mein Standort", { direction: "top" });
      },
      function (err) {
        alert("Standort konnte nicht ermittelt werden: " + err.message);
      },
      { enableHighAccuracy: true, timeout: 10000 }
    );
  }


  // --- Load station data ------------------------------------------------

  async function loadData() {
    try {
      var response = await fetch(DATA_URL);
      if (!response.ok) throw new Error("HTTP " + response.status);
      var buffer = await response.arrayBuffer();
      var json = pako.ungzip(new Uint8Array(buffer), { to: "string" });
      var data = JSON.parse(json);
      if (!data.data || !Array.isArray(data.data)) {
        throw new Error("Unerwartetes Datenformat");
      }
      addMarkers(data.data);
      var lastMod = (data.meta && data.meta.source_last_modified) || "";
      if (lastMod) {
        try {
          var d = new Date(lastMod);
          lastMod = d.toLocaleDateString("de-DE", { day: "2-digit", month: "2-digit", year: "numeric" });
        } catch (e) { /* keep raw string */ }
      }
      app.ports.stationsLoaded.send({ count: data.data.length, lastModified: lastMod });
    } catch (err) {
      console.error("Fehler beim Laden:", err);
      app.ports.dataError.send(err.message || "Unbekannter Fehler");
    }
  }

  // --- Markers ----------------------------------------------------------

  function makeIcon(station) {
    var isSchnell = station.device_type === "rapid";
    var colour = isSchnell ? "#ff8f00" : "#00c853";
    return L.divIcon({
      className: "",
      iconSize: [18, 18],
      iconAnchor: [9, 9],
      html: '<div style="width:18px;height:18px;border-radius:50%;background:' + colour + ';border:3px solid #fff;box-shadow:0 0 6px rgba(0,0,0,0.5);"></div>',
    });
  }

  function addMarkers(stations) {
    var cluster = L.markerClusterGroup({
      chunkedLoading: true, chunkInterval: 100, chunkDelay: 10,
      maxClusterRadius: 60, disableClusteringAtZoom: 16,
      spiderfyOnMaxZoom: true, showCoverageOnHover: false,
    });
    var markers = [];
    for (var i = 0; i < stations.length; i++) {
      var s = stations[i];
      if (!s.geo || s.geo.lat == null || s.geo.lon == null) continue;
      var lat = typeof s.geo.lat === "number" ? s.geo.lat : parseFloat(s.geo.lat);
      var lon = typeof s.geo.lon === "number" ? s.geo.lon : parseFloat(s.geo.lon);
      if (isNaN(lat) || isNaN(lon)) continue;
      var marker = L.marker([lat, lon], { icon: makeIcon(s) });
      var tip = s.display_name || s.operator || "Ladestation";
      marker.bindTooltip(tip, { direction: "top", offset: [0, -6] });
      (function(station) {
        marker.on("click", function () { app.ports.stationClicked.send(station); });
      })(s);
      markers.push(marker);
    }
    cluster.addLayers(markers);
    map.addLayer(cluster);
  }
})();
