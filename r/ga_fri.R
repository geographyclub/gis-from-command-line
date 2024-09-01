### ga for selecting optimal forest stands ###
# important! uncomment to delete old database
# system("rm sqlite.db")

# load libraries
library("foreign") # read.dbf
library("ggplot2") # rescale
library("RSQLite") # write to sqlite
rm(list = ls(all = TRUE))
options(scipen = 999, digits = 2)

# set parameters
x <- 1 # just a starting value
ge <- 100 # generations + 1
st <- 100 # strings
vi <- 100 # sample size

# establish sqlite connection (create if it doesn't exist)
con <- dbConnect(dbDriver("SQLite"), dbname = "sqlite.db")

# import data
friRaw <- read.dbf("fri.dbf")
friSides <- read.dbf("friSides_2.dbf")

# process data relevant to my interests
fri <- subset(friRaw, select = c(cat, RECNO, HA, DEVSTAGE, as.numeric(WG), HT, STKG, SC, AGE, ECOSITE1, SLOPE_AVG, VOL, DIST))
fri$ECOSITE1 <- as.integer(sub("^NW", "", fri$ECOSITE1))
fri$DEVSTAGE <- as.integer(fri$DEVSTAGE)
fri$WG <- as.integer(fri$WG)
fri$DIST[which(is.na(fri$DIST))] <- 1620 # assign mean to null entries

# export genetic table for use in grass
data <- fri
names(data) <- c("GA_cat", "GA_RECNO", "GA_HA", "GA_DEVSTAGE", "GA_WG", "GA_HT", "GA_STKG", "GA_SC", "GA_AGE", "GA_ECOSITE1", "GA_SLOPE_AVG", "GA_VOL", "GA_DIST")
dbWriteTable(con, "friGenetic", data, overwrite = T, row.names = F)

# reward adjacent polygons
adjPolys <- function(){
	
}

# fitness function
ftw <- function(){
	resultRanked <<- sort(resultScaled[,12,x], index.return = TRUE, decreasing = TRUE)
}

# print function
pr <- function(){
	cat(x, max(result[,13,x]), '\n')
}

# write to sqlite function
sql <- function(){
	data1 <- as.data.frame(cbind(selectOptimal,rep(1, length(selectOptimal))))
	dbWriteTable(con, paste("S", st, "V", vi, "G", x, sep = ""), data1, overwrite = T, row.names = F)
}

# initialize variables
vc <- length(fri$cat) # population size
vars <- length(fri) # number of variables
select <- array(dim = c(st, vi, ge))
result <- array(dim = c(st, vars, ge), dimnames = list(1:st, names(fri), 1:ge))
resultScaled <- array(dim = c(st, vars, ge), dimnames = list(1:st, names(fri), 1:ge))
resultOptimal <- 0 # store best result
selectOptimal <- 0 # store best selection

# select random stands to start
for(a in 1:st){
	select[a,1:vi,1] <- sample(fri$cat, vi)
}
# begin generation loop
for(x in 1:(ge - 1)){
	# get data by string
	for(a in 1:st){
		for(b in 1:vars){
			result[a,b,x] <- mean(fri[select[a,,x],b])
		}
	}
	# scale strings
	for(a in 1:vars){
		resultScaled[,a,x] <- rescale(result[,a,x], to = c(0,1), from = range(fri[,a]))
	}
	# rank strings from fitness function
	ftw()
	# store optimal result
	if(resultRanked$x[1] > resultOptimal){
		resultOptimal <- resultRanked$x[1]
		selectOptimal <- select[resultRanked$ix[1],,x]
		names(resultOptimal) <- paste("Gen", x, "St", resultRanked$ix[1], sep = ".")
	}
	# output to screen and sqlite
	pr()
	sql()
	# carry over strings
	select[,,(x + 1)] <- select[,,x]
	# cross over middle strings
	count <- resultRanked$ix[round(st * 0.1 + 1):round(st * 0.9)]
	for(a in 1:length(count)){
		if(a == (length(count) - 1)) break # exit on last (partnerless) string
		tmp <- sample(unique(append(select[count[a],,x], select[count[a + 1],,x])), vi, replace = FALSE)
		select[count[a],,(x + 1)] <- tmp
	}
	# randomize bottom strings
	for(a in resultRanked$ix[round(st * 0.9 + 1):st]){
		select[a,,(x + 1)] <- sample(fri$cat, vi)
	}
	# mutate some strings
	select[sample(st, 1),sample(vi, round(vi * 0.2)),(x + 1)] <- sample(fri$cat, round(vi * 0.2))
}

# close sqlite connection
dbDisconnect(con)

