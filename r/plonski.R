### create plonski data ###
library("foreign")
rm(list = ls())

# import data
plonski <- read.csv("plonski2.csv", as.is = TRUE, na.strings = "-")
fri <- read.dbf("forClip2.dbf")

# reclass
plonskiPar <- vector(length = length(plonski$id))
for(a in 1:length(plonski$id)){
	plonskiPar[a] <- paste(plonski$id[a], plonski$sc[a], sep = ",")
}

sc <- fri$SC
for(a in 1:length(fri$SC)){
        if(fri$SC[a] == 0) sc[a] <- 1
        else if(fri$SC[a] == 4) sc[a] <- 3
}

wg <- vector(length = length(fri$WG))
for(a in 1:length(fri$WG)){
	if(fri$WG[a] == "Ab" || fri$WG[a] == "AX" || fri$WG[a] == "MR" || fri$WG[a] == "PO") wg[a] <- "toleranthard"
	else if(fri$WG[a] == "BF" || fri$WG[a] == "CE" || fri$WG[a] == "LA" || fri$WG[a] == "PJ" || fri$WG[a] == "SW") wg[a] <- "jackpine"
	else if(fri$WG[a] == "BW") wg[a] <- "whitebirch"
	else if(fri$WG[a] == "PR") wg[a] <- "redpine"
	else if(fri$WG[a] == "PW") wg[a] <- "whitepine"
	else if(fri$WG[a] == "SB") wg[a] <- "spruce"
}

ht <- vector(length = length(fri$HT))
for(a in 1:length(fri$HT)){
	b <- which(plonski$sc %in% sc[a])
	c <- which(plonski$id %in% wg[a])
	d <- intersect(b, c)
	ht[a] <- plonski$ht[d[which.min(abs(plonski$ht[d] - fri$HT[a]))]]
}	

age <- vector(length = length(fri$AGE))
for(a in 1:length(fri$AGE)){
        b <- which(plonski$sc %in% sc[a])
        c <- which(plonski$id %in% wg[a])
        d <- intersect(b, c)
        age[a] <- plonski$age[d[which.min(abs(plonski$age[d] - fri$AGE[a]))]]
}

friPar <- vector(length = length(fri$RECNO))
for(a in 1:length(fri$RECNO)){
	friPar[a] <- paste(wg[a], sc[a], sep = ",")
}

# get merchantable volume
vol <- vector(mode = "list", length = length(fri$RECNO))
for(a in 1:length(fri$RECNO)){
	vol[[a]] <- plonski$merch[which(plonskiPar %in% friPar[a])]
}

# fill in vol data to specified age
volAge <- vector(mode = "list", length = length(vol))
for(a in 1:length(vol)){
	volAge[[a]] <- vol[[a]][1:500] # pick an arbitrarily large number to truncate later
	volAge[[a]][length(vol[[a]]):500] <- vol[[a]][length(vol[[a]])]
	volAge[[a]] <- volAge[[a]][1:200] # truncate to make export easier
}

# transform to matrix
volMat <- matrix(nrow = length(vol), ncol = length(volAge[[1]]))
for(a in 1:length(vol)){
	volMat[a,] <- volAge[[a]]
}
rownames(volMat) <- fri$RECNO
colnames(volMat) <- c(1:length(volAge[[1]]))
volFrame <- data.frame(volMat)
volFinal <- cbind(c(1:length(vol)), volFrame)

# export data
names(volFinal)[1] <- "cat"
write.dbf(volFinal, file = "plonskiAll.dbf")

# create dbf from joined fri and plonski data
#final <- read.csv("forClip2.csv", as.is = TRUE, na.strings = "-")
#final2 <- cbind(c(1:25522), final)
#names(final2)[1] <- "cat"
#write.dbf(final2, file = "friPlonski.dbf")

