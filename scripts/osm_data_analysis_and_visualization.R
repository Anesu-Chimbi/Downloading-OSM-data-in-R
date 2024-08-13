
# Load necessary libraries
library(httr2)
library(osmdata)
library(giscoR)
library(mapview)
library(rmapshaper)
library(sf)
library(leaflet)
library(webshot)
library(ggplot2)    # For enhanced map features
library(ggspatial)  # For adding north arrow and scale bar
library(ggplot2)    # For enhanced map features
library(ggspatial)  # For adding north arrow and scale bar
library(mapview)    # For saving maps
library(htmlwidgets)
library(ggspatial)


# Define a smaller bounding box for a specific region in Zimbabwe
Zimbabwe_bbox_small <- getbb("Harare, Zimbabwe")

# Construct an OSM query for water features
zw_water_opq <- opq(bbox = Zimbabwe_bbox_small) |>
  add_osm_feature(key = "natural", value = "water")

# Fetch the data
zw_water_osm_data <- osmdata_sf(zw_water_opq)

# Retrieve polygons for water bodies
zw_water_sf <- zw_water_osm_data$osm_polygons

# Simplify the geometries to speed up visualization
zw_water_sf_simple <- ms_simplify(zw_water_sf)

# Visualize the simplified data using mapview
mapview(zw_water_sf_simple, layer.name = "Water Bodies")

# Save the simplified water data to a shapefile and GeoJSON
# Save to your specific folders
st_write(zw_water_sf_simple, "C:/Users/anesu/Documents/R 2024/Downloading-OSM-data-in-R/data/zw_water_sf_simple.shp")
st_write(zw_water_sf_simple, "C:/Users/anesu/Documents/R 2024/Downloading-OSM-data-in-R/data/zw_water_sf_simple.geojson")

# Perform basic analysis: Calculate the area of water bodies
zw_water_sf_simple$area <- st_area(zw_water_sf_simple)
summary(zw_water_sf_simple$area)


# Create an interactive map with leaflet
water_map_leaflet <- leaflet(data = zw_water_sf_simple) %>%
  addTiles() %>%
  addPolygons(
    color = "blue",
    fillColor = "lightblue",
    fillOpacity = 0.5,
    weight = 2,
    popup = ~paste("Area:", round(area, 2), "square meters"),
    group = "Water Bodies"
  ) %>%
  addLegend(
    position = "bottomright",
    colors = c("lightblue"),
    labels = c("Water Bodies"),
    title = "Legend"
  ) %>%
  addScaleBar(position = "bottomleft")

# Save the interactive map as an HTML file
saveWidget(water_map_leaflet, "/Users/anesu/Documents/R 2024/Downloading-OSM-data-in-R/docs/water_map_interactive.html")

