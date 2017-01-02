---
layout: single
title: "August Coding Dojo: Choosing the Optimal Number of Cluster"
categories: [Statistic]
tags: [Clustering, ggplot2, NbClust, R]
date: 2015-08-18
excerpt: How to automatically define the optimal number of cluster when doing clustering?
teaser: assets/images/Final_factor.png
---

At the last coding dojo, the interrogation we get was the following:
Is it possible to create a function which automatically define the optimal number of cluster?
As usual, the answer with R is: there is a package for that.

<h2> Training data set </h2>

First, we generate some fake data:
Not too much separated, but not too messy. It is a simulation, not real life :)


{% highlight r %}
library(ggplot2)

sd <- 30

mat = data.frame(x =c(seq(1,10),seq(100,120),seq(10:30)) + rnorm(52, 0, sd), 
                 y = c(seq(1,10),seq(100,120),seq(300,320))+ rnorm(52, 0, sd)
                 , c = c(rep("a", 10), rep("b", 21), rep("c", 21)))

ggplot(data = mat, aes(x = x, y = y)) +
    geom_point( size = 4) 
{% endhighlight %}

![plot of chunk unnamed-chunk-1](http://data-laborer.eu/assets/images/figures/source/2015-08-18-Number_of_Cluster/unnamed-chunk-1-1.png)



<h2> Analysis </h2>

<h3> Elbow plot </h3>

Our main inspiration is that post on stackoverflow:

[http://stackoverflow.com/questions/15376075/cluster-analysis-in-r-determine-the-optimal-number-of-clusters](http://stackoverflow.com/questions/15376075/cluster-analysis-in-r-determine-the-optimal-number-of-clusters)

And the help of the Nbclust package.



The first way to determine a reasonnable number of cluster that was taught at school was the elbow plot.
The concept is to plot the sum of the distance between the centroid of the cluster and the point of the cluster by cluster.

The plot looks like an elbow and the classic rule is to take the number of cluster where the curve begin to flaten. Afterward, each new cluster is not really separated from the others.

Elbow plot:


{% highlight r %}
wss <- (nrow(mat)-1)*sum(apply(mat[, -3],2,var))
  for (i in 2:15) wss[i] <- sum(kmeans(mat[, -3],
                                       centers=i)$withinss)

wss2 <- data.frame(x = 1:15, wss = wss)

ggplot(data = wss2, aes(x = x, y = wss))+
    geom_point(size = 4) +
  geom_line() +
  scale_x_continuous(breaks = 1:15) +
  ggtitle("Elbow plot")
{% endhighlight %}

![plot of chunk unnamed-chunk-4](http://data-laborer.eu/assets/images/figures/source/2015-08-18-Number_of_Cluster/unnamed-chunk-4-1.png)



<h3> The function NbClust </h3>

The function NbClust test a consequent set of methods to determine the optimal number of clusters.


{% highlight r %}
res <- NbClust(mat[, -3], diss=NULL, distance = "euclidean", min.nc=2, max.nc=6, 
             method = "kmeans", index = "all")
{% endhighlight %}



The different method used (minus the graphical ones) and the number of clusters picked by each:


{% highlight r %}
res$Best.nc
{% endhighlight %}



{% highlight text %}
##                     KL       CH Hartigan     CCC   Scott     Marriot
## Number_clusters 6.0000   3.0000   3.0000  4.0000  3.0000           3
## Value_Index     8.6036 203.1305  47.3718 11.3789 60.6216 17931349382
##                    TrCovW   TraceW Friedman   Rubin Cindex     DB
## Number_clusters         5      3.0   6.0000  3.0000 4.0000 2.0000
## Value_Index     487603408 104947.3  55.2264 -8.2026 0.3001 0.5097
##                 Silhouette   Duda PseudoT2  Beale Ratkowsky     Ball
## Number_clusters     2.0000 2.0000   2.0000 2.0000    3.0000     3.00
## Value_Index         0.6769 0.3023  66.9214 2.2307    0.5298 79448.65
##                 PtBiserial   Frey McClain   Dunn Hubert SDindex Dindex
## Number_clusters     2.0000 3.0000  2.0000 2.0000      0  2.0000      0
## Value_Index         0.8549 5.5349  0.3181 0.4451      0  0.0163      0
##                   SDbw
## Number_clusters 6.0000
## Value_Index     0.1088
{% endhighlight %}

Most common value:(Without 0)


{% highlight r %}
summary(res$Best.nc[1,][res$Best.nc[1,]!= 0])
{% endhighlight %}



{% highlight text %}
##    Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
##   2.000   2.000   3.000   3.167   3.250   6.000
{% endhighlight %}

In the end, the median of all these methods is choosed. In this case, 2.

<h2> Result </h2>

The plot:


{% highlight r %}
mat$res <- res$Best.partition

ggplot(data = mat, aes(x = x, y = y, colour = factor(res))) +
    geom_point( size = 4)
{% endhighlight %}

![plot of chunk unnamed-chunk-10](http://data-laborer.eu/assets/images/figures/source/2015-08-18-Number_of_Cluster/unnamed-chunk-10-1.png)





There is another approach we didn't had time to look at, but which seems promising:
The package BHC which does bayesian hierarchical clustering could also provide us an insight on the best cluster.
