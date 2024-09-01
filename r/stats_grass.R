##### script to work with thesis data #####
# need to run r inside grass for complete functionality

# get 'er started
#library("plotrix") # twoord.plot
#library("matlab") # rot90
#library("fields") # image.plot
library("foreign") # read.dbf
rm(list = ls(all = TRUE))

# import data
#fri <- read.dbf("fri.dbf")
fri <- read.table("basic.txt", header = TRUE, as.is = TRUE, na.strings = "*")
bio <- read.table("bio.txt", header = TRUE, as.is = TRUE, na.strings = "*")
opt <- read.table("opt.txt", header = TRUE, as.is = TRUE, na.strings = "*")
opt_npp <- read.table("opt_npp.txt", header = TRUE, as.is = TRUE, na.strings = "*")
npp <- read.table("npp.txt", header = TRUE, as.is = TRUE, na.strings = "*")
ndvi <- read.table("ndvi.txt", header = TRUE, as.is = TRUE, na.strings = "*")
slope <- read.table("slope.txt", header = TRUE, as.is = TRUE, na.strings = "*")
total <- read.table("total.txt", header = TRUE, as.is = TRUE, na.strings = "*")
cli <- read.table("kenora_monthly.csv", header = TRUE, as.is = TRUE, na.strings = "", sep = ",")

# get mean npp (gc/m2/year)
npp2001 <- mean(npp$npp2001)
npp2002 <- mean(npp$npp2002)
npp2003 <- mean(npp$npp2003)
npp2004 <- mean(npp$npp2004)
npp2005 <- mean(npp$npp2005)
npp2006 <- mean(npp$npp2006)
nppMean <- c(npp2001, npp2002, npp2003, npp2004, npp2005, npp2006)
names(nppMean) <- c(2001, 2002, 2003, 2004, 2005, 2006)

# get mean ndvi
ndvi2001 <- mean(ndvi$ndvi2001)
ndvi2002 <- mean(ndvi$ndvi2002)
ndvi2003 <- mean(ndvi$ndvi2003)
ndvi2004 <- mean(ndvi$ndvi2004)
ndvi2005 <- mean(ndvi$ndvi2005)
ndvi2006 <- mean(ndvi$ndvi2006)
ndviMean <- c(ndvi2001, ndvi2002, ndvi2003, ndvi2004, ndvi2005, ndvi2006)
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

# plot year-to-year npp and rain
png("plot_npp_rain.png", width = 600, height = 400)
par(font.lab = 2, font.axis = 2, family = "mono", ps = 14, mar = c(4,4,1,1), oma = c(0,0,0,0), lty = 1, mfrow = c(1,1), lwd = 2)
plot(rain, nppMean, xlab = "TOTAL RAIN (mm)", ylab = "MEAN NPP (gC/m^2/year)")
text(rain[c(1,2,3,5,6)], nppMean[c(1,2,3,5,6)], names(nppMean)[c(1,2,3,5,6)], pos = 4)
text(rain[4], nppMean[4], names(nppMean)[4], pos = 2)
abline(lm(nppMean ~ rain), lty = 2)
dev.off()

# plot year-to-year npp and snow
png("plot_npp_snow.png", width = 600, height = 400)
par(font.lab = 2, font.axis = 2, family = "mono", ps = 14, mar = c(4,4,1,1), oma = c(0,0,0,0), lty = 1, mfrow = c(1,1), lwd = 2)
plot(snow, nppMean, xlab = "TOTAL SNOW (cm)", ylab = "MEAN NPP (gC/m^2/year)")
text(snow[c(1,2,3,5,6)], nppMean[c(1,2,3,5,6)], names(nppMean)[c(1,2,3,5,6)], pos = 4)
text(snow[4], nppMean[4], names(nppMean)[4], pos = 2)
abline(lm(nppMean ~ snow), lty = 2)
dev.off()

# plot year-to-year npp and ndvi
png("plot_npp_ndvi.png", width = 600, height = 400)
par(font.lab = 2, font.axis = 2, family = "mono", ps = 14, mar = c(4,4,1,1), oma = c(0,0,0,0), lty = 1, mfrow = c(1,1), lwd = 2)
plot(ndviMean, nppMean, xlab = "MEAN NDVI", ylab = "MEAN NPP (g/cm^2/year)")
text(ndviMean[c(1,2,4,5,6)], nppMean[c(1,2,4,5,6)], names(nppMean)[c(1,2,4,5,6)], pos = 4)
text(ndviMean[3], nppMean[3], names(nppMean)[3], pos = 2)
abline(lm(nppMean ~ ndviMean), lty = 2)
dev.off()

# plot slope of year-to-year npp change

