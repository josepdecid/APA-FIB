#####################################
## APA Laboratori 3                ##
## Clustering                      ##
## version of October, 2017        ## 
#####################################

set.seed(222)
library(MASS)


####################################################################
# Example 1. Clustering easy artificial 2D data with k-means
####################################################################

## First we create a simple data set:

# the cclust library contains some clustering functions, including k-means
library (cclust)

N1 <- 30
N2 <- 40
N3 <- 50

# create cluster 1
x1 <- rnorm (N1,1,0.5)
y1 <- rnorm (N1,1,0.5)

# create cluster 2
x2 <- rnorm (N2,2,0.5)
y2 <- rnorm (N2,6,0.7)

# create cluster 3
x3 <- rnorm (N3,7,1)
y3 <- rnorm (N3,7,1)

# create the data
x <- rbind (cbind(x1,y1), cbind(x2,y2), cbind(x3,y3))
c <- c(rep("4", N1), rep("2", N2), rep("3", N3))
D <- data.frame (x,color=c)

## this is your data
plot(D$x1,D$y1)

## and these are the true clusters
plot(D$x1,D$y1,col=as.vector(D$color))

# so we have 3 very clean clusters ...

# Let's execute k-means

K <- 3 # yeah, this is tricky, why 3?

## execute k-means with a maximum of 100 iterations
# install.packages('cclust')
library('cclust')
kmeans.3 <- cclust (x,K,iter.max=100,method="kmeans",dist="euclidean")

## plot initial and final prototypes (cluster centers)
points(kmeans.3$initcenters, pch=19)
points(kmeans.3$centers, pch=19)

## draw arrows to see the process
arrows (kmeans.3$initcenters[,1], kmeans.3$initcenters[,2], kmeans.3$centers[,1], kmeans.3$centers[,2])

## plot and paint the clusters (according to the computed assignments)
plot(D$x1,D$y1,col=(kmeans.3$cluster+1))

## plot the cluster centers
points(kmeans.3$centers,col=seq(1:kmeans.3$ncenters)+1,cex=2,pch=19)

# clustering quality as measured by the Calinski-Harabasz index (recommended)
# This index measures the dispersion of the data points within the clusters (SSW) and between the clusters (SSB)
# A good clustering has small SSW (compact clusters) and large SSB (separated cluster centers)
# There is also a correction for the number of clusters

# The C-H index is then:

# SSB -> Sum of squares Between (Separated cluster centers +)
# DDW -> Sum of squares Within (Very compact clusters -)
# C-H = (SSB/(K-1)) / (SSW/(N-K))

# where N is the number of data points and K is the number of clusters

(CH.3 <- clustIndex(kmeans.3,x, index="calinski"))

## now let's not be tricky ##

K <- 5 # guess what is going to happen?

## execute k-means with a maximum of 100 iterations
kmeans.5 <- cclust (x,K,iter.max=100,method="kmeans",dist="euclidean")

## this is your data again
plot(D$x1,D$y1,col=as.vector(D$color))

## plot initial and final prototypes (centers)
points(kmeans.5$initcenters, pch=19)
points(kmeans.5$centers, pch=19)

## draw arrows to see the process
arrows (kmeans.5$initcenters[,1], kmeans.5$initcenters[,2], kmeans.5$centers[,1], kmeans.5$centers[,2])

## plot and paint the clusters (according to the computed assignments)
plot(D$x1,D$y1,col=(kmeans.5$cluster+1))

## plot the cluster centers
points(kmeans.5$centers,col=seq(1:kmeans.5$ncenters)+1,cex=2,pch=19)

# clustering quality as measured by the Calinski-Harabasz index

(CH.5 <- clustIndex(kmeans.5,x, index="calinski"))

# notice CH.3 > CH.5, so K=3 is better according to C-H

###########################################################################
# Example 2. Clustering not-so-easy artificial 2D data with k-means and E-M
###########################################################################

## the MASS library contains the multivariate gaussian
library(MASS)

