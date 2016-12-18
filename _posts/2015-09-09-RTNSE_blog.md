---
layout: single
title: "Messing with T-Distributed Stochastic Neighbor Embedding"
categories: [Data visualisation]
tags: [ggplot2, Rtsne, Statistic]
date: 2015-09-14
excerpt: Exemple of use of TSNE to create astonishing graphs
teaser: assets/images/rtnse.png
---

Recently, Kaggle launch the scripts project, which is a board of scripts released by competitioners with possibilites of evaluations by peers.

One of the script is a scatterplot obtained through t-distributed stochastic neighbor embedding which summarise the information of a huge data set.

The scatterplot was so self explaining that I wanted to explore that method.

<h3> Theory </h3>

The theory is not that complicated after you get the concept of the idea behind.
The original paper is [this one](http://jmlr.org/papers/volume9/vandermaaten08a/vandermaaten08a.pdf).

t-SNE is mainly used to visualise huge data set into scatterplot. It reduces the dimensionality of data to 2 or 3 dimensions, allowing to do 2d or 3d plot.

t-SNE converts distances between datapoint in the original space into conditionnal probabilities $p_{j|i}$.

$$p_{j|i} = \frac{\exp{(-d(\boldsymbol{x}_i, \boldsymbol{x}_j) / (2 \sigma_i^2)})}{\sum_{i \neq k} \exp{(-d(\boldsymbol{x}_i, \boldsymbol{x}_k) / (2 \sigma_i^2)})}, \quad p_{i|i} = 0,$$

$\sigma_i$ is the variance of the gaussian which is centered on $\boldsymbol{x}_i$. The `perplexity` parameter of the algorithm can influence this value.

If two points are close, $p_{j|i}$ will be high. If two points are far, $p_{j|i}$ will be low.

The conditionnal probabilities are used to define the joint probabilities: 
$$p_{ij} = \frac{p_{j|i} + p_{i|j}}{2N}.$$

The distances in the embedded space could be described the same way:

$$q_{ij} = \frac{(1 + ||\boldsymbol{y}_i - \boldsymbol{y}_j)||^2)^{-1}}{\sum_{k \neq l} (1 + ||\boldsymbol{y}_k - \boldsymbol{y}_l)||^2)^{-1}},$$

The idea now is, for a good visualisation in the embedded space, $q_{ij}$ and $p_{ij}$ should be equal.

The Kullback-Leibler divergence is the measure used to calculate the mismatch between $q_{ij}$ and $p_{ij}$.

$$KL(P|Q) = \sum_{i \neq j} p_{ij} \log \frac{p_{ij}}{q_{ij}}$$

A gradient descent is used to minimise this mismatch.

<h3> The function </h3>

The package `Rtsne` have one function, ` Rtsne()`. To note:

<ul style = "square">
<li> The function does not allow duplicates</li>
<li> The SNE result is fairly robust to change in perplexity. Classic values are between 5 and 50 </li>
<li> By defaut, an initial pca is made to reduce the number of dimensions before the SNE is done. </li>
<li> There is no normalisation made. Consequently, a variable with huge value will appear well separated. </li>
<li> The algorithm accept only numeric variables.</li>
<ul style = "circle">
<li> Consequently, I personnaly like to divide my dummie variable by the number of modality. </li>
<li> When I want a specific variable to appear well organised, I increase artificially the value. </li>
</ul>
</ul>

<h3> Exemple </h3>

Libraries used:


{% highlight r %}
library(data.table)
library(ggplot2)
library(Rtsne)
{% endhighlight %}



<h4> Diamond data set </h4>


{% highlight r %}
# data table format:
diamonds.dt <- data.table(diamonds)

# We transform ordinal variable into numeric one:
diamonds.dt[, cut2 := as.numeric(cut)]
diamonds.dt[, clarity2 := as.numeric(clarity)]
diamonds.dt[, color2 := as.numeric(color)]

# Normalization of each variable:
diamonds.dt2 <- diamonds.dt[, list(lapply(.SD, function(x) (x - min(x) ) / (max(x) - min(x))), color, cut, clarity), .SDcols = c("carat", "cut2", "color2", "clarity2", "depth", "table", "price", "x", "y", "z")]

