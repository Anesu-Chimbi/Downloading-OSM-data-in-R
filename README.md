# OSM Data Download and Analysis in R

## Description
This project demonstrates how to download, process, and analyze OpenStreetMap (OSM) data directly within R. It provides both a script for fetching OSM data and a Shiny app for interactive visualization. Using Harare, Zimbabwe as an example, this toolkit allows users to extract, analyze, and visualize water bodies from OSM data.

The Shiny app provides an interactive interface for users to explore water features in any specified area and download the map or data for further use.

![image](https://github.com/user-attachments/assets/a1c34b2f-94cb-4bec-b2d1-cd3e98fd0f41)


## Features

- **Download OSM Data:** Fetches OSM data specifically for the Harare area in Zimbabwe.
- **Process and Analyze Data:** Extracts water body features, simplifies geometries for faster rendering, and calculates areas.
- **Interactive Visualization:** Creates interactive maps with `leaflet`, featuring water bodies, legends, and scale bars.
- **Data Storage:** Saves processed water data as shapefiles and GeoJSON files.
  
## Shiny App
- **Interactive Visualization:** Creates an interactive map using leaflet, showing water bodies, legends, and scale bars for any specified location.
- **User-friendly Interface:** Allows users to input a location and view water bodies on the map.
- **Data Export Options:** Provides options to download the displayed map as an HTML file or the data as a CSV.
- **Real-time Processing:** Automatically fetches and processes data from OSM based on user input.
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


