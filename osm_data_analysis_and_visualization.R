# ============================================================
# OSM Water Features — Data Download, Analysis & Visualization
# Author: Anesu Chimbi
# Updated: 2025 — Enhanced analysis, spatial statistics added
# ============================================================

# ── 0. Dependencies ─────────────────────────────────────────
required_pkgs <- c(
  "osmdata", "sf", "rmapshaper", "leaflet", "mapview",
  "htmlwidgets", "ggplot2", "ggspatial", "dplyr",
  "units", "spdep"
)
new_pkgs <- setdiff(required_pkgs, rownames(installed.packages()))
if (length(new_pkgs)) install.packages(new_pkgs)
invisible(lapply(required_pkgs, library, character.only = TRUE))


# ── 1. Configuration ─────────────────────────────────────────
LOCATION   <- "Harare, Zimbabwe"
OUTPUT_DIR <- here::here("data")    # change as needed
DOCS_DIR   <- here::here("docs")
dir.create(OUTPUT_DIR, showWarnings = FALSE, recursive = TRUE)
dir.create(DOCS_DIR,   showWarnings = FALSE, recursive = TRUE)


# ── 2. Download OSM Data ──────────────────────────────────────
message("Fetching bounding box for: ", LOCATION)
bbox <- getbb(LOCATION)

message("Querying OpenStreetMap for water features...")
zw_water_opq <- opq(bbox = bbox) |>
  add_osm_feature(key = "natural", value = "water")

zw_water_osm_data <- osmdata_sf(zw_water_opq)

# Also fetch reservoirs
zw_reservoir_opq <- opq(bbox = bbox) |>
  add_osm_feature(key = "landuse", value = "reservoir")
zw_reservoir_data <- osmdata_sf(zw_reservoir_opq)


# ── 3. Process & Clean Data ───────────────────────────────────
water_polys <- zw_water_osm_data$osm_polygons
res_polys   <- zw_reservoir_data$osm_polygons

# Standardise columns and tag source
process_layer <- function(sf_obj, type_label) {
  if (is.null(sf_obj) || nrow(sf_obj) == 0) return(NULL)
  sf_obj |>
    select(osm_id, name, geometry) |>
    mutate(feature_type = type_label,
           name = if_else(is.na(name), "Unnamed", name))
}

water_clean <- bind_rows(
  process_layer(water_polys, "Natural Water"),
  process_layer(res_polys,   "Reservoir")
)

message("Raw features: ", nrow(water_clean))

# Simplify geometries
water_simple <- ms_simplify(water_clean, keep = 0.05)

# Reproject to UTM 36S for accurate area calculation
water_utm <- st_transform(water_simple, crs = 32736)
water_utm$area_m2  <- as.numeric(st_area(water_utm))
water_utm$area_ha  <- round(water_utm$area_m2 / 1e4, 4)
water_utm$area_km2 <- round(water_utm$area_m2 / 1e6, 6)

# Size classification
water_utm$size_class <- cut(
  water_utm$area_m2,
  breaks = c(0, 1000, 10000, 100000, Inf),
  labels = c("Small (<1 ha)", "Medium (1–10 ha)", "Large (10–100 ha)", "Very Large (>100 ha)"),
  right  = FALSE
)

# Back to WGS-84 for mapping
water_wgs <- st_transform(water_utm, crs = 4326)

message("Processed features: ", nrow(water_wgs))


# ── 4. Basic Summary Statistics ───────────────────────────────
cat("\n=== Water Feature Summary ===\n")
cat("Total features     :", nrow(water_wgs), "\n")
cat("Total area (ha)    :", round(sum(water_wgs$area_ha), 2), "\n")
cat("Mean area (ha)     :", round(mean(water_wgs$area_ha), 4), "\n")
cat("Median area (ha)   :", round(median(water_wgs$area_ha), 4), "\n")
cat("Largest body (ha)  :", round(max(water_wgs$area_ha), 2), "\n")

cat("\n--- By Feature Type ---\n")
water_wgs |>
  st_drop_geometry() |>
  group_by(feature_type) |>
  summarise(n = n(),
            total_area_ha = round(sum(area_ha), 2),
            mean_area_ha  = round(mean(area_ha), 4)) |>
  print()

cat("\n--- Size Class Distribution ---\n")
table(water_wgs$size_class) |> print()


# ── 5. Spatial Statistics ─────────────────────────────────────
# 5a. Nearest-neighbour distance (average distance between water body centroids)
if (nrow(water_utm) >= 3) {
  centroids <- st_centroid(water_utm)
  coords    <- st_coordinates(centroids)
  nn_dists  <- nndist(coords)        # requires spatstat.geom via spdep
  cat("\n=== Spatial Distribution ===\n")
  cat("Mean nearest-neighbour dist (m):", round(mean(nn_dists), 1), "\n")
  cat("Median NN dist (m)             :", round(median(nn_dists), 1), "\n")
}

