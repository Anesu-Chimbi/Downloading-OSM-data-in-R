library(shiny)
library(osmdata)
library(rmapshaper)
library(sf)
library(leaflet)
library(htmlwidgets)

# Define UI for application
ui <- fluidPage(
    titlePanel("OSM Water Features"),
    
    sidebarLayout(
        sidebarPanel(
            # Instructions
            h4("Instructions"),
            p("Enter a location to view water bodies in that area. Use the buttons below to load data, download the map, or download the data as CSV."),
            
            textInput("location", "Enter Location", value = "Harare, Zimbabwe"),
            actionButton("loadData", "Load Data"),
            downloadButton("downloadMap", "Download Map"),
            downloadButton("downloadCSV", "Download CSV"),
            
            # Data Summary
            h4("Data Summary"),
            textOutput("numWaterBodies"),
            textOutput("totalArea")
        ),
        
        mainPanel(
            leafletOutput("map")
        )
    ),
    
   
)

# Define server logic
server <- function(input, output, session) {
    
    observeEvent(input$loadData, {
        req(input$location)  # Ensure location input is provided
        
        # Define bounding box for the specified location
        bbox <- getbb(input$location)
        
        # Construct OSM query for water features
        opq_query <- opq(bbox = bbox) |>
            add_osm_feature(key = "natural", value = "water")
        
        # Fetch the data
        osm_data <- osmdata_sf(opq_query)
        
        # Retrieve and simplify polygons for water bodies
        water_sf <- osm_data$osm_polygons
        
        # Check if data is available
        if (nrow(water_sf) == 0) {
            showNotification("No water features found in this location!", type = "error")
            return(NULL)
        }
        
        water_sf_simple <- ms_simplify(water_sf)
        
        # Ensure 'name' column is present; if not, create it
        if (!"name" %in% colnames(water_sf_simple)) {
            water_sf_simple$name <- "Unknown"
        }
        
        # Calculate the area of water bodies
        water_sf_simple$area <- st_area(water_sf_simple)
        
        # Render the Leaflet map
        output$map <- renderLeaflet({
            leaflet(data = water_sf_simple) %>%
                addTiles() %>%
                addPolygons(
                    color = "blue",
                    fillColor = "lightblue",
                    fillOpacity = 0.5,
                    weight = 2,
                    popup = ~paste("Name:", name, "<br>Area:", round(area, 2), "square meters"),
                    group = "Water Bodies"
                ) %>%
                addLegend(
                    position = "bottomright",
                    colors = c("lightblue"),
                    labels = c("Water Bodies"),
                    title = "Legend"
                ) %>%
                addScaleBar(position = "bottomleft")
        })
        
        # Output the number of water bodies
        output$numWaterBodies <- renderText({
            paste("Number of Water Bodies: ", nrow(water_sf_simple))
        })
        
        # Output the total area of water bodies
        output$totalArea <- renderText({
            total_area <- sum(as.numeric(water_sf_simple$area))
            paste("Total Area of Water Bodies: ", round(total_area, 2), "square meters")
        })
        
        # Save the interactive map as an HTML file
        output$downloadMap <- downloadHandler(
            filename = function() {
                paste("water_map_", Sys.Date(), ".html", sep = "")
            },
            content = function(file) {
                saveWidget(leaflet(data = water_sf_simple) %>%
                               addTiles() %>%
                               addPolygons(
                                   color = "blue",
                                   fillColor = "lightblue",
                                   fillOpacity = 0.5,
                                   weight = 2,
                                   popup = ~paste("Name:", name, "<br>Area:", round(area, 2), "square meters"),
                                   group = "Water Bodies"
                               ) %>%
                               addLegend(
                                   position = "bottomright",
                                   colors = c("lightblue"),
                                   labels = c("Water Bodies"),
                                   title = "Legend"
                               ) %>%
                               addScaleBar(position = "bottomleft"),
                           file)
            }
        )
        
        # Save the data as a CSV file
        output$downloadCSV <- downloadHandler(
            filename = function() {
                paste("water_data_", Sys.Date(), ".csv", sep = "")
            },
            content = function(file) {
                write.csv(as.data.frame(st_drop_geometry(water_sf_simple)), file)
            }
        )
    })
}

# Run the application
shinyApp(ui = ui, server = server)
