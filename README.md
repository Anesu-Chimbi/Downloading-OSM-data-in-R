# OSM Data Download and Analysis in R

## Description

This project demonstrates how to download, process, and analyze OpenStreetMap (OSM) data directly within R, using Harare, Zimbabwe, as an example. It includes scripts for fetching OSM data, processing it to extract water bodies, and visualizing the data with both interactive and static maps. 

## Features

- **Download OSM Data:** Fetches OSM data specifically for the Harare area in Zimbabwe.
- **Process and Analyze Data:** Extracts water body features, simplifies geometries for faster rendering, and calculates areas.
- **Interactive Visualization:** Creates interactive maps with `leaflet`, featuring water bodies, legends, and scale bars.
- **Data Storage:** Saves processed water data as shapefiles and GeoJSON files.

## Installation

To use this project, ensure you have the required R packages installed. You can install them using the following commands:

```r
install.packages("sf")
install.packages("leaflet")
install.packages("osmdata")
install.packages("rmapshaper")
install.packages("mapview")
install.packages("webshot")
install.packages("htmlwidgets")
