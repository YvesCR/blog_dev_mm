---
layout: single
title: "How Far am I From the Next Tube Station?"
categories: [Data visualisation]
tags: [alphahull, data visualisation, geometry, R, Statistic]
date: 2015-07-16
excerpt: How to find the furthest point from a London tube station with Voronoi
teaser: assets/images/London3.png
---

A question was uplifted at the last R coding dojo. What is the location in central London which is the furthest from the subway?

The first bit of code of this question was made at the LondonR coding dojo, here:

[https://github.com/London-R-Dojo/Dojo-repo/tree/master/July-2015-Dojo](https://github.com/London-R-Dojo/Dojo-repo/tree/master/July-2015-Dojo)

Two approach was used to reply to this question:

-Mapping the point depending on the distance from the subway

-Using Voronoi diagram to analytically determine the furthest point.

 
The first approach produced a really nice plot of London when the second approach failed to pass the question of the border of an area,

In this blog post, I try to override this issue.

<h1> Method </h1>

In the alphahull package, the `ashape` function allows to create a close constraint, based on voronoi. It calculates both the constraint and the voronoi vertices.

The function `pnt.in.poly` of the SDMTools allow to flag the voronoi vertices which are inside the constraint.

Combining both allows me to create a constraint Voronoi diagram in which I could look for the point the furthest from any subway station.

![london gif ]({{ site.baseurl }}/image/London.gif) 

<h1> The code </h1>

<h3> Libraries, data, raw map </h3>

Coordinates of stations could be found on the TFL website.
The function `get_map()` plot a map in a really efficient way and quite fast.


<pre><code class="prettyprint ">library(ggmap)
library(alphahull)
library(SDMTools) 
library(devtools)
library(animation)
library(ImageMagick)

# load the libraries:
l &lt;- lapply(c(&quot;data.table&quot;, &quot;alphahull&quot;, &quot;ggmap&quot;, &quot;SDMTools&quot;, &quot;sp&quot;), require, character.only = T)

  # First, get the data:
coord.station &lt;- fread(&quot;tfl.stations.csv&quot;)

  # Get the map of London:
london12 &lt;- get_map(location = &quot;London&quot;, zoom = 12)
zones.london.plot12 &lt;- ggmap(london12, maprange = F) 

  # only zones 1 &amp; inside the plot:
coord.station[, zone2 := ifelse(type == &quot;dlr&quot;, &quot;dlr&quot;, zone) ]
coord.station.min &lt;- coord.station[zone == 1, list(lon, lat, zone2)]

  # plot stations
zones.london &lt;- zones.london.plot12 +
          geom_point(data = coord.station.min, aes(x = lon, y = lat, colour = as.factor(zone2)), size = 1.5) +
          scale_colour_discrete(name = &quot;Zone&quot;)</code></pre>





<h3> Voronoi & constraint calculation </h3>

The alpha parameter control the alpha-shape. The smallest the value, the more complicated the constraint.


<pre><code class="prettyprint ">  # voronoi and constraint:
alphashape &lt;- ashape(coord.station.min$lon, coord.station.min$lat, alpha = 0.021)

  # voronoi summits:
voronoi.full &lt;- data.table(alphashape$delvor.obj$mesh)
polygon.ext &lt;- data.frame(alphashape$edges)

# plot the voronoi diagram without constraint:
plot.no.map.voronoi &lt;- zones.london +
  geom_segment(data = voronoi.full, aes(x = mx1, y = my1, xend = mx2, yend = my2), colour = &quot;red&quot;, size=0.25) +
  geom_segment(data = polygon.ext, aes(x = x1, y = y1, xend = x2, yend = y2), colour = &quot;blue&quot;, size=0.25)
plot.no.map.voronoi</code></pre>

![plot of chunk unnamed-chunk-3](http://data-laborer.euassets/images/figures/source/2015-07-16-Voronoi_station/unnamed-chunk-3-1.png)

Now, we have the constraint and the voronoi diagram on all the subways station of the zone 1.

<h3> Keep voronoi summits inside the constraint </h3>

As I want to keep only the voronoi summit inside the constraint, I use the function `pnt.in.poly` to flag summit outside the constraint.

The function takes only the ordered summit of the constraint as the polygon. The first loop reorder the summits.


<pre><code class="prettyprint "> ## problem: voronoi summit are outside the polygon.
  #we are looking for the voronoi summits which are inside the polygon.
  # our issue here is that the function pnt.in.polygon need an ordered table of the summit.
  # And the function alphahull release an unordered set of points.

  # voronoi summits:
voronoi.summit &lt;- unique(rbind(voronoi.full[, list(mx1, my1)], voronoi.full[, list(mx2, my2)], use.names = F))

  # do a channel with the variables ind1 et ind2:
nb.edges &lt;- dim(polygon.ext)[1]
  
  # initialisation of the table:
order &lt;- data.frame(order = rep(2, nb.edges), lon = rep(0, nb.edges), lat = rep(0, nb.edges), stringsAsFactors = F)

  # new table to modify:
polygon.ext2 &lt;- polygon.ext

order[1, ] &lt;- polygon.ext2[1, c(&quot;ind1&quot;, &quot;x1&quot;, &quot;y1&quot;)]
polygon.ext2 &lt;- polygon.ext2[-1, ]
  
  # loop through the summits to select each time the next one:
for (i in 2: nb.edges) { # i &lt;- 2
  if(order[i-1, 1] %in% polygon.ext2$ind1) { order[i, ] &lt;- polygon.ext2[which(polygon.ext2$ind1 == order[i-1, 1]), c(&quot;ind2&quot;, &quot;x2&quot;, &quot;y2&quot;)]
  polygon.ext2 &lt;- polygon.ext2[-which(polygon.ext2$ind1 == order[i-1, 1]), ]
  } else { order[i, ] &lt;- polygon.ext2[which(polygon.ext2$ind2 == order[i-1, 1]), c(&quot;ind1&quot;, &quot;x1&quot;, &quot;y1&quot;)]
  polygon.ext2 &lt;- polygon.ext2[-which(polygon.ext2$ind2 == order[i-1, 1]), ]}
}

  # list of voronoi summits which are in the polygon:
voronoi.constrain &lt;- data.table(pnt.in.poly(voronoi.summit, order[, c(&quot;lon&quot;, &quot;lat&quot;)]))

  # voronoi inside the polygon:
voronoi.part &lt;- merge(voronoi.full, voronoi.constrain, by = c(&quot;mx1&quot;, &quot;my1&quot;), all.x = T)
setnames(voronoi.constrain, c(&quot;mx1&quot;, &quot;my1&quot;), c(&quot;mx2&quot;, &quot;my2&quot;))
voronoi.part &lt;- merge(voronoi.part, voronoi.constrain, by = c(&quot;mx2&quot;, &quot;my2&quot;), all.x = T)

   # plot the voronoi diagram with constraint &amp; only inside edge of voronoi diagram:
zones.london.vor &lt;- zones.london +
  geom_segment(data = polygon.ext, aes(x = x1, y = y1, xend = x2, yend = y2), colour = &quot;blue&quot;, size = 0.25) +
  geom_segment(data = voronoi.part[pip.x == 1 &amp; pip.y == 1, ], aes(x = mx2, y = my2, xend = mx1, yend = my1), colour = &quot;red&quot;, size = 0.25) 
zones.london.vor</code></pre>

![plot of chunk unnamed-chunk-4](http://data-laborer.euassets/images/figures/source/2015-07-16-Voronoi_station/unnamed-chunk-4-1.png)

<h3>  Finding the furthest point from the subway </h3>

I am looking for the voronoi summit the furthest from any subway station.
I use the `spDistsN1` function to calculate the distance on a sphere.   


<pre><code class="prettyprint ">### Finding the furthest point:
  # voronoi summit in the polygon
voronoi.constrain.lim &lt;- voronoi.constrain[pip == 1, list(mx2, my2)]

  # matrix of distance between all the station and the voronoi summits: 
matrix.dist &lt;- apply(voronoi.constrain.lim, 1, function(eachPoint) spDistsN1(as.matrix(coord.station.min[, list(lon, lat)]), eachPoint, longlat = T))

  # for each colum, the lowest distance:
min.dist &lt;- apply(matrix.dist, 2, min)

  # coordonates of the furthest point:
min.coordinates &lt;- voronoi.constrain.lim[which(matrix.dist == max(min.dist), arr.ind = T)[2]]

  # Thirdly, plotting the point:
zones.london.point &lt;- zones.london.vor +
   geom_point(data = min.coordinates, aes(x = mx2, y = my2), color = &quot;green&quot;, size = 2) +
  annotate(&quot;text&quot;, x = min.coordinates$mx2, y = min.coordinates$my2 - 0.003, label = &quot;The albert memorial&quot;)
zones.london.point</code></pre>

![plot of chunk unnamed-chunk-5](http://data-laborer.euassets/images/figures/source/2015-07-16-Voronoi_station/unnamed-chunk-5-1.png)

In the end, it appears that the furthest point from the subway in London is near the Albert memorial. If you already find yourself hanging there and thinking that the next subway station was quite far, be rassured, it's definitely normal. :)


