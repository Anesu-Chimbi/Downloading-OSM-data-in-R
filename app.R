# ============================================================
# OSM Water Features Explorer — Modernized Shiny App v2.0
# Author: Anesu Chimbi
# Updated: 2025 — Modern UI, enhanced analysis, new features
# ============================================================

library(shiny)
library(bslib)
library(osmdata)
library(rmapshaper)
library(sf)
library(leaflet)
library(leaflet.extras)
library(htmlwidgets)
library(dplyr)
library(ggplot2)
library(plotly)
library(DT)
library(units)

# ── Colour palette ──────────────────────────────────────────
WATER_FILL    <- "#4a9eca"
WATER_BORDER  <- "#1a6fa0"
ACCENT        <- "#0ea5e9"

# ── Helper: human-readable area ─────────────────────────────
fmt_area <- function(x_m2) {
  x <- as.numeric(x_m2)
  dplyr::case_when(
    x >= 1e6  ~ paste0(round(x / 1e6, 3), " km²"),
    x >= 1e4  ~ paste0(round(x / 1e4, 2), " ha"),
    TRUE       ~ paste0(round(x, 1), " m²")
  )
}

# ── UI ───────────────────────────────────────────────────────
ui <- page_sidebar(
  title = NULL,
  theme = bs_theme(
    version    = 5,
    bg         = "#0f172a",
    fg         = "#e2e8f0",
    primary    = ACCENT,
    secondary  = "#334155",
    success    = "#22c55e",
    info       = "#38bdf8",
    warning    = "#f59e0b",
    danger     = "#ef4444",
    base_font  = font_google("Inter"),
    heading_font = font_google("Space Grotesk"),
    font_scale = 0.9
  ),

  # ── Custom CSS ──────────────────────────────────────────────
  tags$head(tags$style(HTML("
    body { background: #0f172a; }

    .app-header {
      background: linear-gradient(135deg, #0f172a 0%, #1e3a5f 100%);
      border-bottom: 1px solid #1e40af40;
      padding: 1rem 1.5rem;
      display: flex; align-items: center; gap: 1rem;
    }
    .app-header .logo-icon {
      font-size: 2rem; filter: drop-shadow(0 0 8px #38bdf8aa);
    }
    .app-header h1 {
      margin: 0; font-size: 1.5rem; font-weight: 700;
      background: linear-gradient(90deg, #38bdf8, #818cf8);
      -webkit-background-clip: text; -webkit-text-fill-color: transparent;
    }
    .app-header p {
      margin: 0; font-size: 0.78rem; color: #64748b;
    }

    /* Sidebar */
    .bslib-sidebar-layout > .sidebar {
      background: #1e293b !important;
      border-right: 1px solid #334155 !important;
    }

    /* Stat cards */
    .stat-card {
      background: #1e293b;
      border: 1px solid #334155;
      border-radius: 12px;
      padding: 1rem;
      margin-bottom: 0.75rem;
      transition: border-color .2s;
    }
    .stat-card:hover { border-color: #38bdf8; }
    .stat-card .stat-val {
      font-size: 1.6rem; font-weight: 700; color: #38bdf8;
      font-family: 'Space Grotesk', sans-serif;
    }
    .stat-card .stat-lbl {
      font-size: 0.72rem; color: #64748b; text-transform: uppercase;
      letter-spacing: 0.06em; margin-top: 2px;
    }
    .stat-card .stat-icon { font-size: 1.4rem; float: right; opacity: .4; }

    /* Tabs */
    .nav-tabs { border-bottom: 1px solid #334155 !important; }
    .nav-tabs .nav-link { color: #64748b !important; border: none !important; }
    .nav-tabs .nav-link.active {
      color: #38bdf8 !important; background: transparent !important;
      border-bottom: 2px solid #38bdf8 !important;
    }

    /* Map container */
    #map { border-radius: 12px; overflow: hidden; }

    /* Load button */
    #loadData {
      background: linear-gradient(135deg, #0ea5e9, #6366f1) !important;
      border: none !important; width: 100%; font-weight: 600;
      letter-spacing: .04em; border-radius: 8px !important;
      box-shadow: 0 4px 15px #0ea5e940;
    }
    #loadData:hover { opacity: .9; transform: translateY(-1px); }

    /* Download buttons */
    .dl-btn {
      background: #1e293b !important; border: 1px solid #334155 !important;
      color: #94a3b8 !important; width: 100%; margin-bottom: .4rem;
      border-radius: 8px !important; font-size: .82rem;
    }
    .dl-btn:hover { border-color: #38bdf8 !important; color: #38bdf8 !important; }

    /* Input */
    .form-control {
      background: #0f172a !important; border: 1px solid #334155 !important;
      color: #e2e8f0 !important; border-radius: 8px !important;
    }
    .form-control:focus {
      border-color: #38bdf8 !important;
      box-shadow: 0 0 0 3px #38bdf820 !important;
    }

    /* Feature type checkboxes */
    .shiny-input-checkboxgroup label { color: #94a3b8; font-size: .83rem; }
    .form-check-input:checked { background-color: #0ea5e9; border-color: #0ea5e9; }

    /* DT table */
    .dataTables_wrapper { color: #94a3b8; }
    table.dataTable thead { background: #1e293b; color: #64748b; font-size: .8rem; }
    table.dataTable tbody tr { background: #0f172a !important; }
    table.dataTable tbody tr:hover { background: #1e293b !important; }
    table.dataTable tbody td { color: #94a3b8; font-size: .82rem; }
    .dataTables_filter input, .dataTables_length select {
      background: #1e293b !important; border: 1px solid #334155 !important;
      color: #e2e8f0 !important; border-radius: 6px; padding: 2px 6px;
    }

    /* Plot area */
    .plotly .bg { fill: #0f172a !important; }

    /* Loading overlay */
    #loading-overlay {
      display: none; position: fixed; inset: 0; z-index: 9999;
      background: #0f172a99; backdrop-filter: blur(4px);
      align-items: center; justify-content: center; flex-direction: column;
    }
    .spinner-ring {
      width: 60px; height: 60px; border-radius: 50%;
      border: 4px solid #1e293b;
      border-top-color: #38bdf8;
      animation: spin 1s linear infinite;
    }
    @keyframes spin { to { transform: rotate(360deg); } }
    .loading-text { color: #38bdf8; margin-top: 1rem; font-size: .9rem; }

    /* Section label */
    .section-label {
      font-size: .68rem; text-transform: uppercase; letter-spacing: .1em;
      color: #475569; margin: 1rem 0 .4rem; font-weight: 600;
    }
  "))),

  # Loading overlay
  div(id = "loading-overlay",
    div(class = "spinner-ring"),
    div(class = "loading-text", "Fetching OSM data...")
  ),

  # ── Header ──────────────────────────────────────────────────
  div(class = "app-header",
#div(class = "logo-icon", "🌊"),#
    div(
      h1("OSM Water Explorer"),
      p("OpenStreetMap hydrological feature analysis")
    )
  ),

  # ── Sidebar ─────────────────────────────────────────────────
  sidebar = sidebar(
    width = 290,
    bg = "#1e293b",

    div(class = "section-label", "Location"),
    textInput("location", label = NULL,
              value = "Harare, Zimbabwe",
              placeholder = "City, Country"),

    div(class = "section-label", "Feature Types"),
    checkboxGroupInput("feature_types", label = NULL,
      choices = list(
        "Natural Water"   = "natural:water",
        "Waterways"       = "waterway",
        "Reservoirs"      = "landuse:reservoir"
      ),
      selected = c("natural:water")
    ),

    div(class = "section-label", "Map Style"),
    selectInput("basemap", label = NULL,
      choices = c(
        "Dark (CartoDB)"    = "CartoDB.DarkMatter",
        "Satellite"         = "Esri.WorldImagery",
        "Street"            = "OpenStreetMap",
        "Terrain"           = "Stadia.StamenTerrain"
      ), selected = "CartoDB.DarkMatter"
    ),

    br(),
    actionButton("loadData", "⬇  Load Data", class = "btn btn-primary"),

    br(), br(),
    div(class = "section-label", "Statistics"),
    uiOutput("statsCards"),

    br(),
    div(class = "section-label", "Export"),
    downloadButton("downloadMap",     "🗺  Download Map (HTML)",  class = "dl-btn"),
    downloadButton("downloadCSV",     "📄  Download Data (CSV)",  class = "dl-btn"),
    downloadButton("downloadGeoJSON", "📦  Download GeoJSON",     class = "dl-btn")
  ),

  # ── Main panel ──────────────────────────────────────────────
  navset_tab(
    nav_panel("🗺 Map",
      leafletOutput("map", height = "calc(100vh - 160px)")
    ),
    nav_panel("📊 Analytics",
      layout_columns(
        col_widths = c(6, 6),
        card(
          card_header("Area Distribution"),
          plotlyOutput("areaHistPlot", height = "280px")
        ),
        card(
          card_header("Top 10 Largest Water Bodies"),
          plotlyOutput("topBodiesPlot", height = "280px")
        )
      ),
      layout_columns(
        col_widths = c(4, 4, 4),
        card(card_header("Size Class Breakdown"), plotlyOutput("sizeBreakdownPlot", height = "240px")),
        card(card_header("Cumulative Area Share"), plotlyOutput("cumulPlot", height = "240px")),
        card(card_header("Feature Type Mix"),      plotlyOutput("typePiePlot",   height = "240px"))
      )
    ),
    nav_panel("📋 Data Table",
      card(DTOutput("dataTable"))
    )
  ),

  # JS for loading spinner
  tags$script(HTML("
    $(document).on('shiny:busy', function() {
      $('#loading-overlay').css('display','flex');
    });
    $(document).on('shiny:idle', function() {
      $('#loading-overlay').hide();
    });
  "))
)

# ── Server ───────────────────────────────────────────────────
server <- function(input, output, session) {

  water_data <- reactiveVal(NULL)

  # ── Fetch OSM data ─────────────────────────────────────────
  observeEvent(input$loadData, {
    req(input$location)
    tryCatch({
      bbox <- getbb(input$location)
      all_features <- list()

      # Natural water
      if ("natural:water" %in% input$feature_types) {
        q <- opq(bbox = bbox) |> add_osm_feature("natural", "water")
        d <- osmdata_sf(q)
        polys <- d$osm_polygons
        if (!is.null(polys) && nrow(polys) > 0) {
          polys$feature_type <- "Natural Water"
          all_features[["natural"]] <- polys
        }
      }

      # Waterways (lines → buffered)
      if ("waterway" %in% input$feature_types) {
        q <- opq(bbox = bbox) |> add_osm_feature("waterway")
        d <- osmdata_sf(q)
        lines <- d$osm_lines
        if (!is.null(lines) && nrow(lines) > 0) {
          lines <- st_transform(lines, 32736)          # UTM 36S for Zimbabwe
          lines <- st_buffer(lines, dist = 15)
          lines <- st_transform(lines, 4326)
          lines$feature_type <- "Waterway"
          all_features[["waterway"]] <- lines
        }
      }

      # Reservoirs
      if ("landuse:reservoir" %in% input$feature_types) {
        q <- opq(bbox = bbox) |> add_osm_feature("landuse", "reservoir")
        d <- osmdata_sf(q)
        polys <- d$osm_polygons
        if (!is.null(polys) && nrow(polys) > 0) {
          polys$feature_type <- "Reservoir"
          all_features[["reservoir"]] <- polys
        }
      }

      if (length(all_features) == 0) {
        showNotification("No water features found for this location.", type = "warning")
        return()
      }

      # Bind and simplify
      combined <- bind_rows(lapply(all_features, function(x) {
        keep_cols <- c("osm_id", "name", "geometry", "feature_type")
        existing <- intersect(keep_cols, names(x))
        st_as_sf(x)[, existing]
      }))

      combined <- ms_simplify(combined, keep = 0.05)

      # Ensure name column
      if (!"name" %in% names(combined)) combined$name <- NA_character_
      combined$name[is.na(combined$name)] <- "Unnamed"

      # Area calculations (reproject for accuracy)
      combined_utm <- st_transform(combined, 32736)
      combined$area_m2  <- as.numeric(st_area(combined_utm))
      combined$area_ha  <- round(combined$area_m2 / 1e4, 4)
      combined$area_km2 <- round(combined$area_m2 / 1e6, 6)
      combined$area_fmt <- fmt_area(combined$area_m2)

      # Size classification
      combined$size_class <- cut(
        combined$area_m2,
        breaks = c(0, 1e3, 1e4, 1e5, Inf),
        labels = c("Small (<1ha)", "Medium (1-10ha)", "Large (10-100ha)", "Very Large (>100ha)"),
        right  = FALSE
      )

      water_data(combined)

    }, error = function(e) {
      showNotification(paste("Error:", condenseMessage(e$message)), type = "danger", duration = 8)
    })
  })

  # ── Map ────────────────────────────────────────────────────
  output$map <- renderLeaflet({
    leaflet() |>
      addProviderTiles("CartoDB.DarkMatter") |>
      setView(lng = 31.05, lat = -17.83, zoom = 11)
  })

  observe({
    df <- water_data()
    req(df)

    type_colors <- c(
      "Natural Water" = "#38bdf8",
      "Waterway"      = "#818cf8",
      "Reservoir"     = "#22d3ee"
    )
    pal <- colorFactor(
      palette = unname(type_colors),
      domain  = names(type_colors)
    )

    bb <- st_bbox(df)

    leafletProxy("map") |>
      clearShapes() |>
      clearControls() |>
      removeLayersControl() |>
      addProviderTiles(input$basemap) |>
      fitBounds(bb[[1]], bb[[2]], bb[[3]], bb[[4]]) |>
      addPolygons(
        data        = df,
        color       = ~pal(feature_type),
        fillColor   = ~pal(feature_type),
        fillOpacity = 0.55,
        weight      = 1,
        popup       = ~paste0(
          "<div style='font-family:Inter,sans-serif;font-size:13px;min-width:180px'>",
          "<b style='color:#38bdf8'>", name, "</b><br>",
          "<span style='color:#64748b'>Type: </span>",   feature_type, "<br>",
          "<span style='color:#64748b'>Area: </span>",   area_fmt,
          "</div>"
        ),
        label       = ~name,
        group       = ~feature_type,
        highlightOptions = highlightOptions(
          color = "#ffffff", weight = 3, fillOpacity = 0.8,
          bringToFront = TRUE
        )
      ) |>
      addLegend(
        position = "bottomright",
        pal      = pal,
        values   = df$feature_type,
        title    = "Feature Type",
        opacity  = 0.9
      ) |>
      addScaleBar(position = "bottomleft") |>
      addLayersControl(
        overlayGroups = unique(df$feature_type),
        options = layersControlOptions(collapsed = FALSE)
      ) |>
      addFullscreenControl()
  })

  # ── Stats cards ────────────────────────────────────────────
  output$statsCards <- renderUI({
    df <- water_data()
    if (is.null(df)) {
      return(div(style = "color:#475569;font-size:.82rem", "Load data to see statistics."))
    }
    total_area <- sum(df$area_m2, na.rm = TRUE)
    tagList(
      div(class = "stat-card",
        div(class = "stat-icon", "🔵"),
        div(class = "stat-val", nrow(df)),
        div(class = "stat-lbl", "Total Features")
      ),
      div(class = "stat-card",
        div(class = "stat-icon", "📐"),
        div(class = "stat-val", fmt_area(total_area)),
        div(class = "stat-lbl", "Total Area")
      ),
      div(class = "stat-card",
        div(class = "stat-icon", "📏"),
        div(class = "stat-val", fmt_area(mean(df$area_m2, na.rm = TRUE))),
        div(class = "stat-lbl", "Avg Feature Size")
      )
    )
  })

  # ── Analytics plots ────────────────────────────────────────
  plot_theme <- function() {
    theme_minimal(base_family = "Inter") +
    theme(
      plot.background  = element_rect(fill = "#0f172a", color = NA),
      panel.background = element_rect(fill = "#0f172a", color = NA),
      panel.grid.major = element_line(color = "#1e293b"),
      panel.grid.minor = element_blank(),
      text             = element_text(color = "#94a3b8"),
      axis.text        = element_text(color = "#64748b", size = 8),
      axis.title       = element_text(color = "#94a3b8", size = 9),
      plot.title       = element_text(color = "#e2e8f0", size = 11, face = "bold"),
      legend.background = element_rect(fill = "#1e293b", color = NA),
      legend.text      = element_text(color = "#94a3b8", size = 8)
    )
  }

  plotly_config <- function(p) {
    p |> config(displayModeBar = FALSE) |>
      layout(
        paper_bgcolor = "#0f172a",
        plot_bgcolor  = "#0f172a",
        font          = list(color = "#94a3b8", family = "Inter"),
        margin        = list(l = 40, r = 20, t = 30, b = 40)
      )
  }

  output$areaHistPlot <- renderPlotly({
    df <- water_data(); req(df)
    p <- ggplot(df, aes(x = log10(area_m2 + 1))) +
      geom_histogram(bins = 25, fill = "#38bdf8", alpha = .8, color = "#0f172a") +
      labs(x = "log₁₀(Area m²)", y = "Count", title = "Area Distribution") +
      plot_theme()
    plotly_config(ggplotly(p, tooltip = c("x", "y")))
  })

  output$topBodiesPlot <- renderPlotly({
    df <- water_data(); req(df)
    top10 <- df |> as.data.frame() |>
      arrange(desc(area_m2)) |> head(10) |>
      mutate(label = ifelse(name == "Unnamed",
                            paste0("Feature ", row_number()), name))
    p <- ggplot(top10, aes(x = reorder(label, area_m2), y = area_ha, fill = area_ha)) +
      geom_col(show.legend = FALSE) +
      scale_fill_gradient(low = "#1d4ed8", high = "#38bdf8") +
      coord_flip() +
      labs(x = NULL, y = "Area (ha)", title = "Top 10 by Area") +
      plot_theme()
    plotly_config(ggplotly(p, tooltip = c("y")))
  })

  output$sizeBreakdownPlot <- renderPlotly({
    df <- water_data(); req(df)
    cnt <- df |> as.data.frame() |> count(size_class, .drop = FALSE)
    p <- ggplot(cnt, aes(x = size_class, y = n, fill = size_class)) +
      geom_col(show.legend = FALSE) +
      scale_fill_manual(values = c("#1d4ed8","#0ea5e9","#22d3ee","#38bdf8")) +
      labs(x = NULL, y = "Count", title = "Size Classes") +
      plot_theme() +
      theme(axis.text.x = element_text(angle = 25, hjust = 1, size = 7))
    plotly_config(ggplotly(p, tooltip = c("x","y")))
  })

  output$cumulPlot <- renderPlotly({
    df <- water_data(); req(df)
    sorted <- sort(df$area_m2, decreasing = TRUE)
    cum_pct <- cumsum(sorted) / sum(sorted) * 100
    d <- data.frame(rank = seq_along(sorted), cumulative = cum_pct)
    p <- ggplot(d, aes(x = rank, y = cumulative)) +
      geom_line(color = "#38bdf8", linewidth = 1) +
      geom_area(fill = "#38bdf8", alpha = .1) +
      labs(x = "Feature rank", y = "Cumulative %", title = "Lorenz Curve") +
      plot_theme()
    plotly_config(ggplotly(p))
  })

  output$typePiePlot <- renderPlotly({
    df <- water_data(); req(df)
    cnt <- df |> as.data.frame() |> count(feature_type)
    plot_ly(cnt, labels = ~feature_type, values = ~n, type = "pie",
            marker = list(colors = c("#38bdf8","#818cf8","#22d3ee")),
            textinfo = "label+percent",
            hoverinfo = "label+value",
            showlegend = FALSE) |>
      plotly_config() |>
      layout(title = list(text = "Feature Types", font = list(color = "#e2e8f0", size = 12)))
  })

  # ── Data table ─────────────────────────────────────────────
  output$dataTable <- renderDT({
    df <- water_data(); req(df)
    tbl <- as.data.frame(df) |>
      select(osm_id, name, feature_type, area_fmt, area_ha, area_km2, size_class) |>
      rename(
        "OSM ID"       = osm_id,
        "Name"         = name,
        "Type"         = feature_type,
        "Area"         = area_fmt,
        "Area (ha)"    = area_ha,
        "Area (km²)"   = area_km2,
        "Size Class"   = size_class
      )
    datatable(tbl, extensions = "Buttons",
      options = list(
        dom = "Bfrtip",
        buttons = c("copy", "csv", "excel"),
        pageLength = 15,
        scrollX = TRUE,
        initComplete = JS("function(s,d) {
          $(s.nTable()).css({'background':'#0f172a','color':'#94a3b8'});
        }")
      ),
      rownames = FALSE, class = "compact stripe"
    )
  })

  # ── Downloads ──────────────────────────────────────────────
  output$downloadMap <- downloadHandler(
    filename = function() paste0("water_map_", Sys.Date(), ".html"),
    content  = function(file) {
      df <- water_data(); req(df)
      m <- leaflet(data = df) |>
        addProviderTiles("CartoDB.DarkMatter") |>
        addPolygons(
          color = WATER_BORDER, fillColor = WATER_FILL,
          fillOpacity = 0.55, weight = 1,
          popup = ~paste0("<b>", name, "</b><br>Type: ", feature_type, "<br>Area: ", area_fmt)
        ) |>
        addLegend(position = "bottomright", colors = WATER_FILL,
                  labels = "Water Feature", title = "OSM Water Explorer") |>
        addScaleBar(position = "bottomleft")
      saveWidget(m, file)
    }
  )

  output$downloadCSV <- downloadHandler(
    filename = function() paste0("water_data_", Sys.Date(), ".csv"),
    content  = function(file) {
      df <- water_data(); req(df)
      write.csv(st_drop_geometry(df) |>
        select(osm_id, name, feature_type, area_m2, area_ha, area_km2, size_class),
        file, row.names = FALSE)
    }
  )

  output$downloadGeoJSON <- downloadHandler(
    filename = function() paste0("water_data_", Sys.Date(), ".geojson"),
    content  = function(file) {
      df <- water_data(); req(df)
      st_write(df, file, driver = "GeoJSON", quiet = TRUE)
    }
  )
}

shinyApp(ui = ui, server = server)