# plot npp and biomass
samp <- sample(length(npp$npp2001), 100)
png("plot_npp_biomass.png", width = 600, height = 400)
par(font.lab = 2, font.axis = 2, family = "mono", ps = 14, mar = c(4,4,1,1), oma = c(0,0,0,0), lty = 1, mfrow = c(1,1), lwd = 2)
plot(npp$biomass[samp], npp$npp2001[samp], xlab = "BIOMASS (T)", ylab = "NPP (g/cm^2/year)")
abline(lm(npp$npp2001[samp] ~ npp$biomass[samp]), lty = 2)
dev.off()

# plot npp and sc
samp <- sample(length(npp$npp2001), 100)
png("plot_npp_sc.png", width = 600, height = 400)
par(font.lab = 2, font.axis = 2, family = "mono", ps = 14, mar = c(4,4,1,1), oma = c(0,0,0,0), lty = 1, mfrow = c(1,1), lwd = 2)
plot(npp$sc[samp], npp$npp2001[samp], xlab = "SITE CLASS", ylab = "NPP (g/cm^2/year)")
abline(lm(npp$npp2001[samp] ~ npp$sc[samp]), lty = 2)
dev.off()

# plot npp and stkg
samp <- sample(length(npp$npp2001), 100)
png("plot_npp_stkg.png", width = 600, height = 400)
par(font.lab = 2, font.axis = 2, family = "mono", ps = 14, mar = c(4,4,1,1), oma = c(0,0,0,0), lty = 1, mfrow = c(1,1), lwd = 2)
plot(npp$stkg[samp], npp$npp2001[samp], xlab = "STOCKING FACTOR", ylab = "NPP (g/cm^2/year)")
abline(lm(npp$npp2001[samp] ~ npp$stkg[samp]), lty = 2)
dev.off()

# plot npp and wg
png("plot_npp_wg.png", width = 600, height = 400)
par(font.lab = 2, font.axis = 2, family = "mono", ps = 14, mar = c(4,4,1,1), oma = c(0,0,0,0), lty = 1, mfrow = c(1,2), lwd = 2)
boxplot(npp$npp2001[which(npp$wg == 1)], xlab = "BROADLEAF", ylab = "NPP (g/cm^2/year)", outpch = NA, ylim = c(4000, 7000))
boxplot(npp$npp2001[which(npp$wg == 2)], xlab = "CONIFER", ylab = "NPP (g/cm^2/year)", outpch = NA, ylim = c(4000, 7000))
dev.off()

# map and stats for fri
png("map_biomass.png", width = 600, height = 400)
par(font.lab = 2, font.axis = 2, family = "mono", ps = 14, mar = c(0.5,0.5,0.5,0.5), oma = c(0,0,0,0), lty = 1, mfrow = c(1,1), lwd = 2)
pal <- colorRampPalette(c("blue", "green", "yellow", "red"))
image.plot(rot90(matrix(stats$biomass, nrow = 187, ncol = 200, byrow = TRUE), k = 3), axes = FALSE, ann = FALSE, col = pal(255), horizontal = FALSE)
dev.off()
summary(fri$AGE)
summary(fri$WG)
summary(fri$SC)
summary(fri$STKG)
summary(fri$VOL)

# maps and stats for evi & ndvi
png("plot_evi_ndvi.png", width = 800, height = 300)
par(font.lab = 2, font.axis = 2, family = "mono", ps = 14, mar = c(0,0,0,6), oma = c(0,0,0,0), lty = 1, mfrow = c(1,2), lwd = 2)
pal <- colorRampPalette(c("blue", "green", "yellow", "red"))
image.plot(rot90(matrix(stats$evi, nrow = 187, ncol = 200, byrow = TRUE), k = 3), axes = FALSE, ann = FALSE, col = pal(255), horizontal = FALSE, main = "GROWING SEASON EVI", zlim = c(0,1))
image.plot(rot90(matrix(stats$ndvi, nrow = 187, ncol = 200, byrow = TRUE), k = 3), axes = FALSE, ann = FALSE, col = pal(255), horizontal = FALSE, main = "GROWING SEASON NDVI", zlim = c(0,1))
dev.off()
summary(stats$evi)
summary(stats$ndvi)

# histogram for evi & ndvi
png("hist_evi_ndvi.png", width = 800, height = 300)
par(font.lab = 2, font.axis = 2, family = "mono", ps = 14, mar = c(4,4,1,1), oma = c(0,0,0,0), lty = 1, mfrow = c(1,2), lwd = 2)
hist(stats$evi, xlab = "GROWING SEASON EVI", ylab = "FREQUENCY", xlim = c(0,1), main = NULL, ylim = c(0,13000))
box()
hist(stats$ndvi, xlab = "GROWING SEASON NDVI", ylab = "FREQUENCY", xlim = c(0,1), main = NULL, ylim = c(0,13000))
box()
dev.off()

