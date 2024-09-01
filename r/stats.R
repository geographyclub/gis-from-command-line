#################### final script for r stats ####################

# remove any old data
library("foreign")
rm(list = ls(all = TRUE))

# import data
fri_raw <- read.dbf("friFinal.dbf")
fri <- read.table("fri.txt", header = TRUE, as.is = TRUE, na.strings = "*")
modis <- read.table("modis.txt", header = TRUE, as.is = TRUE, na.strings = "*")
opt <- read.table("opt.txt", header = TRUE, as.is = TRUE, na.strings = "*")
cli <- read.table("kenora_monthly.csv", header = TRUE, as.is = TRUE, na.strings = "", sep = ",")

#################### process data ####################

# get mean npp (gc/m2/year)
nppMean <- apply(modis[1:6], 2, mean, na.rm = TRUE)
names(nppMean) <- c(2001, 2002, 2003, 2004, 2005, 2006)

# get mean ndvi
ndviMean <- apply(modis[10:15], 2, mean, na.rm = TRUE)
names(ndviMean) <- c(2001, 2002, 2003, 2004, 2005, 2006)

# get mean temp (monthly)
temp2001 <- mean(cli$Mean.Temp...C.[which(cli$Year == 2001)])
temp2002 <- mean(cli$Mean.Temp...C.[which(cli$Year == 2002)])
temp2003 <- mean(cli$Mean.Temp...C.[which(cli$Year == 2003)])
temp2004 <- mean(cli$Mean.Temp...C.[which(cli$Year == 2004)])
temp2005 <- mean(cli$Mean.Temp...C.[which(cli$Year == 2005)])
temp2006 <- mean(cli$Mean.Temp...C.[which(cli$Year == 2006)])
temp <- c(temp2001, temp2002, temp2003, temp2004, temp2005, temp2006)
names(temp) <- c(2001, 2002, 2003, 2004, 2005, 2006)

# get total precip (mm)
precip2001 <- sum(cli$Total.Precip..mm.[which(cli$Year == 2001)])
precip2002 <- sum(cli$Total.Precip..mm.[which(cli$Year == 2002)])
precip2003 <- sum(cli$Total.Precip..mm.[which(cli$Year == 2003)])
precip2004 <- sum(cli$Total.Precip..mm.[which(cli$Year == 2004)])
precip2005 <- sum(cli$Total.Precip..mm.[which(cli$Year == 2005)])
precip2006 <- sum(cli$Total.Precip..mm.[which(cli$Year == 2006)])
precip <- c(precip2001, precip2002, precip2003, precip2004, precip2005, precip2006)
names(precip) <- c(2001, 2002, 2003, 2004, 2005, 2006)

# get total rain (mm)
rain2001 <- sum(cli$Total.Rain..mm.[which(cli$Year == 2001)])
rain2002 <- sum(cli$Total.Rain..mm.[which(cli$Year == 2002)])
rain2003 <- sum(cli$Total.Rain..mm.[which(cli$Year == 2003)])
rain2004 <- sum(cli$Total.Rain..mm.[which(cli$Year == 2004)])
rain2005 <- sum(cli$Total.Rain..mm.[which(cli$Year == 2005)])
rain2006 <- sum(cli$Total.Rain..mm.[which(cli$Year == 2006)])
rain <- c(rain2001, rain2002, rain2003, rain2004, rain2005, rain2006)
names(rain) <- c(2001, 2002, 2003, 2004, 2005, 2006)

# get total snow (cm)
snow2001 <- sum(cli$Total.Snow..cm.[which(cli$Year == 2001)])
snow2002 <- sum(cli$Total.Snow..cm.[which(cli$Year == 2002)])
snow2003 <- sum(cli$Total.Snow..cm.[which(cli$Year == 2003)])
snow2004 <- sum(cli$Total.Snow..cm.[which(cli$Year == 2004)])
snow2005 <- sum(cli$Total.Snow..cm.[which(cli$Year == 2005)])
snow2006 <- sum(cli$Total.Snow..cm.[which(cli$Year == 2006)])
snow <- c(snow2001, snow2002, snow2003, snow2004, snow2005, snow2006)
names(snow) <- c(2001, 2002, 2003, 2004, 2005, 2006)

#################### npp & climate ####################

# plot year-to-year npp
png("plot_npp.png", width = 600, height = 400)
par(font.lab = 2, font.axis = 2, family = "mono", ps = 14, mar = c(4,4,1,1), oma = c(0,0,0,0), lty = 1, mfrow = c(1,1), lwd = 2)
plot(names(nppMean), nppMean, xlab = "YEAR", ylab = "MEAN NPP (gC/m^2/year)")
dev.off()

