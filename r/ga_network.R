# steve's genetic algorithm

library("igraph") # load libraries
library("sma")
rm(list = ls(all = TRUE)) # remove old objects
g1 <- grg.game(15, 0.5) # create random graph
st <- 500 # strings
vc <- vcount(g1) # vertices
vi <- 3 # vertices of interest

random.string <- function(st){
	r1 <<- vector("list")
	v1 <- vector("list")
	v2 <- vector("list")
	for(a in 1:st){
		v1[[a]] <- rep(0, times = vc)
		v2[[a]] <- sample(vc, vi)
		for(b in 1:vi) v1[[a]][v2[[a]][b]] <- 1
	}
	r1 <<- v1
}

fitness.sum <- function(r1){
	v1 <- vector("list")
	v2 <- vector("list", length = vc - vi)
	v3 <- vector("list", length = vc - vi)
	for(a in 1:st){
		for(b in 1:(vc - vi)){
			v1[[b]] <- get.shortest.paths(g1, b - 1, which(r1[[a]] == 1) - 1)
			for(c in 1:vi) v2[[b]][[c]] <- length(v1[[b]][[c]])
			v3[[b]] <- min(v2[[b]])
		}
		names(r1)[[a]] <<- sum(unlist(v3))
	}
}

fitness.mean <- function(r1){
	v1 <- vector("list")
	v2 <- vector("list", length = vc - vi)
	v3 <- vector("list", length = vc - vi)
	for(a in 1:st){
		for(b in 1:(vc - vi)){
			v1[[b]] <- get.shortest.paths(g1, b - 1, which(r1[[a]] == 1) - 1)
			for(c in 1:vi) v2[[b]][[c]] <- length(v1[[b]][[c]])
			v3[[b]] <- min(v2[[b]])
		}
		names(r1)[[a]] <<- sum(unlist(v3)) / (vc - vi)
	}
}

fitness.max <- function(r1){
	v1 <- vector("list")
	v2 <- vector("list", length = vc - vi)
	v3 <- vector("list", length = vc - vi)
	for(a in 1:st){
		for(b in 1:(vc - vi)){
			v1[[b]] <- get.shortest.paths(g1, b - 1, which(r1[[a]] == 1) - 1)
			for(c in 1:vi) v2[[b]][[c]] <- length(v1[[b]][[c]])
			v3[[b]] <- min(v2[[b]])
		}
		names(r1)[[a]] <<- max(unlist(v3))
	}
}

fitness.min <- function(r1){
	v1 <- vector("list")
	v2 <- vector("list", length = vc - vi)
	v3 <- vector("list", length = vc - vi)
	for(a in 1:st){
		for(b in 1:(vc - vi)){
			v1[[b]] <- get.shortest.paths(g1, b - 1, which(r1[[a]] == 1) - 1)
			for(c in 1:vi) v2[[b]][[c]] <- length(v1[[b]][[c]])
			v3[[b]] <- min(v2[[b]])
		}
		names(r1)[[a]] <<- min(unlist(v3))
	}
}

fitness.rank <- function(r1){
	v1 <- sort(names(r1), index.return = TRUE)
	v2 <- vector("list")
	v2[[1]] <- v1[[2]][1:(length(r1) * 0.1)]
	v2[[3]] <- v1[[2]][((length(r1) * 0.9) + 1):length(r1)]
	names(r1) <<- rep(2, times = length(r1))
	names(r1)[v2[[1]]] <<- rep(1, times = length(v2[[1]]))
	names(r1)[v2[[3]]] <<- rep(3, times = length(v2[[3]]))
}

genetic.babymaking <- function(r1){
	v1 <- vector("list")
	v2 <- vector("list")
	v3 <- vector("list")
	for(a in which(names(r1) == 1)){ # keep top strings
		r1[[a]] <<- r1[[a]]
	}
	v1 <- r1[which(names(r1) == 2)] # breed middle strings
	for(b in 1:(length(v1) - 1)){
		v2[[b]] <- sample(unique(append(which(v1[[b]] == 1), which(v1[[b + 1]] == 1))), vi)
		v3[[b]] <- rep(0, times = vc)
		v3[[b]][v2[[b]]] <- 1
	}
	v2[[length(v1)]] <- sample(unique(append(which(v1[[b]] == 1), which(v1[[b + 1]] == 1))), vi) # promiscuous second-last string
	v3[[length(v1)]] <- rep(0, times = vc)
	v3[[length(v1)]][v2[[b + 1]]] <- 1
	r1[which(names(r1) == 2)] <<- v3

	for(d in which(names(r1) == 3)){ # randomize bottom strings
		v1[[d]] <- rep(0, times = vc)
		v2[[d]] <- sample(vc, vi)
		for(e in 1:3) v1[[d]][v2[[d]][e]] <- 1
		r1[[d]] <<- v1[[d]]
	}
}

genetic.mutate <- function(r1){
	v1 <- vector("list")
	v2 <- vector("list")
	for(a in sample(st, (st * 0.1))){
		v1[[a]] <- r1[[a]]
		v2[[a]] <- which(v1[[a]] == 1)
		v2[[a]] <- sample(unique(append(sample(vc, 1), v2[[a]])), 3)
		r1[[a]] <<- rep(0, times = vc)
		r1[[a]][v2[[a]]] <<- 1
	}
}

plot(g1)
random.string(st)
b <- vector()
c <- vector()
for(a in 1:100){
	fitness.min(r1)
	fitness.rank(r1)
	genetic.babymaking(r1)
	genetic.mutate(r1)
	fitness.sum(r1)
	b[a] <- sum(as.numeric(names(r1)))
	c[a] <- b[a] - b[a - 1]
	print(c(a, b[a], c[a]))
}
print(sum(c[2:a]))
print(min(c))

# reset default settings
# rm(list = ls(all = TRUE))
# sink()