# plot evi against ndvi
#samp <- sample(length(stats$ndvi), 100)
#plot(stats$ndvi[samp], stats$evi[samp], xlab = "NDVI", ylab = "EVI", main = "EVI VS NDVI")
#abline(lm(stats$evi[samp]~stats$ndvi[samp]), lty = 2)

# find pixel-by-pixel correlation coefficients for biomass and evi/ndvi
cor(stats$evi,stats$ndvi, method = "pearson")
cor(stats$ndvi,stats$biomass, method = "pearson")
cor(stats$evi,stats$biomass, method = "pearson")

# map neighborhoods
png("plot_b.png", width = 800, height = 300)
par(font.lab = 2, font.axis = 2, family = "mono", ps = 14, mar = c(0.5,0.5,0.5,0.5), oma = c(0,0,0,0), lty = 1, mfrow = c(2,5), lwd = 2)
image(rot90(matrix(hood$b3, nrow = 187, ncol = 200, byrow = TRUE), k = 3), axes = FALSE, ann = FALSE, col = heat.colors(255))
image(rot90(matrix(hood$b13, nrow = 187, ncol = 200, byrow = TRUE), k = 3), axes = FALSE, ann = FALSE, col = heat.colors(255))
image(rot90(matrix(hood$b23, nrow = 187, ncol = 200, byrow = TRUE), k = 3), axes = FALSE, ann = FALSE, col = heat.colors(255))
image(rot90(matrix(hood$b33, nrow = 187, ncol = 200, byrow = TRUE), k = 3), axes = FALSE, ann = FALSE, col = heat.colors(255))
image(rot90(matrix(hood$b43, nrow = 187, ncol = 200, byrow = TRUE), k = 3), axes = FALSE, ann = FALSE, col = heat.colors(255))
image(rot90(matrix(hood$b53, nrow = 187, ncol = 200, byrow = TRUE), k = 3), axes = FALSE, ann = FALSE, col = heat.colors(255))
image(rot90(matrix(hood$b63, nrow = 187, ncol = 200, byrow = TRUE), k = 3), axes = FALSE, ann = FALSE, col = heat.colors(255))
image(rot90(matrix(hood$b73, nrow = 187, ncol = 200, byrow = TRUE), k = 3), axes = FALSE, ann = FALSE, col = heat.colors(255))
image(rot90(matrix(hood$b83, nrow = 187, ncol = 200, byrow = TRUE), k = 3), axes = FALSE, ann = FALSE, col = heat.colors(255))
image(rot90(matrix(hood$b93, nrow = 187, ncol = 200, byrow = TRUE), k = 3), axes = FALSE, ann = FALSE, col = heat.colors(255))
dev.off()

png("plot_e.png", width = 800, height = 300)
par(font.lab = 2, font.axis = 2, family = "mono", ps = 14, mar = c(0.5,0.5,0.5,0.5), oma = c(0,0,0,0), lty = 1, mfrow = c(2,5), lwd = 2)
image(rot90(matrix(hood$e3, nrow = 187, ncol = 200, byrow = TRUE), k = 3), axes = FALSE, ann = FALSE, col = heat.colors(255))
image(rot90(matrix(hood$e13, nrow = 187, ncol = 200, byrow = TRUE), k = 3), axes = FALSE, ann = FALSE, col = heat.colors(255))
image(rot90(matrix(hood$e23, nrow = 187, ncol = 200, byrow = TRUE), k = 3), axes = FALSE, ann = FALSE, col = heat.colors(255))
image(rot90(matrix(hood$e33, nrow = 187, ncol = 200, byrow = TRUE), k = 3), axes = FALSE, ann = FALSE, col = heat.colors(255))
image(rot90(matrix(hood$e43, nrow = 187, ncol = 200, byrow = TRUE), k = 3), axes = FALSE, ann = FALSE, col = heat.colors(255))
image(rot90(matrix(hood$e53, nrow = 187, ncol = 200, byrow = TRUE), k = 3), axes = FALSE, ann = FALSE, col = heat.colors(255))
image(rot90(matrix(hood$e63, nrow = 187, ncol = 200, byrow = TRUE), k = 3), axes = FALSE, ann = FALSE, col = heat.colors(255))
image(rot90(matrix(hood$e73, nrow = 187, ncol = 200, byrow = TRUE), k = 3), axes = FALSE, ann = FALSE, col = heat.colors(255))
image(rot90(matrix(hood$e83, nrow = 187, ncol = 200, byrow = TRUE), k = 3), axes = FALSE, ann = FALSE, col = heat.colors(255))
image(rot90(matrix(hood$e93, nrow = 187, ncol = 200, byrow = TRUE), k = 3), axes = FALSE, ann = FALSE, col = heat.colors(255))
dev.off()

