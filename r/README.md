# r-for-mapmakers

## Introduction

A few R scripts to work with geographic data.

## Files

[dem_crop_persp3d.R](https://github.com/geographyclub/r-for-mapmakers/blob/master/dem_crop_persp3d.R)  -- import and plot dems.

[ga_fri.R](https://github.com/geographyclub/r-for-mapmakers/blob/master/ga_fri.R)  -- genetic algorithm to find optimal forest inventories.

[ga_network.R](https://github.com/geographyclub/r-for-mapmakers/blob/master/ga_network.R)  -- genetic algorithm to find shortest path between nodes.

[ga_plot.R](https://github.com/geographyclub/r-for-mapmakers/blob/master/ga_plot.R) -- genetic algorithm plots.

[plonski.R](https://github.com/geographyclub/r-for-mapmakers/blob/master/plonski.R) -- Plonski Yield Tables in R.

[stats.R](https://github.com/geographyclub/r-for-mapmakers/blob/master/stats.R) -- plotting more stats.

[stats_grass.R](https://github.com/geographyclub/r-for-mapmakers/blob/master/stats_grass.R) -- running R inside GRASS.

## Misc

```R
# Install required packages if not already installed
if (!require("rgdal")) install.packages("rgdal", dependencies=TRUE)
if (!require("RPostgreSQL")) install.packages("RPostgreSQL", dependencies=TRUE)
if (!require("sf")) install.packages("sf", dependencies=TRUE)

# Load required libraries
library(rgdal)
library(RPostgreSQL)
library(sf)

# Database connection parameters
db_user <- "steve"
db_name <- "us"

# Establish a connection to the PostGIS database
con <- dbConnect(PostgreSQL(), 
                 user = db_user, 
                 dbname = db_name)

# Get the list of columns from your_table
your_table=us
columns_query <- "SELECT column_name FROM information_schema.columns WHERE table_name = 'your_table';"
columns_result <- dbGetQuery(con, columns_query)
columns <- columns_result$column_name

# Iterate over each column for k-means clustering
for (column in columns) {
  # Skip non-numeric columns
  if (!is.numeric(dbGetQuery(con, paste("SELECT", column, "FROM your_table LIMIT 1;")))) {
    cat("Skipping non-numeric column:", column, "\n")
    next
  }

  # Query data from the specified column
  query <- paste("SELECT", column, "FROM your_table;", sep = " ")
  data <- dbGetQuery(con, query)

  # Perform k-means weighted clustering
  k <- 3  # Specify the number of clusters
  weights <- rep(1, length(data[[column]]))  # Adjust weights as needed
  clusters <- kmeans(data[[column]], centers = k, weights = weights)

  # Add the cluster assignments to the data
  data$cluster <- clusters$cluster

  # Create a simple feature (sf) object
  sf_data <- st_as_sf(data)

  # Write the sf object to GeoJSON file
  geojson_filename <- paste("counter_cluster_", column, ".geojson", sep = "")
  st_write(sf_data, geojson_filename, driver = "GeoJSON")

  cat("Cluster results for", column, "saved to", geojson_filename, "\n\n")
}

# Close the database connection
dbDisconnect(con)

```
