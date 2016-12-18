---
layout: single
title: "How to Choose your Electric Unicycle/Monowheel"
categories: []
tags: [R, pca, lm]
date: 2016-02-13
excerpt: Analytically pick the best product in a tense market 
teaser: assets/images/Session_technique_slalom_29_01_16.gif
---

I live in London. With the same issues as most of the londoners, aka, a huge commute time. The classic way to beat it is to take a bike or to wake up earlier.

Recently, I discovered another way to do it: the [electric unicycle/monowheel](http://www.theairwheel.com/). It's a green way to commute and energy efficient.

But as for any new product, there is not much reviews or feedback of the products. After a few time on the dedicated forums, I found [that spreadsheet](https://docs.google.com/spreadsheets/d/1Zv1_fAAL3xKCGDEv64Rg7jpeim4oytbMx8mmXKUFThQ/edit?pref=2&pli=1#gid=0 ). It was out of date so I created a new one with the new products and the correct prices( as of 18 déc. 2016).

The main parameter to take in account are the maximal speed, the weight, the autonomy and the price. The maximal speed should not be too low, but over 20 kph is useless. For the weight, the less weight is the better, as is the price (but bonus if it is made in UK). The autonomy is an important point as well, but I don't plan to do trip of more than two hours.






To get a first insight of what could be said on the internal properties of this product, I do a principal componant analysis.



![plot of chunk unnamed-chunk-4](http://data-laborer.eu/blog_dev_mm/assets/images/figures/source/2016-02-13-Unicycle_comparison/unnamed-chunk-4-1.png)

The first dimension separate the unicycles with high values of nearly all the variables from the unicycle with low values.

The second dimension is a little bit more interesting. It separates wheel and weight from price/autonomy/wh. As autonomy and wh are related to the battery, it may suggest that __most of the price of unicycles lies in the battery__.

Now that we know how the PCA separate the unicycle, let's have a look at the brand on these scales.


{% highlight r %}
plot(res.pca, choix = "ind", habillage = 8, col.hab = 8, label =  "quali", invisible = "ind")
{% endhighlight %}

![plot of chunk unnamed-chunk-5](http://data-laborer.eu/blog_dev_mm/assets/images/figures/source/2016-02-13-Unicycle_comparison/unnamed-chunk-5-1.png)

As we could see, we could find a brand for every need.

For a model with a good autonomy but expensive, we could look at the Gotway and Lhotz.
For a less expensive model, we could look for a Macwheel or a Fastwheel. But the autonomy will be according to the price.

Now, the question we could ask is if there is, considering these brands, a brand which have lower prices than the others. For that, we do a regression of the price considering the others variables.

The idea, here, is that if there is a brand which have lower prices than the others considering the others variables of the product.


{% highlight r %}
summary(res.lm <- lm(price ~ autonomy + speed + weight + wheel + climb, data = comparison.norm))
{% endhighlight %}



{% highlight text %}
## 
## Call:
## lm(formula = price ~ autonomy + speed + weight + wheel + climb, 
##     data = comparison.norm)
## 
## Residuals:
##      Min       1Q   Median       3Q      Max 
## -1.10276 -0.36037 -0.03053  0.13781  3.08615 
## 
## Coefficients:
##             Estimate Std. Error t value Pr(>|t|)   
## (Intercept) -0.03724    0.10484  -0.355  0.72435   
## autonomy     0.38463    0.12280   3.132  0.00328 **
## speed        0.30000    0.12636   2.374  0.02260 * 
## weight       0.12361    0.14583   0.848  0.40183   
## wheel        0.14183    0.12303   1.153  0.25603   
## climb       -0.07555    0.12281  -0.615  0.54203   
## ---
## Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
## 
## Residual standard error: 0.6987 on 39 degrees of freedom
##   (13 observations deleted due to missingness)
## Multiple R-squared:  0.5672,	Adjusted R-squared:  0.5118 
## F-statistic: 10.22 on 5 and 39 DF,  p-value: 2.589e-06
{% endhighlight %}

The R^2^ obtained is of 0.5, which indicate a low fit of the price by the others variables.
Autonomy and speed, both  related to the battery are significative variables.


{% highlight r %}
plot(res.lm, which = c(1:4))
{% endhighlight %}

![plot of chunk unnamed-chunk-7](http://data-laborer.eu/blog_dev_mm/assets/images/figures/source/2016-02-13-Unicycle_comparison/unnamed-chunk-7-1.png)![plot of chunk unnamed-chunk-7](http://data-laborer.eu/blog_dev_mm/assets/images/figures/source/2016-02-13-Unicycle_comparison/unnamed-chunk-7-2.png)![plot of chunk unnamed-chunk-7](http://data-laborer.eu/blog_dev_mm/assets/images/figures/source/2016-02-13-Unicycle_comparison/unnamed-chunk-7-3.png)![plot of chunk unnamed-chunk-7](http://data-laborer.eu/blog_dev_mm/assets/images/figures/source/2016-02-13-Unicycle_comparison/unnamed-chunk-7-4.png)

Two outliers appear, here, rows 45 and 27.


{% highlight r %}
comparison.df[c(45, 27), - c(11, 7, 5), with = F]
{% endhighlight %}



{% highlight text %}
##        brand model autonomy speed weight  wh charging.time price
## 1: SOLOWHEEL  1500       12    18     12 132            NA  1890
## 2: FIREWHEEL  F779      100    20     15 776            NA  1890
##                             equipements.intégrés
## 1:                                              
## 2: Eclairage avant et arrière. Affichage digital
##                              les.plus                    les.moins wheel
## 1:               Référence du marché. mini autonomie. Perf -, Prix    16
## 2: Très bonne autonomie. Jolie design                  Poids. Prix    16
##    climb
## 1:    15
## 2:    20
{% endhighlight %}

They are both overpriced looking at their capacities.
The Solowheel 1500 especially is really expensive. The Firewheel have a huge price due to a huge battery, giving an impressive autonomy.


{% highlight r %}
summary(res.lm2 <- lm(price ~ autonomy + speed + weight + wheel + climb, data = comparison.norm[-c(45, 27), ]))
{% endhighlight %}



{% highlight text %}
## 
## Call:
## lm(formula = price ~ autonomy + speed + weight + wheel + climb, 
##     data = comparison.norm[-c(45, 27), ])
## 
## Residuals:
##      Min       1Q   Median       3Q      Max 
## -1.08254 -0.17646  0.00512  0.20551  1.04283 
## 
## Coefficients:
##             Estimate Std. Error t value Pr(>|t|)    
## (Intercept) -0.14851    0.07055  -2.105  0.04214 *  
## autonomy     0.35793    0.10164   3.521  0.00116 ** 
## speed        0.35158    0.08551   4.112  0.00021 ***
## weight       0.15208    0.09537   1.595  0.11932    
## wheel        0.03634    0.08138   0.447  0.65781    
## climb       -0.02719    0.08031  -0.339  0.73683    
## ---
## Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
## 
## Residual standard error: 0.4549 on 37 degrees of freedom
##   (13 observations deleted due to missingness)
## Multiple R-squared:  0.7361,	Adjusted R-squared:  0.7005 
## F-statistic: 20.64 on 5 and 37 DF,  p-value: 8.475e-10
{% endhighlight %}

Without these both outliers, the model is more performant, the R^2^ reaching 0.7.

In the end, the best balanced models found are the Airwheel Q5 340 and the F-Wheel FL D5. These both are quite cheap and really performing. And the F-wheel have a really nice design. That model is definitely the one I recommand.


{% highlight r %}
comparison.df[-c(45, 27), - c(11, 7, 5), with = F][c(12, 23), ]
{% endhighlight %}



{% highlight text %}
##       brand  model autonomy speed weight  wh charging.time price
## 1: AIRWHEEL Q5 340       65    16   13.5 340            NA   715
## 2:  F-WHEEL  FL D5       45    25   15.2 388            NA   751
##                                           equipements.intégrés
## 1:                                                            
## 2: Trolley Eclairage avant. Affichage digital. Port USB. Appli
##                                                   les.plus
## 1:                      Aucun risque de perdre l'équilibre
## 2: Autonomie. Vitesse. Joli design. % de pente élevé. Prix
##                  les.moins wheel climb
## 1:            Peu maniable    14    15
## 2: Poids 12kg, moteur 400W    16    32
{% endhighlight %}