png("plot_n.png", width = 800, height = 300)
par(font.lab = 2, font.axis = 2, family = "mono", ps = 14, mar = c(0.5,0.5,0.5,0.5), oma = c(0,0,0,0), lty = 1, mfrow = c(2,5), lwd = 2)
image(rot90(matrix(hood$n3, nrow = 187, ncol = 200, byrow = TRUE), k = 3), axes = FALSE, ann = FALSE, col = heat.colors(255))
image(rot90(matrix(hood$n13, nrow = 187, ncol = 200, byrow = TRUE), k = 3), axes = FALSE, ann = FALSE, col = heat.colors(255))
image(rot90(matrix(hood$n23, nrow = 187, ncol = 200, byrow = TRUE), k = 3), axes = FALSE, ann = FALSE, col = heat.colors(255))
image(rot90(matrix(hood$n33, nrow = 187, ncol = 200, byrow = TRUE), k = 3), axes = FALSE, ann = FALSE, col = heat.colors(255))
image(rot90(matrix(hood$n43, nrow = 187, ncol = 200, byrow = TRUE), k = 3), axes = FALSE, ann = FALSE, col = heat.colors(255))
image(rot90(matrix(hood$n53, nrow = 187, ncol = 200, byrow = TRUE), k = 3), axes = FALSE, ann = FALSE, col = heat.colors(255))
image(rot90(matrix(hood$n63, nrow = 187, ncol = 200, byrow = TRUE), k = 3), axes = FALSE, ann = FALSE, col = heat.colors(255))
image(rot90(matrix(hood$n73, nrow = 187, ncol = 200, byrow = TRUE), k = 3), axes = FALSE, ann = FALSE, col = heat.colors(255))
image(rot90(matrix(hood$n83, nrow = 187, ncol = 200, byrow = TRUE), k = 3), axes = FALSE, ann = FALSE, col = heat.colors(255))
image(rot90(matrix(hood$n93, nrow = 187, ncol = 200, byrow = TRUE), k = 3), axes = FALSE, ann = FALSE, col = heat.colors(255))
dev.off()

# get stats for optimal vs non-optimal areas (e.g. 93)
png("box_optimal.png", width = 800, height = 400)
par(font.lab = 2, font.axis = 2, family = "mono", ps = 14, mar = c(5,5,5,1), oma = c(0,0,0,0), lty = 1, mfrow = c(1,4), lwd = 2)
boxplot(opt$bo93[which(!is.na(opt$bo93))], xlab = "OPTIMAL", ylab = "BIOMASS", outpch = NA, ylim = c(0,5), range = 0.75)
boxplot(opt$eo93[which(!is.na(opt$eo93))], xlab = "EVI", ylab = "BIOMASS", outpch = NA, ylim = c(0,5), range = 0.75)
boxplot(opt$no93[which(!is.na(opt$no93))], xlab = "NDVI", ylab = "BIOMASS", outpch = NA, ylim = c(0,5), range = 0.75)
boxplot(opt$biomass[which(is.na(opt$bo93))], xlab = "NON-OPTIMAL", ylab = "BIOMASS", outpch = NA, ylim = c(0,5), range = 0.75)
dev.off()
summary(opt$bo3[which(!is.na(opt$bo3))])
summary(opt$eo3[which(!is.na(opt$eo3))])
summary(opt$no3[which(!is.na(opt$no3))])
summary(opt$biomass[which(is.na(opt$bo3))])

# get total biomass for optimal areas (e.g. 3, 43, 93)
c(sum(opt$bo3[which(!is.na(opt$bo3))]), sum(opt$bo43[which(!is.na(opt$bo43))]), sum(opt$bo93[which(!is.na(opt$bo93))]))
c(sum(opt$eo3[which(!is.na(opt$eo3))]), sum(opt$eo43[which(!is.na(opt$eo43))]), sum(opt$eo93[which(!is.na(opt$eo93))]))
c(sum(opt$no3[which(!is.na(opt$no3))]), sum(opt$no43[which(!is.na(opt$no43))]), sum(opt$no93[which(!is.na(opt$no93))]))

# get total biomass for non-optimal areas (assuming equivalent area size)
sum(opt$biomass[sample(which(is.na(opt$bo93)), 9350)])
sum(opt$biomass[sample(which(is.na(opt$eo93)), 9349)])
sum(opt$biomass[sample(which(is.na(opt$no93)), 9351)])