## the ggplot2 library contains functions for making nice plots
library(ggplot2)

set.seed(333)

## First we need some auxiliary functions

# GENERATE DATA FROM A MIXTURE OF 2D GAUSSIANS
generate.data <- function(N, K, prior.mean, prior.var)
{
  p <- length(prior.mean)
  
  # generate random mixture centres from the prior
  mu_k <- mvrnorm(K, mu=prior.mean, Sigma=diag(prior.var, 2))
  
  # generate mixture coefficients
  pi_k <- runif(K)
  pi_k <- pi_k/sum(pi_k)
  
  # generate the data
  obs <- matrix(0, nrow=N, ncol=p)
  z <- numeric(N)
  sigma_k <- matrix(0, nrow=K, ncol=p)
  
  for (i in 1:K)
    sigma_k[i,] <- runif(p)
  
  for (i in 1:N)
  {
    # draw the observation from a component according to coefficient
    z[i] <- sample(1:K, 1, prob=pi_k)
    # draw the observation from the corresponding mixture location
    obs[i,] <- mvrnorm(1, mu=mu_k[z[i],], Sigma=diag(sigma_k[z[i],],p))
  }
  list(locs=mu_k, z=z, obs=obs, coefs=pi_k)
}

# plot 2d data from a mixture
plot.mixture <- function(locs, z, obs)
{
  stopifnot(dim(obs)[2]==2)
  z <- as.factor(z)
  df1 <- data.frame(x=obs[,1], y=obs[,2], z=z)
  df2 <- data.frame(x=locs[,1], y=locs[,2])
  p <- ggplot()
  p <- p + geom_point(data=df1, aes(x=x, y=y, colour=z), shape=16, size=2, alpha=0.75)
  p <- p + geom_point(data=df2, aes(x=x, y=y), shape=16, size=3)
  p <- p + theme(legend.position="none")
  p
}

# plot 2D data as a scatter plot
plot.data <- function(dat)
{
  stopifnot(dim(dat)[2]==2)
  df1 <- data.frame(x=dat[,1], y=dat[,2])
  p <- ggplot()
  p <- p + geom_point(data=df1, aes(x=x, y=y), size=2, alpha=0.75)
  p
}

## Let us generate the data

N <- 1000
K <- 5
centre <- c(0,0)
dispersion <- 10

## generate 2D data as a mixture of 5 Gaussians, each axis-aligned (therefore the two variables are independent)
## with different variances
## the centers and coefficients of the mixture are chosen randomly
d <- generate.data (N,K,centre,dispersion)

## these are the components of the mixture
plot.mixture(d$locs, d$z, d$obs)

## may be we want to have a look at the unconditional density p(x)

## compute 2D kernel density
z <- kde2d(d$obs[,1], d$obs[,2], n=50)

## some pretty colors
library(RColorBrewer)
colorets <- rev(brewer.pal(11, "RdYlBu"))

## this is the raw data (what the clustering method "sees")
plot(d$obs, xlab="x", ylab="y", pch=19, cex=.4)

## and this is a contour plot of the unconditional density 
contour(z, drawlabels=FALSE, nlevels=22, col=colorets, add=TRUE)
abline(h=mean(d$obs[,2]), v=mean(d$obs[,1]), lwd=2)

## a simpler way of plotting the data
plot.data(d$obs)


######################################
## let us try first with k-means (K=2)

K <- 2

kmeans2.2 <- cclust (d$obs,K,iter.max=100,method="kmeans",dist="euclidean")

plot(d$obs[,1],d$obs[,2],col=(kmeans2.2$cluster+1))
points(kmeans2.2$centers,col=seq(1:kmeans2.2$ncenters)+1,cex=2,pch=19)

## I recommend you maximize the plot window
## Can we be indulgent with the result? we know the truth is there are 5 clusters,
## So, is this a reasonable result if we ask for 2?

# clustering quality as measured by the Calinski-Harabasz index

