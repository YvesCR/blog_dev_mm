---
layout: single
title: "Visualisation of my Google Map History"
categories: [data visualisation]
tags: [R, ggmap]
date: 2017-01-15
excerpt: Exploration of the localisation data created when using google map
teaser: assets/images/The_Great_Wave_off_Kanagawa.jpg
---

## Abstract

Recently, I needed a few localisation points to create a test for a visualization.

To create a real effect, I decided to see if I could use the data I create everyday when I use Google map.
Why I am not shy about these data? Simply because they are outdated due to the fact that I have recently moved. (It would be a shame to be robbed by a bugler expert in data because of a blog post :) ).

I ended to find a lot of interesting things:

* Over two years, Google had stored 12K points with an associated time stamps.
* These data tells a lot on me:
    + Where I work
    + Where I live
    + My typical day
    + How I move: by car, by bike or by foot.

All in all, this data set reflects pretty accurately my routine week and is perfect for advertisers and more. Well done, Google.

## Presentation of the Dataset

I went to the [takeout manager](https://takeout.google.com/settings/takeout) of my Google account to see if I could use the data from my Google map account.

The process is fairly easy and fast. In my case, I was able to get 12K coordinates over 2 years of use of Google products.

In addition of the coordinates, Google also provide a time stamp and a bunch of variables poorly completed: velocity, altitude, accuracy and activity with a reliability score.

### Heat Map of my Historical Positions

The data set is included in my github account. I have limited the data set to London and 2 years.


{% highlight r %}
# load libraries:
pacman::p_load(tidyverse, ggmap, scales)

## read the json file:
json_file <- "C:/YCR Perso/mapassistant/data test/Takeout/Historique des positions/Historiquedespositions.json"
json_import_data <- jsonlite::fromJSON(txt = json_file)

# clean the dataset:
coord.df <- json_import_data$locations

# we tidy the dataframe:
coord.df.lim <- coord.df %>%
      mutate(lat = latitudeE7 / 10000000, lon = longitudeE7 / 10000000,
          date_time = as.POSIXct(as.numeric(timestampMs)/1000,
            origin = "1970-01-01")) %>% 
      mutate(date = as.Date(date_time), hour = format(date_time, "%H"),
            day_week = format(date_time, "%a")) %>% 
      mutate(day_week = factor(day_week,
            levels = c("Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun")))%>%
      filter(lon < 0.2 & lon > -0.4 & lat < 51.6 & lat > 51.48)

# limit to London:
coord.df.lim.2 <- coord.df.lim  %>% select(lon, lat, date, hour, day_week)
{% endhighlight %}





The first thing to do with this data set is to create an heat map to visually assess the content.


{% highlight r %}
# min amd max longitude in a specific variable:
mean_lon <- mean(coord.df.lim.2$lon)
mean_lat <- mean(coord.df.lim.2$lat)
min_lon <- min(coord.df.lim.2$lon)
min_lat <- min(coord.df.lim.2$lat)
max_lon <- max(coord.df.lim.2$lon)
max_lat <- max(coord.df.lim.2$lat)

# dl the map layer:
my_map <- ggmap::get_map(location = c(min_lon - 0.01, min_lat - 0.01,
                  max_lon + 0.01, max_lat + 0.01),
                  maptype = "terrain", zoom = 11)

# define the theme:
theme_map_london <- theme(axis.title = element_blank(),
        #axis.text = element_blank(),
        #axis.ticks = element_blank(),
        panel.background = element_blank(),
        plot.background = element_blank())

# number of points in grid
grid_point <- 100

# plot the graph:
ggmap::ggmap(my_map) +
     geom_density2d(data = coord.df.lim.2, 
       aes(x = lon, y = lat), size = 0.3) +
    stat_density2d(data = coord.df.lim.2, 
      aes(x = lon, y = lat, fill = log(..level..)),
      n = grid_point,
      geom = "polygon",
      alpha = 0.5) +
    scale_fill_gradient("Density\nlog scale", low = "green", high = "red") + 
    theme_map_london
{% endhighlight %}

![plot of chunk unnamed-chunk-4](http://yvescr.github.io/assets/images/figures/source/2017-01-15-google_map_our_article/unnamed-chunk-4-1.png)

Here, one difficulty is to interpret the density scale: What exactly are we representing?

### Read the Scale

The density is calculated at an exact point through a two-dimensional kernel density. It is estimated on a grid of, in that case, `100` * `100` points.

A small calculus allows us to define the area of a square:


{% highlight r %}
grid_lat <- (max_lat - min_lat)/ grid_point
grid_lon <- (max_lon - min_lon)/ grid_point 
p <- rbind(c(min_lat, min_lon), c(min_lat + grid_lat, min_lon),
           c(min_lat + grid_lat, min_lon + grid_lon),
           c(min_lat, min_lon + grid_lon), c(min_lat, min_lon))
res_square_meter <- geosphere::areaPolygon(p)
# square meters in one square of the grid
{% endhighlight %}

A density of 6 could be read as exp(6) or 403 points per `53,290` square meter or `76` points per hectare.

## Heat Map per Time Period

Is it possible to define specific place at specific time period?

Let's have a look at the full time period:


{% highlight r %}
# number of points per day:
date_hour_freq <- coord.df.lim %>% 
    group_by(date, day_week, hour) %>% 
    summarise(count = n())

date_freq <- date_hour_freq %>% 
    group_by(date) %>% 
    summarise(count_date = sum(count))

# We add the top line for the date
max_hour_freq <- date_hour_freq %>% 
    group_by(date) %>% 
    summarise(max_hour_freq = max(count))

# an hour is arbitrarily choosen among the top hours
date_freq_max_hour <- merge(merge(date_hour_freq, date_freq, by = "date"),
    max_hour_freq, by = "date") %>% 
    filter(count == max_hour_freq) %>% 
    group_by(date) %>% 
    slice(1)

# Let's represent it on a graph:
ggplot(data = date_freq_max_hour, aes(x = date, y = count)) +
  geom_line() +
  geom_point(aes(color = hour)) +
  scale_x_date(date_breaks = "1 month") +
  theme(axis.text.x = element_text(angle = 45))
{% endhighlight %}

![plot of chunk unnamed-chunk-6](http://yvescr.github.io/assets/images/figures/source/2017-01-15-google_map_our_article/unnamed-chunk-6-1.png)

In a strange way, no data appear between November 2015 and March 2016.


{% highlight r %}
hour_freq <- date_hour_freq %>% 
  group_by(hour) %>% 
  summarise(freq = sum(count))
            
ggplot(hour_freq, aes(x = hour, y = freq)) +
  geom_col()
{% endhighlight %}

![plot of chunk unnamed-chunk-7](http://yvescr.github.io/assets/images/figures/source/2017-01-15-google_map_our_article/unnamed-chunk-7-1.png)

The time stamp is mainly associated with hours between 6 and 10 in the afternoon.
It seems logic to me, as it is the time of the day when I am the most active.
More astonishing, there is points registered during the night. It may be nice to create a heat map per hour to see if we can predict where I will be at certain hours:


{% highlight r %}
# Heatmap per hour
# plot the graph:
map_by_hour <- ggmap::ggmap(my_map) +
    #  geom_density2d(data = coord.df.lim.2, 
    #    aes(x = lon, y = lat), size = 0.3) +
     stat_density2d(data = coord.df.lim.2, 
      aes(x = lon, y = lat, fill = log(..level..)),
      n = grid_point,
      geom = "polygon",
      alpha = 0.5) +
    scale_fill_gradient("Density\nlog scale", low = "green", high = "red") + 
    theme_map_london +
  facet_wrap(~hour)

ggsave(plot = map_by_hour, filename = "map_by_hour.png", width = 20, height = 20, dpi = 300)
{% endhighlight %}

As we can see on [that graph](https://data-laborer.eu/assets/images/special/map_by_hour.png), I am pretty quiet during the night, wake up at Acton between 8 and 9 and run around London the rest of the day, coming back home between 7 and 10 p.m..

Is there a discretisation that can be done per day?


{% highlight r %}
week_freq <- date_hour_freq %>% 
  group_by(day_week) %>% 
  summarise(freq = sum(count))

ggplot(week_freq, aes(x = day_week, y = freq)) +
  geom_col()
{% endhighlight %}

![plot of chunk unnamed-chunk-9](http://yvescr.github.io/assets/images/figures/source/2017-01-15-google_map_our_article/unnamed-chunk-9-1.png)

I have more data stored for Saturday and Sunday, which seems normal, as it is the days where I use Google map the most.


{% highlight r %}
# Heatmap per weekday
# plot the graph:
ggmap::ggmap(my_map) +
    # geom_density2d(data = coord.df.lim.2, 
      # aes(x = lon, y = lat), size = 0.3) +
    stat_density2d(data = coord.df.lim.2, 
      aes(x = lon, y = lat, fill = log(..level..)),
      n = grid_point,
      geom = "polygon",
      alpha = 0.5) +
    scale_fill_gradient("Density\nlog scale", low = "green", high = "red") + 
    theme_map_london +
  facet_wrap(~day_week)
{% endhighlight %}

![plot of chunk unnamed-chunk-10](http://yvescr.github.io/assets/images/figures/source/2017-01-15-google_map_our_article/unnamed-chunk-10-1.png)

It reflects well a typical day: I am generally out in Monday and Wednesday, so I stay still in Tuesday. Saturday and especially Sunday are days where I move a lot around London.

## Activity

In the data set, we also can find a variable activity which is a list of activities, not really well define.


{% highlight r %}
# Number of rows with an activity:
comp_activity <- sum(1-sapply(coord.df.lim$activitys, is.null))
# Percentage of rows with an activity:
pct_activity <- sprintf("%.1f%%", comp_activity / nrow(coord.df.lim) * 100)
{% endhighlight %}

Over `4,072` rows are completed with a list of activity. It represents `38.8%` of the rows.


{% highlight r %}
# reshape the dataset:
index_non_null <- which(!sapply(coord.df.lim$activitys, is.null))
activities_df <- plyr::ldply(index_non_null,
  function(x) data.frame(coord.df.lim[x, c("timestampMs", "lat", "lon")],
    plyr::ldply(1:length(coord.df.lim$activitys[[x]]$timestampMs),
      function(y) data.frame(timestamp_act = coord.df.lim$activitys[[x]]$timestampMs[y],
               type = coord.df.lim$activitys[[x]]$activities[[y]]$type,
               confidence = coord.df.lim$activitys[[x]]$activities[[y]]$confidence,
               stringsAsFactors = F)
      )
    , row.names = NULL)
  )

# clean the dates 
activities_df <- activities_df %>%
        mutate(date_time = as.POSIXct(as.numeric(timestampMs)/1000,
            origin = "1970-01-01"),
            date_time_activity = as.POSIXct(as.numeric(timestamp_act)/1000,
            origin = "1970-01-01") ) %>% 
        mutate(diff_minute = (date_time - date_time_activity)/60)
activities_df_limit <- activities_df %>% filter(confidence > 90)
{% endhighlight %}

Activities have a time stamps of their own.

`79,392` activities are recorded, an average of 7 per location. Nevertheless, we can find a confidence variable. If we restrict to only the highly confident time stamps, over 90, we limit to `16,657` rows.


{% highlight r %}
ggplot(data = activities_df) +
    stat_density(aes(x = diff_minute, y = ..count..)) +
  scale_x_continuous(name = "Minutes", labels = comma) +
  ggtitle("Minutes Between Original Timestamp and Activity Timestamp")
{% endhighlight %}

![plot of chunk unnamed-chunk-13](http://yvescr.github.io/assets/images/figures/source/2017-01-15-google_map_our_article/unnamed-chunk-13-1.png)

Most of the time stamps of the activities are a couple of minutes after the time stamp of the coordinates.
Nevertheless, we can also observe a decreasing sinusoidal trend with peaks at 24h, 48h and 64h.


{% highlight r %}
ggplot(data = activities_df) +
  stat_count(aes(x = type)) +
  scale_y_continuous(labels = comma) +
  ggtitle("Type of Activity, No Limit on Confidence")
{% endhighlight %}

![plot of chunk unnamed-chunk-14](http://yvescr.github.io/assets/images/figures/source/2017-01-15-google_map_our_article/unnamed-chunk-14-1.png)

I don't have a car nor a bike so I was astonished to see so much tags "inVehicle" and "onBicycle". The reason of so much of these tags is that they are associated to a low confidence. When limiting to a confidence of 90 or above, the activities make finally sense. 


{% highlight r %}
activities_df_limit <- activities_df %>% filter(confidence > 90)
ggplot(data = activities_df_limit) +
  stat_count(aes(x = type)) +
  scale_y_continuous(labels = comma) +
  ggtitle("Type of Activity, Limit on Confidence")
{% endhighlight %}

![plot of chunk unnamed-chunk-15](http://yvescr.github.io/assets/images/figures/source/2017-01-15-google_map_our_article/unnamed-chunk-15-1.png)

Most of my activities are standing and tilting. I tilt when I use my unicycle so it makes sense to have so much and I am still mainly at work and at home.

Is it possible to predict that way if a person has a car or a bike? Yes, definitely.

I have created a graph by type that can [be found here](https://data-laborer.eu/assets/images/special/map_by_type.png).
In that graph, it is possible to check where I am standing still and where I am just passing.