# plot year-to-year npp and temp
png("plot_npp_temp.png", width = 600, height = 400)
par(font.lab = 2, font.axis = 2, family = "mono", ps = 14, mar = c(4,4,1,1), oma = c(0,0,0,0), lty = 1, mfrow = c(1,1), lwd = 2)
plot(temp, nppMean, xlab = "MEAN TEMP (C)", ylab = "MEAN NPP (gC/m^2/year)")
text(temp[1:5], nppMean[1:5], names(nppMean)[1:5], pos = 4)
text(temp[6], nppMean[6], names(nppMean)[6], pos = 2)
abline(lm(nppMean ~ temp), lty = 2)
dev.off()

# plot year-to-year npp and precip
png("plot_npp_precip.png", width = 600, height = 400)
par(font.lab = 2, font.axis = 2, family = "mono", ps = 14, mar = c(4,4,1,1), oma = c(0,0,0,0), lty = 1, mfrow = c(1,1), lwd = 2)
plot(precip, nppMean, xlab = "TOTAL PRECIP (mm)", ylab = "MEAN NPP (gC/m^2/year)")
text(precip[c(1,2,3,5,6)], nppMean[c(1,2,3,5,6)], names(nppMean)[c(1,2,3,5,6)], pos = 4)
text(precip[4], nppMean[4], names(nppMean)[4], pos = 2)
abline(lm(nppMean ~ precip), lty = 2)
dev.off()

#################### npp & ndvi ####################

# regress npp and ndvi (average)
summary(lm(modis$npp_average ~ modis$ndvi_average))

#################### npp & fri ####################

# regress npp and biomass (2001)
summary(lm(fri_raw$npp2001_me[which(fri_raw$YRUPD == 2001)] ~ fri_raw$bio_mean[which(fri_raw$YRUPD == 2001)]))

#################### optimal areas ####################

# get stats for optimal npp, biomass and ndvi (filter size = 63; assuming equal area for non-optimal)
samp <- sample(which(is.na(opt$nppo63)), 554)
png("plot_optimal.png", width = 800, height = 400)
par(font.lab = 2, font.axis = 2, family = "mono", ps = 14, mar = c(5,5,5,1), oma = c(0,0,0,0), lty = 1, mfrow = c(1,4), lwd = 2)
boxplot(opt$nppo63[which(!is.na(opt$nppo63))], xlab = "NPP", ylab = "NPP (gC/m^2/year)", outpch = NA, ylim = c(40,250))
boxplot(opt$bo63[which(!is.na(opt$bo63))], xlab = "BIOMASS", ylab = "NPP (gC/m^2/year)", outpch = NA, ylim = c(40,250))
boxplot(opt$no63[which(!is.na(opt$no63))], xlab = "NDVI", ylab = "NPP (gC/m^2/year)", outpch = NA, ylim = c(40,250))
boxplot(modis$npp_average[samp], xlab = "NON-OPTIMAL", ylab = "NPP (gC/m^2/year)", outpch = NA, ylim = c(40,250))
dev.off()
summary(opt$nppo63[which(!is.na(opt$nppo63))]) # npp stats
summary(opt$bo63[which(!is.na(opt$bo63))]) # biomass stats
summary(opt$no63[which(!is.na(opt$no63))]) # ndvi stats
summary(modis$npp_average[samp]) # non-optimal stats

# get stats for optimal npp_slope, cai and non-optimal areas (filter size = 63)
samp <- sample(which(is.na(opt$npp_slope_opt63)), 588)
png("plot_optimal_cai.png", width = 800, height = 400)
par(font.lab = 2, font.axis = 2, family = "mono", ps = 14, mar = c(5,5,5,1), oma = c(0,0,0,0), lty = 1, mfrow = c(1,3), lwd = 2)
boxplot(modis$npp_slope[which(!is.na(opt$npp_slope_opt63))], xlab = "NPP SLOPE", ylab = "NPP (gC/m^2/year)", outpch = NA, ylim = c(0,2))
boxplot(modis$npp_slope[which(!is.na(opt$cai6_opt63))], xlab = "CAI", ylab = "NPP (gC/m^2/year)", outpch = NA, ylim = c(0,2))
boxplot(modis$npp_slope[samp], xlab = "NON-OPTIMAL", ylab = "NPP (gC/m^2/year)", outpch = NA, ylim = c(0,2))
dev.off()
summary(modis$npp_slope[which(!is.na(opt$npp_slope_opt63))]) # npp_slope stats
summary(modis$npp_slope[which(!is.na(opt$cai6_opt63))]) # cai stats
summary(modis$npp_slope[samp]) # non-optimal

# get total biomass for optimal areas
c(sum(opt$bo3[which(!is.na(opt$bo3))]), sum(opt$bo43[which(!is.na(opt$bo43))]), sum(opt$bo93[which(!is.na(opt$bo93))]))
c(sum(opt$eo3[which(!is.na(opt$eo3))]), sum(opt$eo43[which(!is.na(opt$eo43))]), sum(opt$eo93[which(!is.na(opt$eo93))]))
c(sum(opt$no3[which(!is.na(opt$no3))]), sum(opt$no43[which(!is.na(opt$no43))]), sum(opt$no93[which(!is.na(opt$no93))]))