(CH2.2 <- clustIndex(kmeans2.2,d$obs, index="calinski"))

## let us try now with k-means (K=5)

K <- 5

kmeans2.5 <- cclust (d$obs,K,iter.max=100,method="kmeans",dist="euclidean")

plot(d$obs[,1],d$obs[,2],col=(kmeans2.5$cluster+1))
points(kmeans2.5$centers,col=seq(1:kmeans2.5$ncenters)+1,cex=2,pch=19)

## I recommend you maximize the plot window
## This time the result has even more chances of being largely incorrect
## because there are more ways of getting a wrong solution

# clustering quality as measured by the Calinski-Harabasz index

(CH2.5 <- clustIndex(kmeans2.5,d$obs, index="calinski"))

# at least CH2.5 >> CH2.2 ... so C-H does a good job

## In class we saw that k-means is usually re-run several times

do.kmeans <- function (whatK)
{
  r <- cclust (d$obs,whatK,iter.max=100,method="kmeans",dist="euclidean")
  (clustIndex(r,d$obs, index="calinski"))
}

max (r <- replicate (100, do.kmeans(5)))

# so it is not a matter of wrong initialization
# this is really the best k-means can do here

# this may take a while for large datasets
res <- vector("numeric", 10)
for (K in 2:10)
  res[K] <- max (r <- replicate (100, do.kmeans(K)))

res[1] <- NA
plot(res, type="l", axes = FALSE, xlab="K", ylab="Calinski-Harabasz")

axis(side = 1, at = 2:10)
axis(side = 2, at = seq(0,5000,500))
grid(9, 6, lwd = 2)

## the conclusion is that k-means + C-H bet for 5 clusters ... 
## not bad, not bad ...

## but the real *shape* of the clusters cannot be captured, because k-means only "sees" spherical clusters and these are ellipsoidal

######################################
## let us try now E-M for MoGs

library(Rmixmod)

## This method performs E-M for mixture densities, including mixtures of Gaussians
## we can specify which family of gaussians we intend to fit:

## "general" for the general family, 
## "diagonal" for the diagonal family, 
## "spherical" for the spherical family 
## and "all" for all families (meaning the union)
## 
## WARNING: default is "general"

## suppose first that we know the truth and specify axis-aligned densities (i.e., independent variables)

fammodel <- mixmodGaussianModel (family="diagonal", equal.proportions=FALSE)

z <- mixmodCluster (data.frame(d$obs), models = fammodel, nbCluster = 5)

summary(z)

# the final centers
(means <- z@bestResult@parameters@mean)

# if you want "hard" assignments
(found.clusters <- z@bestResult@partition)

# other interesting outcomes are:

## the estimated covariance matrices for each cluster
(z@bestResult@parameters@variance)

## self-explained
(z@bestResult@likelihood)

## the posterior probabilities or "soft" assignments (the gamma_k(x_n) in class)
z@bestResult@proba

## Let's have a look at the first 5 data points:
z@bestResult@proba[1:5,]

## This is a graphical summary of the clustering

plot(d$obs[,1],d$obs[,2],col=(found.clusters+1))
points(means,col="black",cex=2,pch=19)

## It was very likely that E-M performed extremely well
## why? because we knew the truth (cluster form and number)

## Suppose now we do not know the truth, but we still wish to fit general gaussians

fammodel <- mixmodGaussianModel (family="general", equal.proportions=FALSE)

z <- mixmodCluster (data.frame(d$obs),models = fammodel, nbCluster = 5)

summary(z)

means <- z@bestResult@parameters@mean
found.clusters <- z@bestResult@partition

plot(d$obs[,1],d$obs[,2],col=(found.clusters+1))
points(means,col="black",cex=2,pch=19)

## the method works also very smoothly
## why? because we data *is* gaussian

## compare the estimated centers
means

# with the truth (note the clusters may appear in a different order)
d$locs

## or the estimated coefficients
sort(z@bestResult@parameters@proportions)

# with the truth 
sort(d$coefs)