# 5b. Spatial weights & Moran's I on log-area (if enough features)
if (nrow(water_utm) >= 8) {
  cat("\n=== Spatial Autocorrelation (Moran's I on log-area) ===\n")
  tryCatch({
    nb  <- knn2nb(knearneigh(st_coordinates(st_centroid(water_utm)), k = 4))
    lw  <- nb2listw(nb, style = "W")
    mi  <- moran.test(log1p(water_utm$area_m2), lw)
    cat("Moran's I  :", round(mi$estimate["Moran I statistic"], 4), "\n")
    cat("p-value    :", signif(mi$p.value, 3), "\n")
    cat("Interpretation:", ifelse(mi$p.value < 0.05,
        "Significant spatial clustering of water body sizes.",
        "No significant spatial autocorrelation detected."), "\n")
  }, error = function(e) {
    cat("(Moran's I skipped:", e$message, ")\n")
  })
}


# ── 6. Static Map (ggplot2 + ggspatial) ───────────────────────
message("\nRendering static map...")

# Colour palette by type
type_colours <- c("Natural Water" = "#38bdf8", "Reservoir" = "#22d3ee")

static_map <- ggplot(water_wgs) +
  annotation_map_tile(type = "cartolight", zoom = 12, quiet = TRUE) +
  geom_sf(aes(fill = feature_type), colour = "#1a6fa0", linewidth = 0.3, alpha = 0.75) +
  scale_fill_manual(values = type_colours, name = "Feature Type") +
  annotation_scale(location = "bl", width_hint = 0.2) +
  annotation_north_arrow(location = "tr", style = north_arrow_fancy_orienteering()) +
  labs(
    title    = paste("Water Features —", LOCATION),
    subtitle = paste0(nrow(water_wgs), " features | ",
                      round(sum(water_wgs$area_ha), 1), " ha total"),
    caption  = "Data: OpenStreetMap contributors | Analysis: Anesu Chimbi 2025"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    plot.title    = element_text(face = "bold"),
    legend.position = "bottom"
  )

ggsave(file.path(DOCS_DIR, "water_map.png"),
       static_map, width = 10, height = 8, dpi = 180)
message("Saved: water_map.png")


# ── 7. Interactive Leaflet Map ─────────────────────────────────
message("Building interactive Leaflet map...")

pal <- colorFactor(
  palette = c("#38bdf8", "#22d3ee"),
  domain  = water_wgs$feature_type
)

water_map_interactive <- leaflet(water_wgs) |>
  addProviderTiles("CartoDB.DarkMatter", group = "Dark") |>
  addProviderTiles("Esri.WorldImagery",  group = "Satellite") |>
  addProviderTiles("OpenStreetMap",      group = "Street") |>
  addPolygons(
    color       = ~pal(feature_type),
    fillColor   = ~pal(feature_type),
    fillOpacity = 0.55,
    weight      = 1,
    popup       = ~paste0(
      "<b>", name, "</b><br>",
      "Type: ", feature_type, "<br>",
      "Area: ", round(area_ha, 3), " ha"
    ),
    label       = ~name,
    group       = "Water Features",
    highlightOptions = highlightOptions(
      color = "#ffffff", weight = 3,
      fillOpacity = 0.85, bringToFront = TRUE
    )
  ) |>
  addLegend(
    position = "bottomright",
    pal      = pal,
    values   = ~feature_type,
    title    = "Feature Type",
    opacity  = 0.9
  ) |>
  addScaleBar(position = "bottomleft") |>
  addLayersControl(
    baseGroups    = c("Dark", "Satellite", "Street"),
    overlayGroups = "Water Features",
    options       = layersControlOptions(collapsed = FALSE)
  ) |>
  addMiniMap(toggleDisplay = TRUE, minimized = TRUE)

saveWidget(water_map_interactive,
           file.path(DOCS_DIR, "water_map_interactive.html"),
           selfcontained = TRUE)
message("Saved: water_map_interactive.html")


# ── 8. Export Data ─────────────────────────────────────────────
message("Exporting data...")

st_write(water_wgs,
         file.path(OUTPUT_DIR, "zw_water_sf_simple.shp"),
         delete_layer = TRUE, quiet = TRUE)

st_write(water_wgs,
         file.path(OUTPUT_DIR, "zw_water_sf_simple.geojson"),
         delete_layer = TRUE, quiet = TRUE)

write.csv(
  st_drop_geometry(water_wgs),
  file.path(OUTPUT_DIR, "zw_water_summary.csv"),
  row.names = FALSE
)

message("All outputs saved to: ", OUTPUT_DIR)
message("Done ✓")
