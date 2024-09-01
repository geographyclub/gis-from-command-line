# Install and load necessary packages
#sudo apt install fontconfig-dev libharfbuzz-dev libfribidi-dev
#install.packages("tidyverse")
#install.packages("RPostgreSQL")
library(tidyverse)
library(RPostgreSQL)

# Set up PostgreSQL connection parameters
db_connection <- dbConnect(
  PostgreSQL(),
  user = "steve",
  dbname = "canada",
)

# Specify the URLs for the census data files
neighborhood_url <- "https://www12.statcan.gc.ca/census-recensement/2016/dp-pd/prof/details/download-telecharger/comp/page_dl-tc.cfm?Lang=E&Tab=1&Geo1=CSD&Code1=3520005&Geo2=PR&Code2=35&SearchText=toronto&SearchType=Begins&SearchPR=01&B1=Income2015&Custom=&Line=1&Inhabitants=1"
census_tract_url <- "https://www12.statcan.gc.ca/census-recensement/2016/dp-pd/prof/details/download-telecharger/comp/page_dl-tc.cfm?Lang=E&Geo1=CT&Code1=3520005&Geo2=PR&Code2=35&SearchText=toronto&SearchType=Begins&SearchPR=01&B1=Income2015&Custom=&Line=1&Inhabitants=1"

# Download Toronto neighborhood data
neighborhood_data <- read.csv(neighborhood_url)

# Download Toronto census tract data
census_tract_data <- read.csv(census_tract_url)

# Create tables in PostgreSQL and insert data
dbWriteTable(db_connection, "toronto_neighborhood_data", neighborhood_data)
dbWriteTable(db_connection, "toronto_census_tract_data", census_tract_data)

# Close the database connection
dbDisconnect(db_connection)


################

install.packages("opendatatoronto")
install.packages("dplyr")
library(opendatatoronto)
library(dplyr)

# get package
package <- show_package("6e19a90f-971c-46b3-852c-0c48c436d1fc")

# get all resources for this package
resources <- list_package_resources("6e19a90f-971c-46b3-852c-0c48c436d1fc")

#datastore_resources <- filter(resources, tolower(format) %in% c('csv', 'geojson'))
datastore_resources <- resources %>% filter(format == "XLSX")

# load the first datastore resource
data <- filter(datastore_resources, row_number()==1) %>% get_resource()
data$hd2021_census_profile