# deduplication:
diamonds.dt3 <- diamonds.dt2[, list(count = .N), by = c("carat", "cut2", "color2", "clarity2", "depth", "table", "price", "x", "y", "z", "cut", "color", "clarity")]

diamonds.dt4 <-  diamonds.dt3[, c("carat", "cut2", "color2", "clarity2", "depth", "table", "price", "x", "y", "z"), with = F]

# Embedding the data set:
diamonds.2d <- Rtsne(diamonds.dt4, dims = 2, initial_dims = 50, perplexity = 30, max_iter = 600, verbose = T)
save(diamonds.2d, file = "./DATA/diamonds_2d.rdata")

diamonds.dt3[, x.rtsne := diamonds.2d$Y[, 1]]
diamonds.dt3[, y.rtsne := diamonds.2d$Y[, 2]]
{% endhighlight %}




{% highlight r %}
# colorless
ggplot(data = diamonds.dt4, aes(x = x.rtsne, y = y.rtsne)) +
  geom_point(color = "black") +
  ggtitle("Raw plot")
{% endhighlight %}

![plot of chunk unnamed-chunk-5](http://data-laborer.eu/blog_dev_mm/assets/images/figures/source/2015-09-09-RTNSE_blog/unnamed-chunk-5-1.png)

{% highlight r %}
# clarity
ggplot(data = diamonds.dt4, aes(x = x.rtsne, y = y.rtsne, color = as.factor(clarity2)))+
  geom_point() +   theme_classic() +  ggtitle("Clarity")
{% endhighlight %}

![plot of chunk unnamed-chunk-5](http://data-laborer.eu/blog_dev_mm/assets/images/figures/source/2015-09-09-RTNSE_blog/unnamed-chunk-5-2.png)

{% highlight r %}
# cut
ggplot(data = diamonds.dt4, aes(x = x.rtsne, y = y.rtsne, color = as.factor(cut2))) +
  geom_point() +   theme_classic() +  ggtitle("Cut")
{% endhighlight %}

![plot of chunk unnamed-chunk-5](http://data-laborer.eu/blog_dev_mm/assets/images/figures/source/2015-09-09-RTNSE_blog/unnamed-chunk-5-3.png)

{% highlight r %}
# price
ggplot(data = diamonds.dt4, aes(x = x.rtsne, y = y.rtsne, color = price)) +
  geom_point() +   theme_classic() +  ggtitle("Price")
{% endhighlight %}

![plot of chunk unnamed-chunk-5](http://data-laborer.eu/blog_dev_mm/assets/images/figures/source/2015-09-09-RTNSE_blog/unnamed-chunk-5-4.png)

{% highlight r %}
# color
ggplot(data = diamonds.dt4, aes(x = x.rtsne, y = y.rtsne, color = as.factor(color2))) +
  geom_point() +   theme_classic() +  ggtitle("Color")
{% endhighlight %}

![plot of chunk unnamed-chunk-5](http://data-laborer.eu/blog_dev_mm/assets/images/figures/source/2015-09-09-RTNSE_blog/unnamed-chunk-5-5.png)

{% highlight r %}
# carat
ggplot(data = diamonds.dt4, aes(x = x.rtsne, y = y.rtsne, color = carat)) +
  geom_point() +   theme_classic() +  ggtitle("Carat")
{% endhighlight %}

![plot of chunk unnamed-chunk-5](http://data-laborer.eu/blog_dev_mm/assets/images/figures/source/2015-09-09-RTNSE_blog/unnamed-chunk-5-6.png)

{% highlight r %}
# x
ggplot(data = diamonds.dt4, aes(x = x.rtsne, y = y.rtsne, color = x)) +
  geom_point() +   theme_classic() +  ggtitle("X")
{% endhighlight %}

![plot of chunk unnamed-chunk-5](http://data-laborer.eu/blog_dev_mm/assets/images/figures/source/2015-09-09-RTNSE_blog/unnamed-chunk-5-7.png)

{% highlight r %}
# y
ggplot(data = diamonds.dt4, aes(x = x.rtsne, y = y.rtsne, color = y)) +
  geom_point() +   theme_classic() +  ggtitle("Y")
{% endhighlight %}

![plot of chunk unnamed-chunk-5](http://data-laborer.eu/blog_dev_mm/assets/images/figures/source/2015-09-09-RTNSE_blog/unnamed-chunk-5-8.png)

{% highlight r %}
# z
ggplot(data = diamonds.dt4, aes(x = x.rtsne, y = y.rtsne, color = z)) +
  geom_point() +   theme_classic() +  ggtitle("Z")
{% endhighlight %}

![plot of chunk unnamed-chunk-5](http://data-laborer.eu/blog_dev_mm/assets/images/figures/source/2015-09-09-RTNSE_blog/unnamed-chunk-5-9.png)

{% highlight r %}
# depth
ggplot(data = diamonds.dt4, aes(x = x.rtsne, y = y.rtsne, color = depth)) +
  geom_point() +   theme_classic() +  ggtitle("Depth")
{% endhighlight %}

![plot of chunk unnamed-chunk-5](http://data-laborer.eu/blog_dev_mm/assets/images/figures/source/2015-09-09-RTNSE_blog/unnamed-chunk-5-10.png)

<h4> Titanic data set </h4>

The goal in the titanic data set is to predict the Survivor.
Here, we will try to plot the 2D representation of the data set without using the Survivor variable. If the final graph separate the Survivors from the non survivors, it is possible to analyse the variables to use in the survival model.

It is possible to influence the graph weighting the variable used.


{% highlight r %}
# read the data:
setwd("C:/blog/gen")
titanic.train <- fread("./data/train_rtnse.csv")

# get read of qualitative variables. The dummies variable of the Embarked variable are weighted to count for 1 in the count of the variables:
titanic.train[, flg.M := ifelse(Sex == "male", 1, 0)]
titanic.train[, flg.emb.s := ifelse(Embarked == "S", 1/3, 0)]
titanic.train[, flg.emb.c := ifelse(Embarked == "C", 1/3, 0)]
titanic.train[, flg.emb.q := ifelse(Embarked == "Q", 1/3, 0)]

# get read of duplicate values:
titanic.train2 <- titanic.train[, list(count = .N, Survived2 = mean(Survived)), by = list(Pclass, flg.M, flg.emb.s, flg.emb.c, flg.emb.q, Age, SibSp, Parch, Fare, Embarked)]

# get read of missing values and normalisation:
titanic.train2[, Age := ifelse(is.na(Age), -1, (Age-min(Age, na.rm = T))/(max(Age, na.rm = T)-min(Age, na.rm = T)))]
titanic.train2[, Pclass := (Pclass-min(Pclass))/(max(Pclass)-min(Pclass))]
titanic.train2[, Pclass := (Pclass-min(Pclass))/(max(Pclass)-min(Pclass))]
titanic.train2[, Fare := ifelse(Fare == 0, 0, log(Fare)/max(log(Fare)))]
titanic.train2[, SibSp := (SibSp-min(SibSp))/(max(SibSp)-min(SibSp))]
{% endhighlight %}

With a huge table, the function could take a while. 


{% highlight r %}
res.rtnse <- Rtsne(titanic.train2[, list(Pclass, flg.M, flg.emb.s, flg.emb.c, flg.emb.q, Age, SibSp, Parch, Fare, count)], dims = 2, verbose = T, perplexity = 30, max_iter = 1000)
titanic.train2[, x.rtsne := res.rtnse$Y[, 1]]
titanic.train2[, y.rtsne := res.rtnse$Y[, 2]]
{% endhighlight %}




{% highlight r %}
# Raw plot:
ggplot(data = titanic.train2, aes(x = x.rtsne, y = y.rtsne)) +
  geom_point() +   theme_classic() +  ggtitle("Raw graph")
{% endhighlight %}

![plot of chunk unnamed-chunk-9](http://data-laborer.eu/blog_dev_mm/assets/images/figures/source/2015-09-09-RTNSE_blog/unnamed-chunk-9-1.png)

The 2D representation create clusters easily identifiable. Now, the question is: does these clusters make sense looking at the survivor variable.


{% highlight r %}
# Survived:
ggplot(data = titanic.train2, aes(x = x.rtsne, y = y.rtsne, color = Survived2))  +
  geom_point() +   theme_classic() +  ggtitle("Survivors")
{% endhighlight %}

![plot of chunk unnamed-chunk-10](http://data-laborer.eu/blog_dev_mm/assets/images/figures/source/2015-09-09-RTNSE_blog/unnamed-chunk-10-1.png)

The survivors are not that well separated, but we could see a few groups which are well defined.


{% highlight r %}
# Age
ggplot(data = titanic.train2, aes(x = x.rtsne, y = y.rtsne, color = Age)) +
  geom_point() +   theme_classic() +  ggtitle("Age")
{% endhighlight %}

![plot of chunk unnamed-chunk-11](http://data-laborer.eu/blog_dev_mm/assets/images/figures/source/2015-09-09-RTNSE_blog/unnamed-chunk-11-1.png)

{% highlight r %}
# Pclass
ggplot(data = titanic.train2, aes(x = x.rtsne, y = y.rtsne, color = as.factor(Pclass))) +
  geom_point() +   theme_classic() +  ggtitle("Class")
{% endhighlight %}

![plot of chunk unnamed-chunk-11](http://data-laborer.eu/blog_dev_mm/assets/images/figures/source/2015-09-09-RTNSE_blog/unnamed-chunk-11-2.png)

{% highlight r %}
# Sex
ggplot(data = titanic.train2, aes(x = x.rtsne, y = y.rtsne, color = as.factor(flg.M))) +
  geom_point() +   theme_classic() +  ggtitle("Sex")
{% endhighlight %}

![plot of chunk unnamed-chunk-11](http://data-laborer.eu/blog_dev_mm/assets/images/figures/source/2015-09-09-RTNSE_blog/unnamed-chunk-11-3.png)

{% highlight r %}
# Parch
ggplot(data = titanic.train2, aes(x = x.rtsne, y = y.rtsne, color = Parch))  +
  geom_point() +   theme_classic() +  ggtitle("Number of Parents/Children Aboard")
{% endhighlight %}

![plot of chunk unnamed-chunk-11](http://data-laborer.eu/blog_dev_mm/assets/images/figures/source/2015-09-09-RTNSE_blog/unnamed-chunk-11-4.png)

{% highlight r %}
# Fare
ggplot(data = titanic.train2, aes(x = x.rtsne, y = y.rtsne, color = Fare))  +
  geom_point() +   theme_classic() +  ggtitle("Fare")
{% endhighlight %}

![plot of chunk unnamed-chunk-11](http://data-laborer.eu/blog_dev_mm/assets/images/figures/source/2015-09-09-RTNSE_blog/unnamed-chunk-11-5.png)

{% highlight r %}
# SibSp
ggplot(data = titanic.train2, aes(x = x.rtsne, y = y.rtsne, color = SibSp))  +
  geom_point() +   theme_classic() +  ggtitle("Number of Siblings/Spouses Aboard")
{% endhighlight %}

![plot of chunk unnamed-chunk-11](http://data-laborer.eu/blog_dev_mm/assets/images/figures/source/2015-09-09-RTNSE_blog/unnamed-chunk-11-6.png)

{% highlight r %}
# flg.emb.s
ggplot(data = titanic.train2, aes(x = x.rtsne, y = y.rtsne, color = flg.emb.s)) +
  geom_point() +   theme_classic() +  ggtitle("Embarkation at Southampton")
{% endhighlight %}

![plot of chunk unnamed-chunk-11](http://data-laborer.eu/blog_dev_mm/assets/images/figures/source/2015-09-09-RTNSE_blog/unnamed-chunk-11-7.png)

{% highlight r %}
# flg.emb.c
ggplot(data = titanic.train2, aes(x = x.rtsne, y = y.rtsne, color = flg.emb.c))  +
  geom_point() +   theme_classic() +  ggtitle("Embarkation at Cherbourg")
{% endhighlight %}

![plot of chunk unnamed-chunk-11](http://data-laborer.eu/blog_dev_mm/assets/images/figures/source/2015-09-09-RTNSE_blog/unnamed-chunk-11-8.png)

{% highlight r %}
# flg.emb.q
ggplot(data = titanic.train2, aes(x = x.rtsne, y = y.rtsne, color = flg.emb.q))  +
  geom_point() +   theme_classic() +  ggtitle("Embarkation at Queenstown")
{% endhighlight %}

![plot of chunk unnamed-chunk-11](http://data-laborer.eu/blog_dev_mm/assets/images/figures/source/2015-09-09-RTNSE_blog/unnamed-chunk-11-9.png)
