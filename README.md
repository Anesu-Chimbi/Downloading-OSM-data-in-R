# OSM Water Features Explorer

> A toolkit for downloading, processing, and visualizing OpenStreetMap (OSM) hydrological data in R — featuring an interactive Shiny dashboard and spatial analysis pipeline.

[![R](https://img.shields.io/badge/R-%3E%3D4.1-276DC3?logo=r)](https://www.r-project.org/)
[![Shiny](https://img.shields.io/badge/Shiny-live-0097A7)](https://anesuchimbi.shinyapps.io/OSM_shiny_app/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

---

## What's New in v2.0

- **Modern dark UI** — rebuilt with `bslib` v5, Space Grotesk typography, animated stats cards
- **Multi-layer support** — query natural water, waterways (auto-buffered), and reservoirs in one click
- **Analytics tab** — 5 interactive Plotly charts: area histogram, top-10 bar, size-class breakdown, Lorenz curve, feature-type pie
- **Spatial statistics** — Moran's I autocorrelation on log-area, nearest-neighbour distances
- **New exports** — GeoJSON download added alongside HTML map and CSV
- **Accurate area calculation** — reprojects to UTM 36S before computing areas
- **Leaflet upgrades** — fullscreen control, layer switcher, highlighted polygons on hover

---

## Features

| Feature | Description |
|---|---|
| 🔍 **Any location** | Enter any city or region — Harare, Nairobi, Cape Town, etc. |
| 💧 **Multi-type queries** | Natural water, waterways, reservoirs |
| 📊 **Analytics dashboard** | Interactive charts via Plotly |
| 📋 **Data table** | Searchable, sortable DT table with Excel/CSV export |
| 🗺 **Interactive map** | Leaflet with dark/satellite/street basemaps + fullscreen |
| 📦 **GeoJSON export** | Download analysis-ready spatial data |

---

## Repository Structure

```
.
├── OSM_shiny_app/
│   └── app.R                          # Shiny dashboard (v2.0)
├── scripts/
│   └── osm_data_analysis_and_visualization.R  # Standalone analysis script
├── data/
│   ├── zw_water_sf_simple.shp         # Processed shapefile (Harare)
│   └── zw_water_sf_simple.geojson     # GeoJSON equivalent
├── docs/
│   ├── water_map.png                  # Static export
│   └── water_map_interactive.html     # Interactive Leaflet export
└── README.md
```

---

## Installation

```r
install.packages(c(
  "shiny", "bslib", "osmdata", "sf", "rmapshaper",
  "leaflet", "leaflet.extras", "htmlwidgets",
  "dplyr", "ggplot2", "ggspatial", "plotly",
  "DT", "units", "spdep"
))
```

## Running the Shiny App

```r
shiny::runApp("OSM_shiny_app/app.R")
```

Or visit the live deployment: **[anesuchimbi.shinyapps.io/OSM_shiny_app](https://anesuchimbi.shinyapps.io/OSM_shiny_app/)**

---

## Spatial Analysis

The standalone script (`scripts/osm_data_analysis_and_visualization.R`) performs:

1. **OSM data download** — natural water + reservoirs
2. **Geometry simplification** — `rmapshaper::ms_simplify` for fast rendering
3. **Accurate area calculation** — UTM 36S reprojection
4. **Size classification** — Small / Medium / Large / Very Large
5. **Moran's I** — spatial autocorrelation test on log-area
6. **Nearest-neighbour distances** — dispersion analysis
7. **Static map export** — `ggplot2` + `ggspatial`
8. **Interactive map export** — `leaflet` HTML

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

---

## License

MIT © Anesu Chimbi
